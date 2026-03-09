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

### Logic การคำนวณ Role (สายอาชีพหลัก)

1. **ดึงและจัดกลุ่ม Badge**
   - ดึง HTML โปรไฟล์ Google Skills → แยกเฉพาะบรรทัดที่ขึ้นต้นด้วย `Earned ...` และใช้บรรทัดก่อนหน้าเป็นชื่อ badge
   - หาปีจากข้อความวันที่ (รูปแบบ `20XX`) แล้วเก็บเป็น `{ name, year }`
   - ลบ badge ซ้ำ (ใช้ชื่อ badge เป็น key) เหลือเฉพาะ unique badges

2. **จัดหมวดหมู่ (categoriesMap)**
   - แต่ละ badge นำ **ชื่อ badge** ไปเทียบกับ **keywords** ของแต่ละหมวดใน `categoriesMap` (เทียบแบบรวมข้อความ lowercase)
   - หมวดแรกที่ **มี keyword ใด keyword หนึ่งอยู่ในชื่อ badge** จะถูกนับใน `results[category]` และหยุดเทียบหมวดถัดไป (first match wins)
   - ถ้าไม่ match หมวดใดเลย และชื่อ badge ยาวกว่า 5 ตัวอักษร → นับเป็น **Other Skills**

3. **หาสายอาชีพหลัก (dominantCategory)**
   - ใน `results` เลือกหมวดที่มี **จำนวน badge สูงสุด** เป็น dominant category
   - **ไม่นำ "Other Skills" มาใช้เป็น dominant** (ใช้เฉพาะเมื่อทุกหมวดเป็น 0)
   - ถ้าทุกหมวดเป็น 0 → ใช้ `"Other Skills"` เป็น dominant

4. **แสดงผล Role และ Mascot**
   - **ข้อความสายอาชีพ:** `roleNamesMap[dominantCategory]` (เช่น "Data Engineer", "ML Engineer")
   - **Mascot:** ฟังก์ชัน `getMascotSvg(dominantCategory)` เลือก SVG ตาม dominant category

**หมวดและ Role ที่รองรับ (ในโค้ดปัจจุบัน):**

| หมวด (category)        | แสดงเป็น (role)        |
|------------------------|------------------------|
| Generative AI & LLM    | AI Prompt Engineer     |
| Machine Learning & AI  | ML Engineer             |
| Data Engineering       | Data Engineer           |
| Data Analytics         | Data Analyst            |
| Cloud Infra            | Cloud / DevOps Engineer |
| Security               | Security Engineer       |
| App Dev & Tools        | Software Developer      |
| Other Skills           | Tech Generalist         |
| (ไม่มี badge)          | Future Tech Star        |

แก้ไข keywords ได้ที่ `categoriesMap` และชื่อที่แสดงได้ที่ `roleNamesMap` ใน `index.html`

### การทำงานของ server

- `server.js` จะ:
  - อ่าน `index.html`
  - แทนที่ placeholder `__GEMINI_API_KEY__` ด้วยค่าจาก `process.env.GEMINI_API_KEY`
  - เสิร์ฟหน้าเว็บที่ `/`
  - ถ้ามี query string แปลกๆ (เช่น `?fbclid=...`) จะ redirect ไป URL เดิมแบบไม่มี query เพื่อให้ลิงก์สะอาด

### หมายเหตุเพิ่มเติม

- หากเปลี่ยน logic การจัดหมวดหมู่ทักษะ / สายอาชีพ ให้ดูในส่วน `categoriesMap`, `roleNamesMap` และ `getMascotSvg` ภายใน `index.html`
- หากปรับ region / service name / project ชุดใหม่ ให้แก้ที่ `deployment/params.sh` เป็นหลัก แล้วจึงรัน `./deployment/deploy.sh`

