#!/usr/bin/env python3
"""
빌드 에러 자동 수정 스크립트 (OpenAI API).
에러 로그 + android/ 설정 파일을 GPT-4o에 보내고,
수정된 파일을 직접 덮어씁니다.
"""
import os
import re
import sys

try:
    from openai import OpenAI
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "openai", "--quiet"])
    from openai import OpenAI

ERROR_LOG_PATH = "error_tail.txt"
ANDROID_FILES = [
    "android/settings.gradle.kts",
    "android/gradle/wrapper/gradle-wrapper.properties",
    "android/gradle.properties",
    "android/build.gradle.kts",
    "android/app/build.gradle.kts",
]


def read_file(path: str) -> str:
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        return ""


def write_file(path: str, content: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"[auto-fix] Updated: {path}")


def main() -> int:
    error_log = read_file(ERROR_LOG_PATH) or "에러 로그를 찾을 수 없습니다."
    file_context = "\n\n".join(
        f"=== {p} ===\n{read_file(p)}" for p in ANDROID_FILES if os.path.exists(p)
    )

    prompt = f"""Android CI 빌드 에러를 분석하고 android/ 디렉토리의 Gradle 설정 파일들을 수정해서 에러를 해결해주세요.

규칙:
- Gradle / AGP / Kotlin 버전 호환성 문제만 수정합니다.
- 앱 코드(lib/, pubspec.yaml)는 절대 수정하지 않습니다.
- 최소한의 변경만 합니다.
- 존재하지 않는 버전 번호는 사용하지 않습니다.

에러 로그:
{error_log}

현재 파일:
{file_context}

수정이 필요한 파일만 아래 XML 형식으로 반환하세요. 설명이나 다른 텍스트는 포함하지 마세요.
<FILE path="android/settings.gradle.kts">
(전체 파일 내용)
</FILE>
"""

    client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY", ""))
    print("[auto-fix] Calling OpenAI API...")

    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role": "user", "content": prompt}],
        max_tokens=4096,
        temperature=0,
    )

    text = response.choices[0].message.content or ""
    print("[auto-fix] OpenAI response received.")

    changes = re.findall(
        r'<FILE path="([^"]+)">\n?(.*?)\n?</FILE>', text, re.DOTALL
    )

    if not changes:
        print("[auto-fix] No file changes suggested.")
        print("Response preview:", text[:600])
        return 1

    applied = 0
    for path, content in changes:
        path = path.strip()
        if not path.startswith("android/"):
            print(f"[auto-fix] Skipping non-android path: {path}")
            continue
        write_file(path, content.strip() + "\n")
        applied += 1

    print(f"[auto-fix] Applied {applied} file change(s).")
    return 0 if applied > 0 else 1


if __name__ == "__main__":
    sys.exit(main())
