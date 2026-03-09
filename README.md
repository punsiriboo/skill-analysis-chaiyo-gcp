## Skill Analysis Chaiyo GCP (Google Skills Analyzer)

เว็บแอปสำหรับวิเคราะห์โปรไฟล์ Badge/Skill ของ Google (เช่น Google Cloud Skills Boost) แล้วสรุปเป็นสายอาชีพหลัก พร้อมกราฟสวยๆ และคำแนะนำจาก Gemini

### โครงสร้างโปรเจกต์หลัก

- `index.html` – หน้าเว็บหลัก (Tailwind + Chart.js + JavaScript ฝั่ง client)
- `server.js` – Node.js HTTP server เล็กๆ สำหรับรันบน Cloud Run และ inject ค่า `GEMINI_API_KEY` เข้าไปใน `index.html`
- `Dockerfile` – ใช้ build image สำหรับ Cloud Run
- `deployment/params.sh` – ค่าพื้นฐานของการ deploy (ACCOUNT, PROJECT_ID, LOCATION_ID)
- `deployment/deploy.sh` – สคริปต์ deploy ไป Cloud Run
- `env.yaml.example` – ตัวอย่างไฟล์ environment variables (ให้คัดลอกไปเป็น `env.yaml`)

### การเตรียมค่า API Key (Gemini)

1. คัดลอกไฟล์ตัวอย่าง:
   ```bash
   cp env.yaml.example env.yaml
   ```
2. แก้ไฟล์ `env.yaml` ใส่ค่า:
   ```yaml
   GEMINI_API_KEY: "YOUR_REAL_GEMINI_API_KEY"
   ```
   หรือจะชี้ไปที่ Secret Manager ก็ได้ เช่น:
   ```yaml
   GEMINI_API_KEY: "projects/YOUR_PROJECT_ID/secrets/gemini-api-key/versions/latest"
   ```

**หมายเหตุ:** `env.yaml` ถูก ignore ไม่ให้ commit ขึ้น git แล้ว

### การตั้งค่าก่อน deploy

1. แก้ `deployment/params.sh`
   ```bash
   ACCOUNT=your.email@gmail.com
   PROJECT_ID=your-gcp-project-id
   LOCATION_ID=asia-southeast3   # หรือ region ที่ต้องการ
   ```
2. Login และให้สิทธิ์ account นี้ใน GCP ให้สามารถใช้ Cloud Run ได้

### Deploy ไปที่ Cloud Run

รันจาก root ของโปรเจกต์:

```bash
./deployment/deploy.sh
```

สคริปต์จะ:

- ตั้ง `gcloud config set account` จาก `ACCOUNT` ใน `params.sh`
- ใช้ `PROJECT_ID` / `LOCATION_ID` จาก `params.sh` (แต่ override ได้ด้วย env `GCP_PROJECT_ID`, `GCP_REGION`)
- deploy ด้วย `gcloud run deploy` โดยอ่านค่า env จาก `env.yaml`

### การทำงานของ server

- `server.js` จะ:
  - อ่าน `index.html`
  - แทนที่ placeholder `__GEMINI_API_KEY__` ด้วยค่าจาก `process.env.GEMINI_API_KEY`
  - เสิร์ฟหน้าเว็บที่ `/`
  - ถ้ามี query string แปลกๆ (เช่น `?fbclid=...`) จะ redirect ไป URL เดิมแบบไม่มี query เพื่อให้ลิงก์สะอาด

### หมายเหตุเพิ่มเติม

- หากเปลี่ยน logic การจัดหมวดหมู่ทักษะ / สายอาชีพ ให้ดูในส่วน `categoriesMap`, `roleNamesMap` และ `getMascotSvg` ภายใน `index.html`
- หากปรับ region / service name / project ชุดใหม่ ให้แก้ที่ `deployment/params.sh` เป็นหลัก แล้วจึงรัน `./deployment/deploy.sh`

