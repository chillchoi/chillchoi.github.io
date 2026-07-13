# GALAXY PASSPORT — V2 Master Development Blueprint
**Klleon Digital Human SDK × Samsung Galaxy Fold Flagship Experience**

> Version 2.0 · 2026-07-07 · Single source of truth for all future development.
> Supersedes the V1 prototype (`index.html`, steps 1–13, verified working 2026-07-06).

---

## 0. Ground Truth — What the SDK Actually Gives Us (READ FIRST)

Every design decision below is constrained by verified facts from the working V1 prototype.
Any feature that ignores these facts will fail in implementation. Designers and engineers
must treat this section as physics, not opinion.

| # | Fact (verified in prototype) | Design consequence |
|---|---|---|
| G1 | The Digital Human is a **live WebRTC video stream** (1080×1920, 9:16) rendered into `<avatar-container>` (Shadow DOM, unstylable inside). | We **cannot** make him jump, cheer, put on sunglasses, change outfits, or spread his arms on command. There is no gesture/animation API in Klleon SDK v2. All "excitement" must be staged in the **environment layer** (particles, camera moves, sound, UI choreography) synchronized with energetic speech. If true body animation is required, the **content team must record additional avatar states or clips** — this is a formal asset request, not code. |
| G2 | The grey studio backdrop is **baked into the video**. CSS blend modes tint the human (rejected in V1). | Magical blue/fantasy background behind the avatar requires a **chroma-key / alpha avatar from Klleon content team** (request pending). Until delivered: design compositions where the video is framed as a "portal/window" and the fantasy environment surrounds it. |
| G3 | `speak()` fired immediately after `stopSpeaking()` or during a response is **dropped by the server**. Correct sequencing requires waiting for the `RESPONSE_ENDED` signal. | All character speech must flow through a single **SpeechDirector queue**. No component may call `SDK.speak()` directly. This is the #1 race-condition source. |
| G4 | Only **one callback per event type** (`onStatus`/`onSignal`/`onError`); the last registration wins. | One global **SDKBridge** owns the callbacks and re-broadcasts on an internal event bus. No component registers SDK callbacks directly. |
| G5 | Session init takes **3–8 s** (key check → WS → streaming → `CONNECTED_FINISH`). `destroy()`/re-`init()` costs the same again. | **Never** destroy the session mid-experience. The avatar stream survives all mode/screen changes; screens move *around* it. Reconnect only from Idle reset. |
| G6 | Fold state is detected by **viewport aspect ratio** on resize (verified: works). Device Posture API availability on the target device is unconfirmed. | FoldManager uses ratio thresholds from **config**, enhanced progressively by posture APIs when present. Never hardcode 4:3/9:16 in components. |
| G7 | Camera (`getUserMedia`) works on `localhost`/HTTPS only. LAN HTTP fails. | Device testing of camera steps requires **HTTPS before Milestone 3**. Non-negotiable roadmap item. |
| G8 | SDK key is domain-whitelisted; new origins fail with "허용되지 않은 주소". | Every test/staging/production origin must be registered ahead of time. Keep a living list in `docs/origins.md`. |
| G9 | ADLP avatars need `execution_type: "adlp_worker"` in `init()`. Avatar IDs are per-key authorized. | Avatar ID + execution type live in **config**, never in code. |
| G10 | 350-char limit per message; TTS reading time ≈ 0.9× characters in seconds (rough KR average). | Script lines are authored short (≤ 2 sentences). SpeechDirector estimates duration for choreography timing, then corrects on `RESPONSE_ENDED`. |

### ✅ Resolved decisions (product owner confirmed 2026-07-07 — no further input required)
These were previously open; all now have a ruling so implementation is unblocked. Each is a **default we own**; revisit only if reality contradicts.

1. **Reward verification = visual proof, no infrastructure.** The completed passport (with the traveler's two photos) *is* the evidence staff accept at the event. There is **no scanning system, no verification backend, no server-side check**. The "STAFF ✓" corner is a decorative stamp area staff can eyeball or mark. → Removes an entire backend workstream.
2. **QR code = self-save of the passport image.** The traveler scans their own QR with their own phone to **download/save their Galaxy Passport image**. Because a QR cannot hold a 4K image, the QR encodes a **short-lived URL** to the generated passport PNG. → Requires one tiny piece of infrastructure: a temporary image-host endpoint (upload PNG → return URL → QR encodes URL, expires in e.g. 24 h). This is the *only* server component in the whole product. See §5a.
3. **Output quality = 4K.** The generated passport exports at **3840 px on its long edge** (see §0-Q "4K requirement"). Camera captures request max device resolution. Destination cinematics target 4K source, adaptively down-decoded on device if thermal budget requires (§10-R8). → Drives the PassportRenderer to an offscreen 4K canvas and the AssetLoader encode targets.
4. **Screen ratios — verified from the H8 workshop deck (see `H8-SPEC.md`).** Folded/**Cover** = **10:16 portrait** (5.5″ QHD+ 16:10); Unfolded/**Main** = **4:3 landscape** (7.6″ QHD+). Samsung's own pitch: cover = "full-screen vertical short-form", main = "immersive landscape long-form" — so our **Fold phase (passport-making) lives on the cover screen**, our **Unfold phase (cinematic + keepsake) on the main screen**. FoldManager threshold (`foldThreshold` = 1.0) + all layouts are config-driven, so a different panel is a **single config change**, not a redesign. *(Correction: an earlier draft had this backwards as fold 4:3 / unfold 16:9. It is fold 10:16 / unfold 4:3.)*
5. **One passport per completion, no anti-abuse.** Event/showcase context: every run generates a fresh passport; no per-person limits, no dedupe. Photos are RAM-only and wiped on reset (privacy, EP-17).

### 🔸 Content-team asks (NOT blockers — engine works without them; upgrades if delivered)
Filed in `docs/asset-requests.md`. Ask when requesting/receiving the "expedition guide" avatar:
- **Alpha / chroma-key avatar variant** — enables the true fantasy background behind the guide (the "blue background" wish, G2). Without it: portal-frame composition (already designed, looks great).
- **Emotive avatar states/clips** — idle-loop, celebration, pilot-outfit as separate `avatar_id`s or pre-rendered clips for non-interactive beats. Without them: environment-choreographed emotion (already designed, G1/R10).

### 0-Q. 4K Requirement (new hard requirement)
| Surface | Target |
|---|---|
| **Passport export (the deliverable)** | 3840 px long edge PNG, rendered on an offscreen canvas at 2× device pixel ratio; this is the file the QR links to |
| **Camera captures (both selfies)** | `getUserMedia` requests `{ width: {ideal: 3840}, height: {ideal: 2160} }`; capture canvas sized to the actual returned track resolution (never upscale) |
| **Destination cinematics/loops** | 4K source encodes (H.265/AV1); device plays highest tier it can sustain at 60 fps (AssetLoader picks tier by decode probe, R8) |
| **UI / particles** | vector/CSS + 2× sprite atlases; resolution-independent |

> Note: 4K **live video loops in 5 orbs simultaneously is NOT required** — orbs display at ~100 px, so their loops are 720p (R1). 4K applies to the *final passport*, *full-screen cinematics*, and *camera captures* — the things the user actually sees large or keeps.

---

## 1. Product Vision

**The emotional promise:** *"A being inside the device invites you on a journey — and the device itself is the vehicle."*

This is not a chatbot demo. It is a demonstration that a Digital Human can be a **continuous character** who:
- lives across hardware states (the fold is a narrative device, not a screen resize),
- witnesses and reacts to everything you do (photos, choices, hesitation),
- turns a retail interaction into a **90-second story with a collectible souvenir**.

**Why this showcases Klleon's SDK specifically:**
1. **Persistent presence** — one uninterrupted avatar session across 7+ UI scenes proves the SDK's stream is an ambient layer, not a widget (G5 made into a feature).
2. **Real-time reactivity** — SpeechDirector-driven reactions to user actions within <300 ms of the trigger demonstrate the speak/signal loop's responsiveness.
3. **Hardware-aware AI** — the character *knows* the fold state and directs the user's hands ("이제 펼쳐볼까?"). No competitor demo does this.
4. **Productizable architecture** — the same engine reruns with a different `adventure.json` for museums, retail, education (§11). We're demoing an SDK, so the demo itself must be SDK-shaped.

**The 3 emotional peaks** (everything else exists to serve these):
- **P1 — The Unfold** (opening the device = takeoff): physical action rewarded with a world transformation.
- **P2 — The Return** (selfie 2 approved): "you actually went there" fiction lands.
- **P3 — The Passport Materialization**: the souvenir forms out of light while the guide narrates — the single most screenshotted moment.

---

## 2. Experience Principles

Rules every screen, animation, and line of dialogue must obey. PR reviews check against these.

**Presence**
- **EP-1. The guide never vanishes without narrative cover.** Full-screen takeovers (camera, video, passport) are diegetic: he "steps aside", "opens the window", "hands you the camera". His voice persists even when his video is occluded.
- **EP-2. One continuous session.** SDK session survives from boot to reset (G5). Visual layers move around the stream.
- **EP-3. He acknowledges every meaningful user action** within one beat: choice taps, photo capture, submission, fold/unfold, returning from inactivity. Silence after a user action is a bug.

**Motion & Magic**
- **EP-4. Nothing pops.** Every element materializes (scale+blur+particles in), and dematerializes (drift+fade out). Standard curve: `cubic-bezier(.2,.8,.2,1)`; standard durations: 240 ms (micro), 600 ms (element), 1200 ms (scene).
- **EP-5. Magic has a source.** Particles emanate from the guide's position or the user's touch point — never from screen edges randomly. (Since we can't animate his arms — G1 — the *particle origin at his hands' resting position* creates the "he summoned it" illusion.)
- **EP-6. Idle is alive.** Every state has ambient motion (floating bubbles ±6 px sine drift, particle dust, breathing glow). A static frame anywhere is a bug.

**Waiting & Failure**
- **EP-7. Every wait is authored.** Camera warm-up, canvas compositing, SDK reconnect — each has a scripted line + ambient animation. No spinners, ever. The guide *is* the loading indicator.
- **EP-8. Failure is in-character.** Camera denied → "이런, 카메라 문이 잠겨있네! 설정에서 열어줄래?" Errors never show codes to users (codes go to console + on-screen debug badge in dev builds only).
- **EP-9. Inactivity is a graceful landing,** not a timeout. 30 s → guide verbally re-invites once; 15 s more → soft farewell line → reset to the correct Idle for the current fold state (§4).

**Hardware**
- **EP-10. Fold transitions are always rewarded.** Any fold-state change gets an immediate visual+verbal response — even out-of-sequence ones (user unfolds early → guide playfully asks to close it: "아직이야! 조금만 기다려줘. 접어두면 출발 준비 완료!").
- **EP-11. Design each mode natively.** Fold Mode (compact, portrait, intimate) and Wide Mode (cinematic, panoramic) have independent layouts, type scales, and compositions. Shared components adapt via mode tokens, never via stretching.

**Tone**
- **EP-12. Energy ratchets upward** through the mission (§9 tone arc) and resets only at Idle.
- **EP-13. Speech ≤ 2 sentences per beat.** Long explanations are split across beats or paired with visuals. (G10.)
- **EP-14. The user is "여행자" (traveler)**, never "고객/사용자". The fiction never breaks — even in error states.

**Quality & Privacy**
- **EP-15. The keepsake is 4K.** The passport the traveler saves is the product's business card — it renders at 4K (§0-Q) and must look flawless zoomed in. Camera captures at max resolution; never upscale.
- **EP-16. Perceived performance > raw fidelity.** 60 fps and instant response beat higher resolution everywhere the user *interacts*; 4K is spent on the *keepsake and cinematics*, not on live orb loops (R1).
- **EP-17. Photos never touch disk.** All traveler images live in memory only, are used to compose the passport, and are wiped on reset/inactivity. The QR-hosted copy auto-expires (§5a). Defensible in an enterprise/Samsung privacy review without a legal detour.

---

## 3. User Journey V2

> Scene notation: `S#`. All speech lines are final-draft Korean, authored for TTS rhythm (test each with `speak()` before freeze). Timings assume KR TTS ≈ 5.5 chars/sec.

### S0 · BOOT (hidden from user)
- **Purpose:** Reach `CONNECTED_FINISH` + preload critical assets before anyone approaches.
- **UI:** Brand splash: dark navy, slow-drifting star particles, pulsing Klleon × Galaxy mark.
- **Engineering:** `SDK.init()` (ADLP per config); preload particle sprites, destination loop videos, filter LUTs, SFX. Retry init ×3 with backoff; after 3 fails → staff-facing error screen (only non-diegetic screen in the app).
- **Exit →** S1 when `CONNECTED_FINISH` && preload ≥ critical set.

### S1 · FOLD IDLE (attract loop)
- **Purpose:** Pull passersby in. This screen runs 90% of the day — it must be the best-looking loop in the app.
- **User goal:** Decide to touch. **Guide goal:** Radiate "adventure is waiting".
- **UI (Fold Mode — 10:16 portrait cover screen):** Guide full-body center (EP-G2 framing: video panel presented as a glowing "portal" card with rounded 24 px corners, floating ±4 px; fantasy environment fills the surround — aurora gradient, drifting embers). Title lockup "GALAXY PASSPORT" sits **low (bottom), clear of the guide's head**. Soft CTA bubble: *"여행을 떠나볼까?"*
- **Behavior:** Every 25 s an attract line rotates (pool of 5, §9). Any tap → S2.
- **Edge:** If unfolded during S1 → switch to UNFOLD IDLE variant (wide composition, same content) — no scolding; idle is stateless.

### S2 · GREETING & CHOICE
- **Purpose:** Establish character + offer 3 paths.
- **Guide goal:** Make choosing feel like being handed something magical.
- **Speech (on entry):** `"오! 드디어 왔구나, 여행자! 나는 은하수부터 조선까지 안 가본 데가 없는 가이드야."` → beat → `"오늘은 뭐부터 해볼까?"`
- **Animation:** On the second line, **three glass bubbles materialize sequentially (120 ms stagger) from the guide's hand-height position** (EP-5 illusion): ✨ *기능 구경하기* · 💬 *자유 대화* · 🧭 *어드벤처 미션* (visually largest, brightest glow, gentle pulse).
- **UI:** Bubbles are organic circles (not rectangles), backdrop-blur 16 px, 1 px white/25% border, inner glow, idle sine-float (EP-6). Tap → bubble bursts into 12 particles, others drift off-screen.
- **Paths:** 기능 구경하기 → S2a guided tour (guide narrates 3 capability beats, then returns here). 자유 대화 → S2b free chat (chat-container styled to theme, `sendMessage` LLM loop; inactivity returns here). 미션 → S3.
- **Edge:** Tap during guide speech → allowed; SpeechDirector cancels remaining queue gracefully (`stopSpeaking` → await `RESPONSE_ENDED` → next line; G3).

### S3 · PASSPORT MATERIALIZATION (mission accept)
- **Purpose:** Mission trailhead; introduce the passport as an *object* before asking for a photo. New scene vs V1 (V1 jumped straight to camera — weak storytelling).
- **Speech:** `"좋아, 어드벤처 시작이다!"` → `"여행자라면 여권이 필요하지. 자, 받아!"`
- **Animation (the first "wow", 2.4 s):** Particle vortex gathers at guide's hand position → converges → **blank fantasy passport forms** (golden edges, emblem, floating) → drifts to screen center → opens to reveal an empty photo slot with a pulsing dashed outline.
- **Speech (cont.):** `"어라? 사진이 비어있네. 여행자 얼굴부터 담아볼까?"` → auto-advance to S4 (800 ms).
- **Dev note:** Passport object is a reusable Canvas/DOM hybrid component (`PassportView`) — the same component later renders the final passport (§7). Build once.

### S4 · SELFIE 1 — PASSPORT PHOTO
- **Purpose:** First camera interaction; low pressure, guided.
- **UI (Fold Mode):** Camera fills the passport's photo slot frame — i.e., the **camera lives inside the passport graphic**, not a raw fullscreen camera (differentiates from selfie 2; reinforces "passport photo"). Oval guide, mirrored preview, big glass shutter orb.
- **Guide presence:** Video panel shrinks to a **corner medallion (128 px circle, bottom-left)**, still speaking (EP-1): `"오케이, 여기 봐! 웃어도 되고, 여권답게 진지해도 좋아."`
- **Flow:** Shutter → 300 ms white flash + freeze → retake (`다시 찍기` ghost bubble) / confirm (`좋아, 이 얼굴이야!` glowing bubble).
- **Failure:** Camera denied → EP-8 line + retry bubble + skip path (staff can allow a photo-less passport variant — see edge matrix).
- **Edge:** Inactivity 30 s at camera → EP-9 (camera torn down before idle reset — release `getUserMedia` tracks always in `onExit`).

### S5 · SELFIE 1 CELEBRATION
- **Purpose:** Peak #0.5 — the journey "officially begins". V1's "좋아요!" was flat (feedback).
- **Choreography (2.8 s):** Photo flies into passport slot → **golden stamp SLAMS diagonally** onto the page ("ENTRY ✦") with screen-shake (4 px, 120 ms) + burst of 40 particles + SFX. Simultaneously guide (video restored to center):
- **Speech:** `"됐다!! 이제 진짜 여행자네!"` → `"자, 그럼… 어디로 떠나볼까? 세계는 넓고, 우리는 자유야!"`
- **G1 honesty:** The avatar won't visibly jump. The **stamp slam + shake + SFX carry the celebration physically**; his line carries it verbally. If content team later delivers a "celebration clip", CelebrationScene swaps it in via config flag.
- **Auto →** S6.

### S6 · DESTINATION BUBBLES
- **Purpose:** The choice moment — bubbles, not buttons (feedback).
- **Destinations (config-driven, launch set of 5):** 🗼 파리 · 🍊 제주 · 🏯 조선 (시간여행) · 🌆 미래도시 · 🔮 판타지 월드
- **UI:** Five glass orbs (Ø 96–120 px) drift in gentle orbital paths around the guide's upper body area. **Inside each orb: a looping muted video thumbnail** (720p, 3–5 s seamless loop, `object-fit: cover`, circular mask) — the "miniature living world".
- **Interaction (two-tap, per feedback):**
  - Tap 1 → orb **expands to Ø 70% viewport width**, others shrink & dim to 40%; preview loop plays with ambient audio (low volume); caption + one guide teaser line (`파리: "예술과 빛의 도시! 크루아상은 덤이야."`). Second orb tap while one is expanded → swap (previous shrinks back).
  - Tap 2 (on the expanded orb) → **selection burst**: orb shatters into particles that swirl into the passport's "DESTINATION" field.
- **⚠️ Engineering ruling (overrides feedback):** Feedback asked for **live 3D worlds per bubble**. Five concurrent WebGL contexts + a live WebRTC avatar stream on a fold-device browser is a guaranteed jank/thermal failure. **Ruling: pre-rendered seamless video loops** (indistinguishable at Ø 100 px, 60fps cheap, art-directable). One *optional* Three.js scene for the *expanded* state only (single context, destroyed on collapse) may be evaluated in M6 as a stretch goal. See §10-R1, §13.
- **Speech (on entry):** `"내가 제일 아끼는 다섯 곳을 소환했어. 하나 골라봐 — 구경만 해도 좋아!"`

### S7 · DEPARTURE HYPE (pilot transformation)
- **Purpose:** Build anticipation; make the user *want* to unfold. Peak P1 setup.
- **Speech:** `"조선이라고?! 최고의 선택이야!"` (destination-specific line ×5, §9) → `"지금부터 나는 너의 파일럿! 탑승 준비 됐지?"`
- **Visual (in lieu of outfit change — G1):** **Environment transforms around him**: aurora background shifts to the destination's color key, a glowing "PILOT MODE" winged emblem materializes and docks top-center, floating ✈ particles, deep engine-rumble SFX begins low.
- **Countdown:** Giant translucent `3… 2… 1…` numerals form from particles behind the passport. On `1`:
- **→ S8.** *(If content team supplies a pilot-outfit avatar variant, config swaps avatar here during the countdown's 3 s using a parallel pre-connected session — M6 stretch; do not architecture-block on it.)*

### S8 · UNFOLD INVITATION
- **Purpose:** Direct the physical action. The fold IS the boarding gate.
- **UI:** Screen dims to cockpit-dark; animated fold-opening glyph (two panels, hinge light leaking through, looping); text `"Galaxy를 펼치면, 이륙합니다"`.
- **Speech:** `"자, 여행자. 게이트를 열어줘 — Galaxy를 활짝 펼치는 거야!"` Then every 12 s a nudge line (max 2, then EP-9 idle rules).
- **Trigger:** FoldManager posture change → **S9 immediately** (target: first Wide-Mode frame within 500 ms of resize event — pre-mount Wide layout hidden during S7).
- **Edge:** User folds back mid-transition → pause Wide scene, guide: `"어어, 문이 닫혔어! 다시 열어줘~"` → resume.
- **Dev build:** `펼쳤어요 (테스트)` ghost button, stripped by production flag.

### S9 · TAKEOFF & DESTINATION CINEMATIC (Wide Mode begins — Peak P1)
- **Purpose:** The single biggest payoff. The entire app transforms (feedback: "everything becomes wide").
- **Transition choreography (total ~1.4 s):** On unfold: white-gold light sweep across the seam → UI splits and slides off both edges → **Wide Mode world fades in already moving** (never fade-from-black; momentum reads as "we're flying").
- **Cinematic (4 s, per destination):** Full-bleed destination flythrough video (pre-rendered, high-bitrate, panoramic composition) + destination score swell + light vignette. Guide video docks as a **cockpit-corner medallion** narrating: `"저기 봐! 남산 위로… 아니, 여긴 조선의 한양이야!"` Progress shimmer along the bottom edge (authored wait, EP-7).
- **Wide Mode global changes (persist through S12):** wide layout grid, larger type scale, panoramic particle field, destination color theme on all UI tokens.
- **Auto →** S10.

### S10 · THEMED SELFIE INVITATION
- **Speech:** `"도착~! 기념사진 없이 돌아갈 순 없지."` → `"조선 여행자로 변신시켜줄게. 준비됐어?"`
- **UI:** Single large bubble: `📸 변신하고 찍기` + small preview chip showing the filter's look (pre-rendered sample). Guide medallion visible.
- **→ S11** on tap.

### S11 · SELFIE 2 — FULL-SCREEN THEMED CAMERA
- **Purpose:** The "you are there" photo. Full-screen camera (feedback), destination filter baked in.
- **UI (Wide Mode):** Camera fills the entire display. **Filter pipeline:** CSS filter on live preview + same transform baked into canvas at capture (V1-proven), **plus** destination frame overlay (art asset: e.g., 조선 = ink-brush border + 갓 sticker anchor points; 미래도시 = HUD neon frame). Guide medallion bottom-corner with live commentary lines every ~6 s (pool of 3).
- **Capture flow:** identical mechanics to S4 (shutter orb → freeze → retake/confirm) — same `CameraScene` component, different config (fullscreen vs passport-slot, filter id).
- **Failure/edge:** identical to S4 matrix.

### S12 · MISSION COMPLETE CELEBRATION (Peak P2)
- **Choreography (3.2 s):** Photo 2 shrinks + flies toward passport (which slides in from edge) → second stamp SLAM ("ARRIVAL ✦ 조선") → confetti burst full-width + fireworks particles + triumphant SFX.
- **Speech:** `"우와아—! 해냈어! 조선까지 갔다 온 여행자, 바로 너야!"` → `"이제 마지막 선물이 남았지. 잘 봐."`
- **→ S13.**

### S13 · PASSPORT GENERATION (Peak P3 — the showstopper)
- **Purpose:** Souvenir materialization + instructions delivered *during* the animation (feedback).
- **Choreography (8 s total, speech-synced via SpeechDirector duration estimates):**
  1. (0–2 s) Screen dims; all remaining UI dissolves into particles that spiral toward center. Guide: `"오늘의 모든 순간을 모아서…"`
  2. (2–4.5 s) Particles compress into a blinding point → **passport forms closed**, rotating slowly, gold emblem catching light. Guide: `"세상에 단 하나뿐인, 너만의 Galaxy Passport!"`
  3. (4.5–6 s) Passport **flies toward camera** (scale 0.2→1.15 with motion blur) → settles → **unfolds open** filling the screen.
  4. (6–8 s) Contents stamp in one by one (photo 1 → photo 2 → stamps → QR). Guide, over this: `"화면을 꾹 눌러 저장하고, 직원에게 보여줘. 선물이 기다리고 있어!"`
- **→ S14.**

### S14 · PASSPORT REVEAL / REWARD (terminal interactive state)
- **The collectible (full spec):** Fantasy-passport art direction — deep navy leather texture, gold foil border, constellation watermark. **Rendered at 4K (§0-Q).** Contents: ① Selfie 1 (passport slot, oval matte) ② Selfie 2 (polaroid-tilted, taped corner) ③ 닉네임 (see below) ④ Traveler no. (`GP-2026-####`, sequential per device-day) ⑤ Destination name + emblem ⑥ 완료 날짜 ⑦ 2 magical stamps (ENTRY/ARRIVAL) ⑧ "TRAVEL COMPLETE" gold ribbon ⑨ **QR code → short-lived URL of THIS passport's 4K image** (traveler scans with own phone to save it — §5a) ⑩ staff-check corner (decorative "STAFF ✓" stamp area; staff eyeball the passport as proof — no scanning).
- **Nickname:** After reveal, guide asks `"마지막으로, 여행자 이름을 알려줘!"` → single glass input bubble (Korean/eng, 8 chars max, profanity filter list from config) → name inscribes in gold with a writing animation. **Skippable** (default: "이름 모를 여행자").
- **Actions (glass bubbles):** `💾 이미지로 저장` (4K PNG direct download / long-press hint) · `📱 QR로 저장` (QR enlarges → traveler scans with own phone → saves the 4K image from the short-lived URL) · `✅ 미션 끝!`. Staff simply view the on-screen passport as event proof (no scan).
- **Speech (farewell):** `"함께해서 최고였어, [닉네임]! 다음엔 어느 세계로 가볼까? 또 만나자!"`
- **Exit:** `미션 끝!` tap or 60 s inactivity → S15.

### S15 · RESET
- Passport dissolves upward into stars (2 s) → Wide farewell frame → prompt to fold (`"다음 여행자를 위해 접어줘!"`) → any fold state accepted after 10 s → wipe session data (photos, nickname — **privacy: all user images live in memory only, never persisted**, cleared here and on any reset) → S1.

### Global edge matrix (applies to all scenes)
| Event | Response |
|---|---|
| SDK `SOCKET_DISCONNECTED_UNEXPECTEDLY` / `STREAMING_FAILED` mid-mission | Freeze scene, ambient particles keep moving; silent auto `destroy()`→`init()` (≤ 2 attempts); guide line on recovery: `"휴, 잠깐 난기류였어! 계속 가자."` If unrecoverable → apologetic reset to S1. |
| Unfold during S1–S7 (early) | EP-10 playful redirect; mission state preserved. |
| Fold during S9–S13 (mid-Wide) | Per feedback: guide explains mission continues unfolded, invites re-unfold; 30 s → inactivity rules. |
| Inactivity (30 s + 15 s grace) | EP-9 → correct Idle for current posture; camera torn down; mission data wiped. |
| Camera permission denied | EP-8 retry ×1 → offer photo-less path (passport renders destination art in photo slots). |
| `TIME_EXHAUSTED` / `QUOTA_EXCEEDED` (SDK session budget) | Staff-facing badge + graceful "정비 중" idle variant. Monitor budget in ops dashboard (M7). |

---

## 4. State Machine

Single FSM owns the app. Scenes = states. No component changes state directly; they emit intents.

```
STATES
  BOOT, FOLD_IDLE, UNFOLD_IDLE, GREETING, TOUR, FREE_CHAT,
  PASSPORT_INTRO, CAMERA_1, CELEBRATE_1, DESTINATION, DEPARTURE,
  UNFOLD_WAIT, CINEMATIC, SELFIE2_INVITE, CAMERA_2, CELEBRATE_2,
  PASSPORT_GEN, REWARD, RESETTING, ERROR_STAFF

TRANSITIONS (event → target)
  BOOT:           sdkReady∧assetsReady → FOLD_IDLE | UNFOLD_IDLE (by posture)
                  initFailed×3        → ERROR_STAFF
  FOLD_IDLE:      tap                 → GREETING
                  posture:open        → UNFOLD_IDLE
  UNFOLD_IDLE:    tap                 → GREETING        posture:closed → FOLD_IDLE
  GREETING:       pick:tour → TOUR   pick:chat → FREE_CHAT   pick:mission → PASSPORT_INTRO
  TOUR/FREE_CHAT: done|inactive       → GREETING (fresh bubbles)
  PASSPORT_INTRO: animDone            → CAMERA_1
  CAMERA_1:       confirmed           → CELEBRATE_1     denied×2 → CELEBRATE_1(photoless)
  CELEBRATE_1:    animDone            → DESTINATION
  DESTINATION:    selected            → DEPARTURE
  DEPARTURE:      countdownDone       → UNFOLD_WAIT
  UNFOLD_WAIT:    posture:open        → CINEMATIC
  CINEMATIC:      videoEnded          → SELFIE2_INVITE
  SELFIE2_INVITE: tap                 → CAMERA_2
  CAMERA_2:       confirmed           → CELEBRATE_2
  CELEBRATE_2:    animDone            → PASSPORT_GEN
  PASSPORT_GEN:   animDone            → REWARD
  REWARD:         done|inactive60     → RESETTING
  RESETTING:      wiped               → FOLD_IDLE | UNFOLD_IDLE

GLOBAL GUARDS (any state)
  inactivity(30+15) [except BOOT, CINEMATIC, PASSPORT_GEN, ERROR] → RESETTING
  sdkFatal → ERROR_STAFF
  posture change → routed to current scene's onPosture() (EP-10); scenes without
    a handler get the default playful redirect
```

Each state implements the Scene interface: `preload() → enter(ctx) → onPosture(p) → onInactivity() → exit()`. `exit()` MUST release cameras, timers, particle emitters (leak audit in M5).

---

## 5. SDK / Application Architecture

**Stack ruling:** Vite + TypeScript, **framework-free core** (the avatar is a web component; the app is choreography-heavy and imperative — a vDOM fights us). Rendering helpers via small utilities; particles on a single shared `<canvas>`; FSM hand-rolled (~80 lines, typed) — XState optional if the team prefers.

```
┌─────────────────────────────────────────────────────┐
│                    AdventureApp                     │
│   boots config → managers → FSM → first scene       │
├────────────┬───────────────────────┬────────────────┤
│  EventBus (typed pub/sub — the only coupling layer) │
├────────────┴───────────────────────┴────────────────┤
│ SDKBridge        owns the ONLY onStatus/onSignal/   │
│                  onError registrations (G4);        │
│                  rebroadcasts as bus events;        │
│                  reconnect policy (G5)              │
│ SpeechDirector   speech queue; one line in flight;  │
│                  awaits RESPONSE_ENDED (G3);        │
│                  duration estimator for choreo      │
│                  sync; cancelAll() on scene exit    │
│ FoldManager      posture from config thresholds +   │
│                  progressive Device Posture API;    │
│                  emits posture:open/closed          │
│ SceneManager     FSM; mounts/unmounts scenes;       │
│                  enforces exit() cleanup            │
│ CameraManager    getUserMedia lifecycle; capture    │
│                  pipeline (mirror, filter, overlay  │
│                  compositing); guaranteed release   │
│ FXEngine         particle systems, screen shake,    │
│                  stamp slams, materialize/dissolve; │
│                  one shared canvas; sprite pooling  │
│ AudioDirector    SFX + per-destination score;       │
│                  ducks under avatar TTS             │
│ PassportStore    photos (RAM only), nickname,       │
│                  destination, timestamps; wipe()    │
│ PassportRenderer offscreen-canvas composer → PNG;   │
│                  also drives live PassportView      │
│ AssetLoader      manifest-driven preload; critical/ │
│                  lazy tiers; retry; readiness gates │
│ InactivityWatch  global timer; per-scene exemptions │
│ ConfigService    adventure.json + device.json +     │
│                  secrets (sdk key, avatar id, ADLP) │
└─────────────────────────────────────────────────────┘
```

**Plugin architecture (the SDK story, §11):** A deployment = engine + `adventure.json` + asset pack. Scenes are registered per adventure (`registerScene(id, factory)`); the mission flow is a declarative scene sequence in config. New verticals add scenes/assets — they don't touch managers.

### 5a. The one server component — Passport Image Host (for QR self-save)

The app is otherwise 100% client-side. The QR self-save feature (§0-decision 2) needs exactly one endpoint:

```
POST /passport   body: { png: <4K image blob> }   → { url: "https://…/p/<id>", expires: 24h }
GET  /p/<id>     → serves the PNG (or a mobile-friendly save page with the image)
```

- **Why it exists:** a QR code physically cannot contain a 4K image; it holds a URL. When the passport is generated (S13), the client uploads the PNG and receives a short URL, which becomes the QR payload.
- **Scope:** dead-simple. Any object store + signed URL works (S3 + presigned, Cloudflare R2, or a 30-line serverless function). Images auto-expire (24 h default, config) — reinforces RAM-only privacy (EP-17).
- **Fallback if unavailable / offline venue:** QR is hidden; only the direct `💾 이미지로 저장` download button shows. The experience never blocks on the network for this. (R11.)
- **Origin/CORS:** the host origin must allow the app origin; add to `docs/origins.md` alongside SDK whitelisting (G8).

---

## 6. Folder Structure

```
galaxy-passport/
├─ index.html                    # shell only
├─ vite.config.ts
├─ src/
│  ├─ main.ts                    # AdventureApp boot
│  ├─ core/
│  │  ├─ EventBus.ts  SceneManager.ts  StateMachine.ts
│  │  ├─ ConfigService.ts  AssetLoader.ts  InactivityWatch.ts
│  ├─ sdk/
│  │  ├─ SDKBridge.ts  SpeechDirector.ts  types.ts
│  ├─ device/
│  │  ├─ FoldManager.ts  CameraManager.ts
│  ├─ fx/
│  │  ├─ FXEngine.ts  particles/  transitions/  AudioDirector.ts
│  ├─ passport/
│  │  ├─ PassportStore.ts  PassportRenderer.ts  PassportView.ts  qr.ts
│  ├─ scenes/                    # one file per FSM state
│  │  ├─ BootScene.ts  IdleScene.ts  GreetingScene.ts … RewardScene.ts
│  ├─ ui/
│  │  ├─ components/  (GlassBubble, ShutterOrb, GuideMedallion,
│  │  │                DestinationOrb, StampSlam, CountdownNumerals,
│  │  │                NicknameInput, DebugBadge)
│  │  ├─ tokens.css   mode-fold.css   mode-wide.css
│  ├─ script/
│  │  ├─ lines.ko.ts             # ALL speech lines, keyed, per destination
│  └─ debug/                     # dev-only sim buttons, state inspector
├─ adventures/
│  └─ galaxy-passport/
│     ├─ adventure.json          # flow, destinations, filters, thresholds
│     └─ assets/  (loops/ cinematics/ filters/ sfx/ art/)
├─ docs/
│  ├─ BLUEPRINT.md (this file)  origins.md  asset-requests.md
└─ tools/ serve-https.ts         # mkcert local HTTPS for device testing
```

---

## 7. UI Architecture

**Modes:** `mode-fold` / `mode-wide` classes on root; all layout tokens (spacing, type scale, orb sizes, guide-panel geometry) defined per mode in CSS custom properties. Components consume tokens only (EP-11).

**Screens** = scenes (§3). **Persistent layers** (z-order):
1. `#environment` — gradient sky, ambient particles (always animating)
2. `#avatar-layer` — `<avatar-container>` in one of 3 framings: **Portal** (idle/greeting, centered card), **Stage** (mission talk beats, large center), **Medallion** (camera/cinematic, corner circle). Framing changes animate via FLIP (600 ms) — the *same stream element* is never unmounted (G5).
3. `#fx-canvas` — FXEngine shared canvas
4. `#scene-root` — current scene's DOM
5. `#overlay-root` — passport view, countdowns, celebration stamps
6. `#debug-root` — dev builds only

**Reusable components:** GlassBubble (option/CTA/speech variants) · DestinationOrb (video-loop mask + 2-tap logic) · ShutterOrb · GuideMedallion (drag-safe corner dock) · PassportView (live DOM version) · StampSlam · CountdownNumerals · NicknameInput · ProgressShimmer (authored waits) · DebugBadge.

**Popups:** none. Everything is diegetic overlays (EP-1). The only modal-like element is ERROR_STAFF.

---

## 8. Animation Bible

Global: curve `cubic-bezier(.2,.8,.2,1)`; durations 240/600/1200 ms (micro/element/scene); everything GPU-composited (`transform`/`opacity` only — no layout-thrashing properties in loops).

| Category | Spec |
|---|---|
| **Materialize (in)** | scale .86→1 + blur 8→0 + opacity 0→1, 600 ms; paired 12-particle inward spiral from origin point (EP-5) |
| **Dissolve (out)** | opacity→0 + drift up 16 px + particle scatter, 400 ms |
| **Idle float** | translateY sine ±6 px, 3.2 s period, phase-randomized per element (EP-6) |
| **Bubble pulse (CTA)** | scale 1↔1.045 + glow opacity ↔, 2.4 s |
| **Orb expand** | Ø→70 vw, spring (stiffness .5), others scale .6 + desat; 500 ms |
| **Selection burst** | orb → 24 particles along bezier paths → converge on passport field, 900 ms |
| **Stamp slam** | stamp scale 3→1 rotate -12°, 180 ms ease-in; on impact: 4 px screen shake 120 ms + 40-particle radial burst + SFX hit |
| **Flash capture** | white overlay opacity 0→.9→0, 300 ms |
| **Countdown numeral** | forms from 60 particles (600 ms), holds, shatters on next |
| **Fold transition (unfold)** | light sweep along hinge axis 300 ms → UI split-slide 400 ms → wide world already in motion (parallax layers at 0.8×/1×/1.2×) |
| **Passport materialize** | vortex (120 particles, spiral shader on fx canvas) 2 s → form + rotate → fly-to-camera scale .2→1.15 w/ 2-frame motion blur → unfold 3D rotateY 90→0 |
| **Passport contents** | each item stamps in at 160 ms intervals (photo drop + settle bounce, stamps slam, QR fades) |
| **Guide framing change** | FLIP transform between Portal/Stage/Medallion, 600 ms |
| **Speech "gesture" proxy** | (G1) while guide speaks: his portal frame glows brighter + ambient particles drift toward him; on emphatic lines (config-flagged) a soft radial pulse emits from the portal — reads as body language without body control |
| **Loading (authored)** | ProgressShimmer: light band sweeping a hairline, 1.6 s loop + guide line |
| **Success generic** | gold particle fountain 1.2 s |
| **Failure generic** | scene desaturates 20% 400 ms + gentle head-shake wobble on the active element (±3°) — never red flashes |
| **Reset** | everything dissolves upward into stars, 2 s |

Performance budget: ≤ 350 live particles; FXEngine pools sprites; all loops pause when `document.hidden`.

---

## 9. Conversation Design

**Persona:** 모험 가이드 (male, per new avatar). Bold, warm, playful — an explorer who's seen everything and is still excited. Never honorific-stiff (해요체 with occasional 반말 hype spikes — A/B with brand team), never sarcastic at the user's expense.

**Tone arc (energy 1–10):** Idle 4 (inviting hum) → Greeting 6 → Mission accept 7 → Camera 6 (focused, coaching) → Celebration 1: **9** → Destination 7 (curatorial) → Departure: **9** → Cinematic 8 (awed) → Camera 2: 7 → Celebration 2: **10** → Passport gen 8 (ceremonial) → Farewell 6 (warm).

**Rules:**
- ≤ 2 sentences per beat (G10); front-load the emotional word (`"됐다!!"`, `"우와아—!"`).
- **Silence is used** during: camera aiming (after 1 coaching line — let them focus), cinematic mid-section (music leads), passport fly-in apex (1.2 s hold before the reveal line lands).
- Every destination gets 4 bespoke lines (teaser, selection hype, arrival, farewell reference) — table in `lines.ko.ts`, 5×4 + core ≈ 60 lines total, all TTS-tested.
- Delays: any wait > 2.5 s triggers the scene's authored wait line (one per scene, non-repeating).
- Mistakes: retake requested → `"당연하지! 완벽한 여권 사진을 위해서라면."` Camera denied → EP-8. User idle mid-mission → one re-invite (`"여행자, 아직 갈 길이 남았어!"`) before EP-9 farewell.
- **All lines via SpeechDirector** with `interrupt: 'queue' | 'replace'` policy per line class (celebrations replace; ambient lines queue and are droppable).

---

## 10. Technical Risks

| ID | Risk | Sev | Mitigation |
|---|---|---|---|
| R1 | 3D destination bubbles → jank/thermal on device w/ live WebRTC | 🔴 | Ruled out for orbs (§S6); video loops. Single-context 3D only as M6 stretch, behind config flag, with FPS auto-fallback |
| R2 | `speak()` drops on rapid sequencing (G3) | 🔴 | SpeechDirector is the sole caller; state-machine tested against RESPONSE_* signal traces |
| R3 | Choreography desync (anim keyed to TTS duration) | 🟠 | Duration estimator + correction on RESPONSE_ENDED; animations designed with elastic hold points, never hard-cut on estimate |
| R4 | Fold detection ambiguity on custom device (open Q#1) | 🔴 | Config thresholds + hysteresis (300 ms debounce); on-device calibration screen in dev build; Device Posture API when available |
| R5 | Session death mid-mission (network) | 🟠 | Silent reconnect ≤ 2×; scene freeze choreography; in-character recovery line; telemetry counter |
| R6 | Memory creep over a full event day (photos, canvases, particles) | 🟠 | RAM-only photos wiped on reset; FX pooling; scene exit audits; 4-hour soak test in M5 with heap snapshots |
| R7 | Camera HTTPS on device (G7) | 🔴 | mkcert HTTPS server in M1; origin whitelisted (G8) immediately after |
| R8 | 4K asset weight + decode load (5 loops + 5×4K cinematics + 4K passport render) vs first-load & device thermal | 🟠 | Tiered AssetLoader: boot = idle-set only; cinematics lazy-load during S2–S6 dwell; **4K decode probe picks the highest sustainable tier (4K→1440p→1080p) per device**; orbs are 720p (not 4K); passport 4K render is a one-shot offscreen composite (not sustained), so it's safe even when live playback isn't; H.265/AV1 encodes |
| R9 | Race: posture change during scene transition | 🟠 | FSM serializes: posture events queue behind in-flight transition; transitions ≤ 1.4 s max |
| R10 | Avatar cannot emote (G1) — experience reads flat if team assumes it can | 🔴 | This blueprint designs all emotion into environment+speech; asset request filed for emotive variants (docs/asset-requests.md); demo-review checkpoint in M3 |
| R11 | Offline/venue Wi-Fi flakiness | 🟠 | All assets local after first load (service-worker cache); only SDK traffic needs network; R5 handles drops; staff badge on repeated failure |
| R12 | TTS latency spikes → dead air | 🟡 | Ambient audio bed always present; ProgressShimmer on >2.5 s; lines pre-warmed where SDK allows |
| R13 | Domain/quota surprises on event day (G8, TIME_EXHAUSTED) | 🟠 | origins.md checklist; quota confirmed with Klleon ops pre-event; ERROR_STAFF screen readable at a glance |

---

## 11. Future Expansion — Adventure Platform

The engine is vertical-agnostic; an **Adventure Pack** is:

```jsonc
// adventures/<name>/adventure.json
{
  "id": "galaxy-passport",
  "character": { "avatarId": "…", "adlp": true, "persona": "explorer" },
  "modes": { "fold": {"ratio": [0.66, 1.2]}, "wide": {"ratio": [1.2, 3]} },
  "flow": ["greeting","passportIntro","camera1","celebrate1","destination",
            "departure","unfoldWait","cinematic","selfie2Invite","camera2",
            "celebrate2","passportGen","reward"],
  "choices": [ { "id":"paris", "loop":"loops/paris.mp4",
                 "cinematic":"cin/paris.mp4", "filter":"lut/paris.cube",
                 "frame":"art/paris-frame.png", "lines": {…} }, … ],
  "collectible": { "template":"passport", "fields": ["photo1","photo2",
                    "nickname","serial","date","qr","staffCheck"] },
  "inactivity": { "warnAfter": 30, "resetAfter": 45 }
}
```

Because scenes are registered factories and all copy/assets/thresholds live in the pack: **Museum docent** (choices = exhibits, collectible = stamped tour card), **Retail stylist** (choices = looks, collectible = lookbook), **Education** (choices = eras, collectible = certificate), **Theme park / automotive showroom / enterprise onboarding** — all reuse 100% of the managers and ~80% of scenes. The only engine additions ever needed are new scene types (e.g., quiz), which register alongside existing ones.

---

## 12. Development Roadmap

Each milestone ends in a runnable build ("demo Friday" cadence).

| M | Deliverable (working build) | Contents |
|---|---|---|
| **M0** ½ wk | Repo + skeleton | Vite/TS scaffold, EventBus, FSM, ConfigService; V1 behaviors ported behind scenes API; HTTPS dev server (R7); origins registered (G8) |
| **M1** 1 wk | **Core loop, ugly** | SDKBridge + SpeechDirector (G3/G4 solved & signal-trace tested); FoldManager w/ calibration screen; full FSM navigable end-to-end with placeholder visuals + real speech |
| **M2** 1 wk | **Camera + Passport spine** | CameraScene (both configs), capture pipeline w/ filters, PassportStore/Renderer/View at **4K export** (§0-Q), nickname input; **passport image host (§5a) + QR self-save**; device HTTPS camera verified at max resolution |
| **M3** 1.5 wk | **Emotion pass 1** | FXEngine (particles, stamps, shake), GlassBubble/orb components, materialize/dissolve everywhere, S3/S5/S12 celebrations, tone-arc script v1 recorded through TTS · **checkpoint: G1 review — does emotion land without avatar gestures?** |
| **M4** 1 wk | **Wide Mode + cinematics** | Fold transition choreography, Wide layouts, destination loops + cinematic videos (placeholder art ok), S6 two-tap orbs, S9 takeoff |
| **M5** 1 wk | **Hardening** | Inactivity system, full edge matrix, reconnect drills, 4-hr soak (R6), asset tiering, perf budget enforcement (60 fps on device) |
| **M6** 1 wk | **Polish + stretch** | Final art/SFX/score, passport collectible art, speech A/B, optional: expanded-orb 3D (R1 flag), pilot-avatar swap if content team delivered |
| **M7** ½ wk | **Event readiness** | Staff error screens, ops runbook, quota confirmation, kiosk auto-boot, analytics counters, dry-run at venue origin |

Critical path: M1's SpeechDirector and FoldManager unblock everything; M2's HTTPS unblocks device testing; art can parallelize from M3.

---

## 13. Critical Design Review — pushback on the brief

1. **"3D miniature worlds in every bubble" — rejected as specified (R1).** Five live 3D scenes + WebRTC + particles on a fold device is a thermal/jank trap that would sabotage the flagship's *feel* to gain fidelity nobody perceives at 100 px. Video loops deliver the identical emotion at 5% of the cost. Compromise preserved: optional single 3D context on the *expanded* orb only, M6, behind a kill-switch flag.
2. **"He puts on sunglasses / jumps / changes outfits" — impossible with current SDK (G1) and dangerous to promise.** The strongest version of this demo is honest about where the magic lives: environment choreography + writing. I've filed the emotive-avatar asset request; the architecture accepts it the day it exists. Do not storyboard executive demos around gestures we cannot render.
3. **Unfold = 16:9 contradicts the earlier 9:16 spec (open Q#1).** This is a hardware fact, not a preference — get panel dimensions before Wide Mode art is commissioned, or M4 gets rebuilt.
4. **V1's "flight attendant politeness" wasn't the only flatness — V1 had no object continuity.** The V2 passport-as-persistent-object (materializes in S3, collects stamps at each beat, becomes the reward) is the single biggest storytelling upgrade, beyond anything in the feedback list.
5. **The original flow asked for approval theater ("Digital Human approves selfie").** Approval implies the user can fail a selfie — wrong emotion. V2 reframes to *celebration* (nothing to approve; you're already a traveler). Retake remains available but is user-initiated pride, not system judgment.
6. **QR + nickname + serial were mentioned only decoratively in feedback** — they're the actual retention/ops mechanics (staff verification, share-ability, uniqueness). V2 specifies them fully (S14, open Q#4/5).
7. **Inactivity "politely explain fold-first restart" (feedback) is kept but bounded** — one explanation, then farewell. An unattended kiosk lecturing an empty room is worse than resetting.

## Top 20 Highest-Impact Improvements over V1/original concept

| # | Improvement | Why it materially matters |
|---|---|---|
| 1 | **SpeechDirector queue (G3)** | Eliminates the #1 demo-killer: silently dropped lines during rapid sequences |
| 2 | **Persistent passport object across the whole mission** | Converts 15 disconnected steps into one story with a physical through-line |
| 3 | **One never-destroyed avatar session, reframed Portal/Stage/Medallion** | "He's alive in the device" — the core SDK claim, made visible |
| 4 | **Environment-based emotion system (G1-honest)** | Celebration that actually ships vs. gestures that can't |
| 5 | **Video-loop destination orbs (not 3D)** | Same wonder, 60 fps, no thermal throttling mid-demo |
| 6 | **Fold transition < 500 ms with pre-mounted Wide layout** | The unfold is Peak P1; lag here kills the entire premise |
| 7 | **FSM with scene contracts (enter/exit/onPosture)** | Edge cases (early unfold, mid-mission fold) become routine code, not bugs |
| 8 | **Two-tap orb interaction (preview → commit)** | Browsing destinations becomes play; selection becomes intentional |
| 9 | **Passport generation as speech-synced 8 s ceremony** | The screenshot moment; instructions delivered inside the spectacle (feedback, executed with sync engineering) |
| 10 | **Authored waits (EP-7) — no spinners** | Waiting becomes character time; perceived performance ≫ actual |
| 11 | **Tone arc 4→10 with beat-level energy spec** | Excitement that *builds* instead of uniform cheerfulness |
| 12 | **Collectible-grade passport (nickname, serial, stamps, QR, staff corner)** | The take-home artifact = organic social sharing + ops verification |
| 13 | **Adventure Pack config architecture** | Turns a one-off demo into the SDK product story Klleon can sell |
| 14 | **Inactivity as narrative landing (EP-9)** | Kiosk resilience all day without ever looking broken |
| 15 | **In-character failure states (EP-8) + silent reconnect** | Network hiccups become "turbulence", not error dialogs in front of executives |
| 16 | **Mode-native layouts via tokens (EP-11)** | Fold and Wide each look designed, not responsive-stretched |
| 17 | **RAM-only photos + wipe on reset** | Privacy defensible at an enterprise/Samsung review without a legal detour |
| 18 | **Tiered asset loading during dwell time** | Heavy cinematics without a heavy boot |
| 19 | **Dev calibration screen + config thresholds for fold detection (R4)** | Survives the custom hardware's real dimensions, whatever they turn out to be |
| 20 | **M-milestone plan with G1/G2 checkpoint gates** | The two existential dependencies (emotive avatar, chroma-key) get decided on schedule instead of discovered at the end |

---

*End of Blueprint. Changes require a version bump and a note in the changelog below.*

**Changelog**
- 2.0 (2026-07-07): Initial V2 blueprint from V1 prototype learnings + design feedback.
- 2.1 (2026-07-07): Product owner resolved all open questions — QR = self-save of passport image (§5a host added), staff verification = visual proof only (no scanning), 4K output requirement added (§0-Q, EP-15/17), unfold = 16:9 config-driven. Content-team asks demoted to non-blocking upgrades.
- 2.2 (2026-07-07): Polish pass under full execution authority. (a) Passport interior wrapped in clipped `.pp-page` — stamps/photos can never bleed past the card edge (defect seen in field screenshot); cover gets gold emblem ring + inner frame + leather sheen. (b) **Captures stay clean**: no emoji stickers baked into photos — filter/tint only; world stamps are passport decorations, killing the triple-emblem clutter. (c) Final card: duplicate serial removed, pfp crop biased to face (`center 22%`), world stamp repositioned clear of QR; same fix in 4K export. (d) **Sfx module**: synthesized chime/thunk/whoosh/sparkle + haptic vibration on stamp slams and shutter — zero asset files, autoplay-safe. (e) Passport now carries issue serial/date from materialization (recorded-object continuity).
