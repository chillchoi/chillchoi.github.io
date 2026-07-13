# Galaxy Passport — 배포 가이드

이 앱은 **서버가 필요 없는 정적(static) 웹앱**입니다. 뒤에서 돌아가는 서버 로직이
없으므로, `dist/` 폴더만 정적 호스팅에 올리면 바로 동작합니다.
(외부 통신은 클레온 SDK CDN 하나뿐입니다.)

## 1. 빌드 산출물 만들기

Node만 있으면 됩니다 (npm 설치 불필요):

```bash
node build.mjs
```

→ `dist/` 폴더가 생성됩니다. **이 폴더가 배포 대상입니다.**

## 2. 로컬에서 미리보기

```bash
node serve.mjs          # http://localhost:8080 에서 dist/ 확인
```

## 3. 배포 (아래 중 아무거나)

- **Netlify / Vercel**: `dist/` 폴더를 드래그&드롭 (또는 output 디렉토리를 `dist`로 지정)
- **AWS S3 + CloudFront**: `dist/`의 파일을 버킷에 업로드, 정적 웹 호스팅 활성화
- **GitHub Pages**: `dist/` 내용을 배포 브랜치에 푸시

> ⚠️ **배포 후 필수**: 배포된 도메인(예: `https://your-app.com`)을 클레온 SDK
> **허용 도메인**에 등록해야 아바타가 연결됩니다. 승혁님/담당자에게 주소를 전달하세요.
> (미등록 시 "허용되지 않은 주소" 에러가 납니다.)
>
> 📸 **카메라**: 셀피 단계는 `https` 또는 `localhost`에서만 동작합니다.
> 정적 호스팅은 대부분 https라 문제없지만, http로 열면 카메라가 막힙니다.

## (선택) Vite로 최적화 빌드

더 작은 용량의 최적화 빌드를 원하면, npm이 설치된 PC에서:

```bash
npm install
npm run build:vite     # 최적화된 dist/ 생성
```

## 파일 구조

| 파일 | 설명 |
|---|---|
| `index.html` | 본 앱 (자체 완결형, 그대로 배포 가능) |
| `v1-prototype.html` | 초기 프로토타입 (참고용) |
| `build.mjs` | 정적 빌드 스크립트 (node만 필요) |
| `serve.mjs` | 로컬 미리보기 서버 (node만 필요) |
| `vite.config.js` / `package.json` | 선택적 Vite 파이프라인 |
| `BLUEPRINT.md` | 전체 설계 명세서 |
| `dist/` | **배포 산출물** |

## 참고: QR 이미지 저장 기능

여권의 QR로 이미지를 저장하는 기능은, 나중에 "생성된 여권 이미지를 잠깐
올려두는 작은 업로드 주소" 하나만 붙이면 완성됩니다 (BLUEPRINT §5a).
그 전까지는 **"💾 이미지로 저장"** 버튼으로 4K 이미지가 바로 다운로드되며,
이것만으로도 이벤트 현장에서 직원에게 보여주는 용도는 충분합니다.
