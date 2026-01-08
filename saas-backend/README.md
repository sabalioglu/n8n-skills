# 🎬 UGC SaaS Platform - Backend API

**AI-Powered User-Generated Content Video Generator**

A complete multi-tenant SaaS backend built on n8n workflows, Supabase, and AI services. Generates authentic UGC-style video ads from product images with customizable characters, audiences, and styles.

**Conceived by Romuald Członkowski** - [www.aiadvisors.pl/en](https://www.aiadvisors.pl/en)

---

## 📋 Table of Contents

1. [Features](#features)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Quick Start](#quick-start)
5. [Database Setup](#database-setup)
6. [Workflow Setup](#workflow-setup)
7. [Configuration](#configuration)
8. [API Documentation](#api-documentation)
9. [Frontend Integration](#frontend-integration)
10. [Testing](#testing)
11. [Deployment](#deployment)
12. [Troubleshooting](#troubleshooting)

---

## ✨ Features

### 🔐 **Multi-Tenant SaaS**
- Supabase JWT authentication
- Row-level security (RLS)
- Per-user credit tracking
- Subscription tiers (Free/Pro/Enterprise)

### 🎥 **AI-Powered Video Generation**
- **9 UGC Styles:** Holding product, unboxing, mirror selfie, ASMR, podcast, etc.
- **5 Target Audiences:** Gen Z, Millennials, Gen X, All Ages, Business/Professional
- **Adaptive Characters:** AI selects age, gender, and style based on audience
- **Product Analysis:** AI analyzes product category and features
- **Smart Grid Generation:** Creates 2x2 product views with optimal angles
- **Scene Progression:** Problem → Solution storytelling

### 💳 **Credits & Billing**
- Credit-based pricing (1 video = 10 credits)
- Automatic credit deduction
- Refunds on job failures
- Subscription limits enforcement

### 📊 **Job Management**
- Real-time status tracking
- Progress percentage (0-100%)
- Detailed step descriptions
- Job history per user

### 🔔 **Optional Features**
- Webhook notifications on completion
- API access for enterprise
- Priority processing for paid tiers

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Frontend (Bolt/Genspark)                 │
│  (React/Next.js with Supabase Auth)                         │
└────────────┬────────────────────────────────────────────────┘
             │ JWT Token
             ▼
┌─────────────────────────────────────────────────────────────┐
│                       n8n Workflows                          │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  1. UGC SaaS API (Generate Video)                   │    │
│  │     - JWT Validation                                │    │
│  │     - Credit Checking                               │    │
│  │     - Job Creation                                  │    │
│  │     - AI Processing                                 │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  2. Job Status API (Check Progress)                 │    │
│  │     - JWT Validation                                │    │
│  │     - Status Retrieval                              │    │
│  └─────────────────────────────────────────────────────┘    │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│                      Supabase Backend                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Auth (JWT)   │  │ PostgreSQL   │  │ Storage      │      │
│  │              │  │ - Users      │  │ - Videos     │      │
│  │              │  │ - Jobs       │  │ - Thumbnails │      │
│  │              │  │ - Credits    │  │              │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│                       AI Services                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Kie.ai       │  │ Gemini AI    │  │ FFmpeg       │      │
│  │ - Nano-Banana│  │ - Analysis   │  │ - Assembly   │      │
│  │ - Seedream   │  │ - Prompts    │  │              │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Prerequisites

### Required Services

1. **n8n** (self-hosted or cloud)
   - Version: 1.0.0+
   - Node.js 18+

2. **Supabase** (cloud or self-hosted)
   - PostgreSQL database
   - Storage bucket
   - Auth enabled

3. **Kie.ai Account**
   - API key for image generation
   - Credits for Nano-Banana and Seedream models

4. **Google Gemini API**
   - API key for AI analysis

### Optional Services

5. **Stripe** (for payments)
6. **SendGrid** (for email notifications)
7. **Sentry** (for error tracking)

---

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/your-org/ugc-saas-backend.git
cd ugc-saas-backend
```

### 2. Set Up Environment Variables

```bash
cp .env.example .env
# Edit .env with your API keys
```

### 3. Set Up Supabase Database

```bash
# Run migration in Supabase SQL Editor
cat supabase/migrations/001_initial_schema.sql
# Copy contents and run in Supabase
```

### 4. Import n8n Workflows

1. Open n8n dashboard
2. Go to **Workflows** → **Import from File**
3. Import:
   - `workflows/ugc-saas-api.json`
   - `workflows/job-status-api.json`

### 5. Configure Workflows

1. Open each workflow
2. Update credentials:
   - Supabase HTTP Request nodes
   - Kie.ai HTTP Request nodes
   - Gemini AI nodes

### 6. Test

```bash
# Get JWT token from Supabase
curl -X POST https://your-project.supabase.co/auth/v1/token \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'

# Test video generation
curl -X POST https://your-n8n.com/webhook/v1/generate-ugc \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "productImage=@product.jpg" \
  -F "productName=Test Product"
```

---

## 🗄️ Database Setup

### Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Create new project
3. Save your project URL and API keys

### Step 2: Run Migration

Copy and run `supabase/migrations/001_initial_schema.sql` in the SQL Editor.

This creates:
- ✅ `user_profiles` table
- ✅ `subscription_plans` table (with default plans)
- ✅ `video_jobs` table
- ✅ `credit_transactions` table
- ✅ `usage_logs` table
- ✅ Helper functions (`check_user_credits`, `deduct_credits`, `refund_credits`)
- ✅ Row-level security (RLS) policies
- ✅ Auto-create profile trigger

### Step 3: Create Storage Bucket

1. Go to **Storage** in Supabase
2. Create bucket named `user-videos`
3. Make it **public** (or configure signed URLs)
4. Set up CORS if needed

### Step 4: Test Database Functions

```sql
-- Check if functions work
SELECT public.check_user_credits(
  'your-user-id-uuid',
  10
);

-- View subscription plans
SELECT * FROM public.subscription_plans;
```

---

## ⚙️ Workflow Setup

### Workflow 1: UGC SaaS API (Generate Video)

**Webhook URL:** `/webhook/v1/generate-ugc`

**What it does:**
1. Validates JWT token
2. Checks user credits (10 credits required)
3. Validates input (product image, name, etc.)
4. Creates job record in database
5. Deducts credits
6. Returns immediate response with `jobId`
7. Processes video asynchronously:
   - Uploads product image
   - AI analyzes product → generates 2x2 grid
   - Selects character based on audience
   - Generates scenes (problem + solution)
   - Assembles video with FFmpeg
   - Uploads to Supabase Storage
   - Updates job status to `completed`

**Environment Variables Needed:**
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `KIE_API_URL`
- `KIE_API_KEY`
- `API_BASE_URL`

### Workflow 2: Job Status API (Check Progress)

**Webhook URL:** `/webhook/v1/job-status/:jobId`

**What it does:**
1. Validates JWT token
2. Retrieves job from database
3. Ensures user owns the job (security)
4. Returns detailed status:
   - Progress percentage
   - Current step
   - Video URL (if completed)
   - Error message (if failed)

---

## 🔧 Configuration

### n8n Environment Variables

In n8n, go to **Settings** → **Environments** and add:

```bash
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJxxx...
SUPABASE_SERVICE_ROLE_KEY=eyJxxx...
KIE_API_URL=https://api.kie.ai
KIE_API_KEY=your-key
GEMINI_API_KEY=your-key
API_BASE_URL=https://your-n8n.com/webhook
```

### Webhook URLs

After importing workflows, activate them and copy the webhook URLs:

1. **Generate UGC:** `https://your-n8n.com/webhook/v1/generate-ugc`
2. **Job Status:** `https://your-n8n.com/webhook/v1/job-status/:jobId`

Share these URLs with your frontend team.

---

## 📖 API Documentation

See **[docs/API_DOCUMENTATION.md](docs/API_DOCUMENTATION.md)** for complete API reference.

### Quick Examples

#### Generate Video (cURL)

```bash
curl -X POST https://your-n8n.com/webhook/v1/generate-ugc \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "productImage=@product.jpg" \
  -F "productName=Premium Headphones" \
  -F "productDescription=Wireless noise-cancelling headphones" \
  -F "ugcType=Holding Product - Natural pose" \
  -F "targetAudience=Gen Z (18-24)" \
  -F "duration=16s Problem + Solution" \
  -F "platform=TikTok/Reels (9:16)"
```

#### Check Status (cURL)

```bash
curl -X GET https://your-n8n.com/webhook/v1/job-status/ugc_123456 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## 🎨 Frontend Integration

### React Example

```jsx
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
const API_BASE = 'https://your-n8n.com/webhook'

async function generateVideo(productImage, productName) {
  // Get user token
  const { data: { session } } = await supabase.auth.getSession()
  const token = session.access_token

  // Create form data
  const formData = new FormData()
  formData.append('productImage', productImage)
  formData.append('productName', productName)

  // Call API
  const response = await fetch(`${API_BASE}/v1/generate-ugc`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}` },
    body: formData
  })

  const result = await response.json()

  if (!result.success) {
    throw new Error(result.message)
  }

  return result.jobId
}

async function checkStatus(jobId) {
  const { data: { session } } = await supabase.auth.getSession()

  const response = await fetch(`${API_BASE}/v1/job-status/${jobId}`, {
    headers: { 'Authorization': `Bearer ${session.access_token}` }
  })

  return await response.json()
}
```

See **[docs/API_DOCUMENTATION.md](docs/API_DOCUMENTATION.md)** for more examples.

---

## 🧪 Testing

### Manual Testing

1. **Create Test User**
   ```bash
   # In Supabase dashboard
   # Auth → Add User
   # Email: test@example.com
   ```

2. **Test Credit System**
   ```sql
   -- Check user credits
   SELECT * FROM user_profiles WHERE email = 'test@example.com';

   -- Test credit deduction
   SELECT public.deduct_credits(
     'user-uuid',
     10,
     null,
     'Test deduction'
   );
   ```

3. **Test Video Generation**
   - Use Postman or curl with test product image
   - Monitor n8n workflow execution
   - Check database for job status updates

### Automated Testing

Create test cases for:
- ✅ JWT validation (valid/invalid/expired tokens)
- ✅ Credit checking (sufficient/insufficient)
- ✅ Input validation (missing image, invalid params)
- ✅ Multi-tenancy (user can't access other users' jobs)
- ✅ Credit refunds (on job failure)

---

## 🚀 Deployment

### Production Checklist

#### Security
- [ ] Use HTTPS for all endpoints
- [ ] Rotate API keys regularly
- [ ] Enable Supabase RLS on all tables
- [ ] Set up CORS properly
- [ ] Use environment variables (never hardcode secrets)
- [ ] Enable rate limiting

#### Performance
- [ ] Set up n8n with multiple workers
- [ ] Enable n8n queue mode for async processing
- [ ] Configure Supabase connection pooling
- [ ] Set up CDN for video delivery
- [ ] Optimize FFmpeg settings

#### Monitoring
- [ ] Set up error tracking (Sentry)
- [ ] Configure uptime monitoring
- [ ] Set up log aggregation
- [ ] Create alerts for failed jobs
- [ ] Monitor credit balance trends

#### Scaling
- [ ] Use n8n cloud or managed instance
- [ ] Scale Supabase plan as needed
- [ ] Implement job queue (Bull/BullMQ)
- [ ] Consider separating video processing to workers
- [ ] Set up horizontal scaling for n8n

---

## 🐛 Troubleshooting

### "UNAUTHORIZED: Missing authorization token"

**Solution:** Ensure frontend is sending JWT token in Authorization header:
```javascript
headers: { 'Authorization': `Bearer ${token}` }
```

### "INSUFFICIENT_CREDITS"

**Solution:**
1. Check user's credit balance in Supabase
2. Add credits manually:
   ```sql
   UPDATE user_profiles
   SET credits_balance = credits_balance + 10
   WHERE email = 'user@example.com';
   ```

### "JOB_NOT_FOUND"

**Causes:**
- User trying to access another user's job (RLS blocking)
- Invalid job ID
- Job not yet created in database

**Solution:** Check `video_jobs` table and verify `user_id` matches

### Video generation stuck at "scene_generation"

**Causes:**
- Kie.ai API timeout
- Network issues
- Invalid prompts

**Solution:**
1. Check n8n workflow execution logs
2. Verify Kie.ai API key is valid
3. Check Kie.ai account credits
4. Review error in `video_jobs.error_message`

### Credits not refunded on failure

**Check:**
```sql
SELECT * FROM credit_transactions WHERE job_id = 'your-job-uuid';
```

If no refund record, manually refund:
```sql
SELECT public.refund_credits('user-uuid', 10, 'job-uuid', 'Manual refund');
```

---

## 📚 Additional Resources

- **n8n Documentation:** https://docs.n8n.io
- **Supabase Documentation:** https://supabase.com/docs
- **Kie.ai API Docs:** https://docs.kie.ai
- **Google Gemini API:** https://ai.google.dev/docs

---

## 🤝 Contributing

This is a private SaaS backend. For questions or custom development, contact:

**Romuald Członkowski**
- Website: [www.aiadvisors.pl/en](https://www.aiadvisors.pl/en)
- Email: contact@aiadvisors.pl

---

## 📄 License

Proprietary - All rights reserved

**Conceived by Romuald Członkowski** - [www.aiadvisors.pl/en](https://www.aiadvisors.pl/en)

---

## 🎯 Next Steps

1. ✅ Set up Supabase database
2. ✅ Import n8n workflows
3. ✅ Configure environment variables
4. ✅ Test with sample product image
5. 🚀 Build your frontend with Bolt/Genspark
6. 💳 Set up Stripe for payments
7. 📧 Configure email notifications
8. 🚀 Deploy to production
