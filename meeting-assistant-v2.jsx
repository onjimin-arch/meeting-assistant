import { useState, useEffect, useRef } from "react";

const C = {
  bg: '#212121', surface: '#2f2f2f', hover: '#3a3a3a',
  border: '#3e3e3e', text: '#ececec', muted: '#8e8ea0',
  accent: '#10a37f', accentDark: '#0d8f6e', danger: '#ef4444',
};

const MEETINGS = [
  { id:1, title:'2025 Q2 전략 회의', date:'오늘 14:30', dur:'45분' },
  { id:2, title:'신규 서비스 기획 킥오프', date:'어제 10:00', dur:'1시간 20분' },
  { id:3, title:'주간 팀 스탠드업', date:'5월 10일', dur:'30분' },
  { id:4, title:'AX 로드맵 리뷰', date:'5월 8일', dur:'55분' },
];

const TRANSCRIPT = `이지민: 네, 다들 들어오셨으면 시작할게요. 오늘 Q2 전략 방향 확정하는 자리인데, DEBTFLOW 배포 일정부터 짚고 가겠습니다.

김철수: 저희 쪽에서는 6월 첫째 주 배포가 가능한 상태입니다. 내부 테스트는 이번 주 마무리되고요.

이지민: 좋아요. HRFlow는요?

박영희: 설계는 완료됐고요, HR팀이랑 확인해야 할 사항이 몇 가지 있어서요. 이번 주 안에 미팅 잡으려고요.

김철수: 제가 HR팀 일정 조율할게요. 5월 20일 이전으로 잡겠습니다.

이지민: 멀티에이전트 프레임워크 파일럿은요?

최동욱: Q2 내로 기존 에이전트 프로젝트에 붙여볼 계획입니다. 실제 프로젝트에 적용하면서 검증하는 방향으로요.

이지민: 인력 얘기도 짧게 하고 싶은데요. AX팀 2명 증원 검토 중인 거 다들 아시죠?

박영희: 예산 쪽은 Q2 확정되면 같이 검토하면 될 것 같아요.

이지민: 그럼 다음 회의는 5월 20일 화요일 오전 10시로 잡겠습니다. 수고하셨습니다.`;

const MINUTES = `## 회의록

**일시**: 2025년 5월 13일 14:30
**참석자**: 이지민, 김철수, 박영희, 최동욱
**목적**: 2025 Q2 전략 방향 확정

---

### 1. 주요 안건

**AX 로드맵 업데이트**
- DEBTFLOW v2 배포 일정: 6월 첫째 주 확정
- HRFlow 설계 완료, HR팀 피드백 수렴 단계 진입
- 멀티에이전트 프레임워크 Q2 내 파일럿 적용 예정

**인력 계획**
- AX팀 헤드카운트 2명 증원 검토 중
- 외부 컨설팅 여부: 7월 이후 재논의

---

### 2. 결정 사항

- ☐ DEBTFLOW 배포: 이지민 담당, 6/2 마감
- ☐ HR팀 미팅 일정: 김철수 조율, 5/20 이전
- ☐ Q2 예산 재확인: 박영희 담당

---

### 3. 다음 회의

5월 20일 (화) 오전 10시`;

const QUICK = {
  '액션아이템 추출': '이 회의에서 추출된 액션아이템은 총 3개입니다:\n\n1. **DEBTFLOW v2 배포** — 이지민 | 마감 6/2\n2. **HR팀 미팅 일정 조율** — 김철수 | 5/20 이전\n3. **Q2 예산 재확인** — 박영희 | 미정',
  '영문 요약': '**Meeting Summary (EN)**\n\nDate: May 13, 2025 | Duration: 45 min\n\n**Key Decisions**: DEBTFLOW v2 deployment set for early June. HRFlow entering feedback phase. Multi-agent framework pilot planned for Q2.\n\n**Action Items**: 3 items assigned across team leads.',
  '임원 보고용 재작성': '**[경영진 요약]** 2025 Q2 전략 회의\n\nAX 핵심 시스템 2종(DEBTFLOW·HRFlow)이 예정대로 진행 중이며 Q2 내 배포 및 피드백 수렴을 완료할 계획입니다. 인력 증원(2명) 검토는 7월 예산 확정 후 결정됩니다.',
};

// ─── Shared ───────────────────────────────────────────────────────────────────

function Back({ go }) {
  return (
    <button onClick={go} style={{ background:'none', border:'none', cursor:'pointer', color:C.muted, padding:4, display:'flex' }}>
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="15,18 9,12 15,6"/></svg>
    </button>
  );
}

// ─── Home ─────────────────────────────────────────────────────────────────────

function Home({ onRec, onMeeting, onSettings }) {
  return (
    <div style={{ display:'flex', flexDirection:'column', height:'100%' }}>
      <div style={{ padding:'20px 20px 14px', display:'flex', justifyContent:'space-between', alignItems:'center' }}>
        <span style={{ fontSize:18, fontWeight:600, color:C.text }}>Meeting Assistant</span>
        <button onClick={onSettings} style={{ background:'none', border:'none', cursor:'pointer', color:C.muted, padding:6, display:'flex' }}>
          <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <circle cx="12" cy="12" r="3"/>
            <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/>
          </svg>
        </button>
      </div>
      <div style={{ flex:1, overflowY:'auto', padding:'4px 12px' }}>
        <p style={{ fontSize:10.5, color:C.muted, textTransform:'uppercase', letterSpacing:'0.1em', padding:'4px 8px 10px' }}>최근 회의</p>
        {MEETINGS.map(m => (
          <div key={m.id} onClick={() => onMeeting(m)}
            style={{ display:'flex', alignItems:'center', gap:12, padding:'11px 12px', borderRadius:12, marginBottom:2, cursor:'pointer', transition:'background 0.15s' }}
            onMouseEnter={e => e.currentTarget.style.background = C.hover}
            onMouseLeave={e => e.currentTarget.style.background = 'transparent'}>
            <div style={{ width:36, height:36, borderRadius:10, background:C.surface, display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0 }}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={C.accent} strokeWidth="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14,2 14,8 20,8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
            </div>
            <div style={{ flex:1, minWidth:0 }}>
              <p style={{ margin:0, fontSize:14, color:C.text, fontWeight:500, whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>{m.title}</p>
              <p style={{ margin:0, fontSize:12, color:C.muted, marginTop:2 }}>{m.date} · {m.dur}</p>
            </div>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={C.muted} strokeWidth="2"><polyline points="9,18 15,12 9,6"/></svg>
          </div>
        ))}
      </div>
      <div style={{ padding:'12px 16px 28px' }}>
        <button onClick={onRec}
          style={{ width:'100%', padding:'14px 0', borderRadius:14, background:C.accent, border:'none', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', gap:10, color:'#fff', fontSize:15, fontWeight:600, fontFamily:'inherit' }}
          onMouseEnter={e => e.currentTarget.style.background = C.accentDark}
          onMouseLeave={e => e.currentTarget.style.background = C.accent}>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="white"><path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z"/><path d="M19 10v2a7 7 0 0 1-14 0v-2" stroke="white" fill="none" strokeWidth="2"/><line x1="12" y1="19" x2="12" y2="23" stroke="white" strokeWidth="2"/><line x1="8" y1="23" x2="16" y2="23" stroke="white" strokeWidth="2"/></svg>
          새 회의 녹음
        </button>
      </div>
    </div>
  );
}

// ─── Recording ────────────────────────────────────────────────────────────────

function Recording({ time, wave, onStop }) {
  const f = s => `${Math.floor(s/60).toString().padStart(2,'0')}:${(s%60).toString().padStart(2,'0')}`;
  return (
    <div style={{ display:'flex', flexDirection:'column', height:'100%', alignItems:'center', justifyContent:'space-between', padding:'56px 32px 52px' }}>
      {/* 상단: REC 뱃지만 */}
      <div style={{ display:'inline-flex', alignItems:'center', gap:8, background:C.surface, borderRadius:20, padding:'6px 14px' }}>
        <div style={{ width:7, height:7, borderRadius:'50%', background:C.danger, animation:'blink 1s ease infinite' }}/>
        <span style={{ fontSize:12, color:C.muted, fontWeight:500 }}>REC</span>
      </div>

      {/* 중단: 웨이브폼 */}
      <div style={{ display:'flex', alignItems:'center', gap:3, height:64, width:'100%' }}>
        {wave.map((h, i) => (
          <div key={i} style={{ flex:1, borderRadius:2, background: i%3===0 ? C.accent : C.muted, opacity: i%3===0 ? 0.9 : 0.3, height:`${h}%`, transition:'height 0.1s ease' }}/>
        ))}
      </div>

      {/* 하단: 타이머 + 종료 버튼 + 텍스트 */}
      <div style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:14 }}>
        <p style={{ fontSize:38, fontWeight:200, color:C.text, letterSpacing:'0.06em', margin:0 }}>{f(time)}</p>
        <button onClick={onStop} style={{ width:70, height:70, borderRadius:'50%', background:C.danger, border:'none', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', boxShadow:`0 0 0 10px ${C.danger}22` }}>
          <div style={{ width:22, height:22, borderRadius:5, background:'#fff' }}/>
        </button>
        <p style={{ color:C.muted, fontSize:12, margin:0 }}>탭하여 종료</p>
      </div>

      <style>{`@keyframes blink{0%,100%{opacity:1}50%{opacity:0.3}}`}</style>
    </div>
  );
}

// ─── Processing ───────────────────────────────────────────────────────────────

function Processing({ step, autoSave }) {
  const steps = [
    { label:'음성 인식 중', sub:'Whisper Tiny on-device' },
    { label:'회의록 생성 중', sub:'Gemma 4 2B on-device' },
    ...(autoSave ? [{ label:'Notion에 저장 중', sub:'지정 페이지에 업로드' }] : []),
  ];
  return (
    <div style={{ display:'flex', flexDirection:'column', height:'100%', alignItems:'center', justifyContent:'center', padding:40 }}>
      <div style={{ width:48, height:48, borderRadius:'50%', border:`2.5px solid ${C.border}`, borderTopColor:C.accent, animation:'spin 0.75s linear infinite', marginBottom:36 }}/>
      <div style={{ width:'100%', maxWidth:260 }}>
        {steps.map((s, i) => (
          <div key={i} style={{ display:'flex', alignItems:'center', gap:14, padding:'10px 0', opacity: step >= i ? 1 : 0.3, transition:'opacity 0.5s' }}>
            <div style={{ width:22, height:22, borderRadius:'50%', flexShrink:0, display:'flex', alignItems:'center', justifyContent:'center', transition:'all 0.4s', background: step > i ? C.accent : C.surface, border: step === i ? `2px solid ${C.accent}` : '2px solid transparent' }}>
              {step > i
                ? <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="3"><polyline points="20,6 9,17 4,12"/></svg>
                : step === i ? <div style={{ width:5, height:5, borderRadius:'50%', background:C.accent, animation:'pulse 1s ease infinite' }}/> : null}
            </div>
            <div>
              <p style={{ margin:0, fontSize:14, color:C.text, fontWeight:500 }}>{s.label}</p>
              <p style={{ margin:0, fontSize:11, color:C.muted }}>{s.sub}</p>
            </div>
          </div>
        ))}
      </div>
      <style>{`@keyframes spin{to{transform:rotate(360deg)}} @keyframes pulse{0%,100%{opacity:1}50%{opacity:0.2}}`}</style>
    </div>
  );
}

// ─── Minutes ──────────────────────────────────────────────────────────────────

function Minutes({ onBack, onChat }) {
  const [open, setOpen] = useState(false);
  const [copied, setCopied] = useState(false);

  function copy() {
    navigator.clipboard.writeText(TRANSCRIPT).catch(() => {});
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  return (
    <div style={{ display:'flex', flexDirection:'column', height:'100%' }}>

      {/* 고정 헤더 */}
      <div style={{ padding:'14px 16px 12px', borderBottom:`1px solid ${C.border}`, display:'flex', alignItems:'center', gap:10, flexShrink:0 }}>
        <Back go={onBack} />
        <div style={{ flex:1, minWidth:0 }}>
          <p style={{ margin:0, fontSize:14, fontWeight:600, color:C.text, whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>2025 Q2 전략 회의</p>
          <p style={{ margin:0, fontSize:11, color:C.muted }}>오늘 14:30 · 45분</p>
        </div>
        <button style={{ display:'flex', alignItems:'center', gap:6, background:C.surface, border:`1px solid ${C.border}`, borderRadius:9, padding:'6px 11px', cursor:'pointer', color:C.text, fontSize:12, fontFamily:'inherit', flexShrink:0 }}>
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><polyline points="15,3 21,3 21,9"/><line x1="10" y1="14" x2="21" y2="3"/></svg>
          Notion 저장
        </button>
      </div>

      {/* 스크롤 영역 */}
      <div style={{ flex:1, overflowY:'auto', position:'relative' }}>

        {/* ① 원본 스크립트 토글 바 — sticky */}
        <div style={{
          position:'sticky', top:0, zIndex:10,
          background:C.bg,
          borderBottom:`1px solid ${C.border}`,
          display:'flex', alignItems:'center',
          padding:'0 20px',
          height:42,
        }}>
          {/* 왼쪽: 펼치기/접기 클릭 영역 */}
          <div
            onClick={() => setOpen(v => !v)}
            style={{ display:'flex', alignItems:'center', gap:8, flex:1, cursor:'pointer', height:'100%' }}>
            <svg
              width="11" height="11" viewBox="0 0 24 24"
              fill="none" stroke={C.muted} strokeWidth="2.5"
              style={{ transform: open ? 'rotate(90deg)' : 'rotate(0deg)', transition:'transform 0.2s', flexShrink:0 }}>
              <polyline points="9,18 15,12 9,6"/>
            </svg>
            <span style={{ fontSize:12.5, color:C.muted, fontWeight:500, userSelect:'none' }}>원본 스크립트 보기</span>
          </div>

          {/* 오른쪽: 복사 버튼 — 열렸을 때만 */}
          {open && (
            <button
              onClick={copy}
              style={{
                display:'flex', alignItems:'center', gap:5,
                padding:'5px 10px', borderRadius:7,
                background: copied ? '#1a3a2e' : C.surface,
                border: `1px solid ${copied ? C.accent : C.border}`,
                color: copied ? C.accent : C.muted,
                fontSize:12, cursor:'pointer', fontFamily:'inherit',
                transition:'all 0.2s', flexShrink:0,
              }}>
              {copied ? (
                <>
                  <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="20,6 9,17 4,12"/></svg>
                  복사됨
                </>
              ) : (
                <>
                  <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>
                  복사
                </>
              )}
            </button>
          )}
        </div>

        {/* ② 스크립트 본문 — 일반 흐름으로 스크롤 */}
        {open && (
          <div style={{ background:C.surface, padding:'16px 20px', borderBottom:`1px solid ${C.border}`, animation:'fadeIn 0.15s ease' }}>
            <pre style={{ margin:0, whiteSpace:'pre-wrap', color:C.muted, fontSize:12.5, lineHeight:1.9, fontFamily:'inherit' }}>
              {TRANSCRIPT}
            </pre>
          </div>
        )}

        {/* ③ 회의록 본문 */}
        <pre style={{ margin:0, padding:'18px 20px 28px', whiteSpace:'pre-wrap', color:C.text, fontSize:13.5, lineHeight:1.8, fontFamily:'inherit' }}>
          {MINUTES}
        </pre>

      </div>

      {/* 하단 버튼 */}
      <div style={{ padding:'10px 16px 28px', borderTop:`1px solid ${C.border}`, flexShrink:0 }}>
        <button onClick={onChat}
          style={{ width:'100%', padding:'13px', borderRadius:13, background:C.surface, border:`1px solid ${C.border}`, cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', gap:9, color:C.muted, fontSize:14, fontFamily:'inherit' }}
          onMouseEnter={e => e.currentTarget.style.background = C.hover}
          onMouseLeave={e => e.currentTarget.style.background = C.surface}>
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
          추가 작업 요청
        </button>
      </div>

      <style>{`@keyframes fadeIn{from{opacity:0;transform:translateY(-4px)}to{opacity:1;transform:translateY(0)}}`}</style>
    </div>
  );
}

// ─── Chat ─────────────────────────────────────────────────────────────────────

function Chat({ onBack }) {
  const [msgs, setMsgs] = useState([{ r:'a', t:'안녕하세요! 이 회의 내용을 기반으로 추가 작업을 요청하거나 궁금한 내용을 질문해 보세요.' }]);
  const [input, setInput] = useState('');
  const [typing, setTyping] = useState(false);
  const endRef = useRef(null);
  useEffect(() => { endRef.current?.scrollIntoView({ behavior:'smooth' }); }, [msgs, typing]);

  function send(text) {
    const m = text || input;
    if (!m.trim()) return;
    setInput('');
    setMsgs(prev => [...prev, { r:'u', t:m }]);
    setTyping(true);
    setTimeout(() => {
      setTyping(false);
      setMsgs(prev => [...prev, { r:'a', t: QUICK[m] || `"${m}"에 대한 분석을 완료했습니다. 추가로 필요한 사항이 있으시면 말씀해 주세요.` }]);
    }, 900);
  }

  return (
    <div style={{ display:'flex', flexDirection:'column', height:'100%' }}>
      <div style={{ padding:'14px 16px 12px', borderBottom:`1px solid ${C.border}`, display:'flex', alignItems:'center', gap:10, flexShrink:0 }}>
        <Back go={onBack} />
        <div>
          <p style={{ margin:0, fontSize:14, fontWeight:600, color:C.text }}>추가 작업</p>
          <p style={{ margin:0, fontSize:11, color:C.muted }}>2025 Q2 전략 회의 기반</p>
        </div>
      </div>
      <div style={{ padding:'10px 14px 8px', display:'flex', gap:7, overflowX:'auto', borderBottom:`1px solid ${C.border}`, flexShrink:0 }}>
        {Object.keys(QUICK).map(l => (
          <button key={l} onClick={() => send(l)}
            style={{ padding:'6px 12px', borderRadius:20, background:C.surface, border:`1px solid ${C.border}`, color:C.text, fontSize:12, cursor:'pointer', whiteSpace:'nowrap', fontFamily:'inherit', flexShrink:0 }}
            onMouseEnter={e => e.currentTarget.style.background = C.hover}
            onMouseLeave={e => e.currentTarget.style.background = C.surface}>
            {l}
          </button>
        ))}
      </div>
      <div style={{ flex:1, overflowY:'auto', padding:'16px' }}>
        {msgs.map((m, i) => (
          <div key={i} style={{ display:'flex', gap:10, marginBottom:20, flexDirection: m.r==='u' ? 'row-reverse' : 'row', alignItems:'flex-start' }}>
            {m.r === 'a' && (
              <div style={{ width:28, height:28, borderRadius:'50%', background:C.accent, display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0, marginTop:2 }}>
                <svg width="13" height="13" viewBox="0 0 24 24" fill="white"><path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z"/></svg>
              </div>
            )}
            <div style={{ maxWidth:'78%', padding: m.r==='u' ? '10px 14px' : '2px 0', borderRadius: m.r==='u' ? 16 : 0, background: m.r==='u' ? C.surface : 'transparent', color:C.text, fontSize:14, lineHeight:1.7, whiteSpace:'pre-wrap' }}>
              {m.t}
            </div>
          </div>
        ))}
        {typing && (
          <div style={{ display:'flex', gap:10, marginBottom:20 }}>
            <div style={{ width:28, height:28, borderRadius:'50%', background:C.accent, display:'flex', alignItems:'center', justifyContent:'center' }}>
              <svg width="13" height="13" viewBox="0 0 24 24" fill="white"><path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z"/></svg>
            </div>
            <div style={{ display:'flex', gap:4, alignItems:'center' }}>
              {[0,1,2].map(i => <div key={i} style={{ width:6, height:6, borderRadius:'50%', background:C.muted, animation:'dot 1.4s ease infinite', animationDelay:`${i*0.2}s` }}/>)}
            </div>
          </div>
        )}
        <div ref={endRef}/>
        <style>{`@keyframes dot{0%,80%,100%{transform:scale(0.7);opacity:0.4}40%{transform:scale(1);opacity:1}}`}</style>
      </div>
      <div style={{ padding:'8px 14px 28px', flexShrink:0 }}>
        <div style={{ display:'flex', gap:8, alignItems:'flex-end', background:C.surface, borderRadius:16, padding:'10px 10px 10px 16px', border:`1px solid ${C.border}` }}>
          <textarea value={input} onChange={e => setInput(e.target.value)}
            onKeyDown={e => { if (e.key==='Enter' && !e.shiftKey) { e.preventDefault(); send(); }}}
            placeholder="메시지 입력..." rows={1}
            style={{ flex:1, background:'none', border:'none', outline:'none', color:C.text, fontSize:14, resize:'none', fontFamily:'inherit', lineHeight:1.5, maxHeight:100 }}/>
          <button onClick={() => send()}
            style={{ width:32, height:32, borderRadius:10, background: input ? C.accent : C.hover, border:'none', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0, transition:'background 0.2s' }}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22,2 15,22 11,13 2,9"/></svg>
          </button>
        </div>
      </div>
    </div>
  );
}

// ─── Settings ─────────────────────────────────────────────────────────────────

function Settings({ onBack, autoSave, setAutoSave }) {

  return (
    <div style={{ display:'flex', flexDirection:'column', height:'100%' }}>
      <div style={{ padding:'14px 16px 12px', borderBottom:`1px solid ${C.border}`, display:'flex', alignItems:'center', gap:10, flexShrink:0 }}>
        <Back go={onBack} />
        <p style={{ margin:0, fontSize:16, fontWeight:600, color:C.text }}>설정</p>
      </div>
      <div style={{ flex:1, overflowY:'auto', padding:'16px' }}>
        <p style={{ fontSize:10.5, color:C.muted, textTransform:'uppercase', letterSpacing:'0.1em', marginBottom:10 }}>Notion 연동</p>
        {[{ label:'API 토큰', ph:'secret_xxxxxxxxx', type:'password' }, { label:'저장 페이지 URL', ph:'https://notion.so/...', type:'text' }].map(f => (
          <div key={f.label} style={{ marginBottom:10 }}>
            <label style={{ display:'block', fontSize:12, color:C.muted, marginBottom:6 }}>{f.label}</label>
            <input type={f.type} placeholder={f.ph}
              style={{ width:'100%', background:C.surface, border:`1px solid ${C.border}`, borderRadius:10, padding:'10px 13px', color:C.text, fontSize:13, outline:'none', fontFamily:'inherit', boxSizing:'border-box' }}
              onFocus={e => e.target.style.borderColor = C.accent}
              onBlur={e => e.target.style.borderColor = C.border}/>
          </div>
        ))}

        {/* 자동 저장 토글 */}
        <div onClick={() => setAutoSave(v => !v)}
          style={{ display:'flex', alignItems:'center', justifyContent:'space-between', padding:'11px 14px', background:C.surface, borderRadius:10, border:`1px solid ${C.border}`, marginTop:10, cursor:'pointer' }}>
          <div>
            <p style={{ margin:0, fontSize:13, color:C.text, fontWeight:500 }}>회의록 완성 시 자동 저장</p>
            <p style={{ margin:0, fontSize:11, color:C.muted, marginTop:2 }}>완성 즉시 Notion에 자동으로 저장됩니다</p>
          </div>
          <div style={{ width:42, height:24, borderRadius:12, background: autoSave ? C.accent : C.border, transition:'background 0.2s', display:'flex', alignItems:'center', padding:'2px', flexShrink:0, marginLeft:12 }}>
            <div style={{ width:20, height:20, borderRadius:'50%', background:'#fff', transform: autoSave ? 'translateX(18px)' : 'translateX(0)', transition:'transform 0.2s', boxShadow:'0 1px 3px rgba(0,0,0,0.3)' }}/>
          </div>
        </div>

        <p style={{ fontSize:10.5, color:C.muted, textTransform:'uppercase', letterSpacing:'0.1em', margin:'24px 0 10px' }}>회의록 작성 지침</p>
        <textarea placeholder="예: 참석자, 안건, 결정사항, 액션아이템 순으로 작성하되 담당자와 마감일 포함..." rows={5}
          style={{ width:'100%', background:C.surface, border:`1px solid ${C.border}`, borderRadius:10, padding:'10px 13px', color:C.text, fontSize:13, outline:'none', fontFamily:'inherit', resize:'vertical', boxSizing:'border-box', lineHeight:1.6 }}
          onFocus={e => e.target.style.borderColor = C.accent}
          onBlur={e => e.target.style.borderColor = C.border}/>
        <p style={{ fontSize:10.5, color:C.muted, textTransform:'uppercase', letterSpacing:'0.1em', margin:'24px 0 10px' }}>모델 정보</p>
        <div style={{ background:C.surface, borderRadius:12, border:`1px solid ${C.border}`, marginBottom:28, overflow:'hidden' }}>
          {[['STT 모델','Whisper Tiny'],['LLM 모델','Gemma 4 2B'],['처리 방식','온디바이스'],['지원 플랫폼','Android / iOS']].map(([k,v], i, a) => (
            <div key={k} style={{ display:'flex', justifyContent:'space-between', padding:'11px 16px', borderBottom: i < a.length-1 ? `1px solid ${C.border}` : 'none' }}>
              <span style={{ fontSize:13, color:C.muted }}>{k}</span>
              <span style={{ fontSize:13, color:C.accent, fontWeight:500 }}>{v}</span>
            </div>
          ))}
        </div>
        <button style={{ width:'100%', padding:13, borderRadius:12, background:C.accent, border:'none', cursor:'pointer', color:'#fff', fontSize:14, fontWeight:600, fontFamily:'inherit' }}
          onMouseEnter={e => e.currentTarget.style.background = C.accentDark}
          onMouseLeave={e => e.currentTarget.style.background = C.accent}>
          저장
        </button>
      </div>
    </div>
  );
}

// ─── App ──────────────────────────────────────────────────────────────────────

export default function App() {
  const [screen, setScreen] = useState('home');
  const [time, setTime] = useState(0);
  const [step, setStep] = useState(0);
  const [wave, setWave] = useState(Array.from({length:30}, () => 20));
  const [autoSave, setAutoSave] = useState(false);
  const tRef = useRef(null); const wRef = useRef(null);

  const recording = screen === 'recording';
  useEffect(() => {
    if (recording) {
      tRef.current = setInterval(() => setTime(t => t+1), 1000);
      wRef.current = setInterval(() => setWave(Array.from({length:30}, () => 15+Math.random()*70)), 120);
    } else {
      clearInterval(tRef.current); clearInterval(wRef.current);
    }
    return () => { clearInterval(tRef.current); clearInterval(wRef.current); };
  }, [recording]);

  function startRec() { setTime(0); setScreen('recording'); }
  function stopRec() {
    setScreen('processing'); setStep(0);
    const total = autoSave ? 3 : 2;
    let s = 0;
    const iv = setInterval(() => {
      s++; setStep(s);
      if (s >= total) { clearInterval(iv); setTimeout(() => setScreen('minutes'), 600); }
    }, 1400);
  }

  const screens = {
    home:       <Home onRec={startRec} onMeeting={() => setScreen('minutes')} onSettings={() => setScreen('settings')} />,
    recording:  <Recording time={time} wave={wave} onStop={stopRec} />,
    processing: <Processing step={step} autoSave={autoSave} />,
    minutes:    <Minutes onBack={() => setScreen('home')} onChat={() => setScreen('chat')} autoSave={autoSave} />,
    chat:       <Chat onBack={() => setScreen('minutes')} />,
    settings:   <Settings onBack={() => setScreen('home')} autoSave={autoSave} setAutoSave={setAutoSave} />,
  };

  return (
    <div style={{ display:'flex', alignItems:'center', justifyContent:'center', minHeight:'100vh', background:'#0d0d0d', fontFamily:"'DM Sans', system-ui, sans-serif" }}>
      <style>{`@import url('https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&display=swap'); *{box-sizing:border-box;margin:0;padding:0} ::-webkit-scrollbar{width:3px} ::-webkit-scrollbar-thumb{background:#3e3e3e;border-radius:2px}`}</style>
      <div style={{ width:390, height:844, background:C.bg, borderRadius:48, overflow:'hidden', boxShadow:'0 0 0 1px #2a2a2a, 0 50px 100px rgba(0,0,0,0.9)', display:'flex', flexDirection:'column' }}>
        <div style={{ padding:'16px 26px 0', display:'flex', justifyContent:'space-between', alignItems:'center', flexShrink:0 }}>
          <span style={{ fontSize:13, fontWeight:600, color:C.text }}>9:41</span>
          <div style={{ width:120, height:22, background:'#000', borderRadius:11 }}/>
          <div style={{ display:'flex', gap:5, alignItems:'center' }}>
            <svg width="15" height="11" viewBox="0 0 24 18" fill={C.text}><rect x="0" y="6" width="4" height="12" rx="1"/><rect x="7" y="3" width="4" height="15" rx="1"/><rect x="14" y="0" width="4" height="18" rx="1"/><rect x="21" y="0" width="3" height="18" rx="1" opacity="0.3"/></svg>
            <div style={{ width:22, height:11, borderRadius:3, border:`1.5px solid ${C.text}`, display:'flex', alignItems:'center', padding:'2px' }}>
              <div style={{ width:'75%', height:'100%', background:C.text, borderRadius:1.5 }}/>
            </div>
          </div>
        </div>
        <div style={{ flex:1, overflow:'hidden', display:'flex', flexDirection:'column' }}>
          {screens[screen]}
        </div>
        <div style={{ height:34, display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0 }}>
          <div style={{ width:130, height:5, background:C.text, borderRadius:3, opacity:0.2 }}/>
        </div>
      </div>
    </div>
  );
}
