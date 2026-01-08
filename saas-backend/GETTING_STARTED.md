# 🚀 Getting Started with Your SaaS Backend

**Your UGC workflow is now a complete multi-tenant SaaS platform!**

**Conceived by Romuald Członkowski** - [www.aiadvisors.pl/en](https://www.aiadvisors.pl/en)

---

## 🎯 What You Have Now

Instead of a **single-user workflow**, you now have a **production-ready SaaS backend** with:

### ✅ What Changed

**BEFORE (Your Original Workflow):**
- ❌ One user only
- ❌ No authentication
- ❌ Hardcoded API keys
- ❌ No credit system
- ❌ No user management
- ❌ Synchronous responses

**AFTER (Your New SaaS Backend):**
- ✅ Unlimited users (multi-tenant)
- ✅ Supabase JWT authentication
- ✅ Environment variables for secrets
- ✅ Per-user credit system (10 credits = 1 video)
- ✅ Subscription tiers (Free/Pro/Enterprise)
- ✅ Async processing with status tracking
- ✅ Complete API for frontend integration

---

## 📂 What Was Created

```
saas-backend/
├── 📄 README.md                      ← Start here! Complete setup guide
├── 📄 SUMMARY.md                     ← Project overview
├── 📄 GETTING_STARTED.md             ← This file
├── 📄 .env.example                   ← All environment variables explained
│
├── 📁 supabase/
│   └── migrations/
│       └── 001_initial_schema.sql   ← Run this in Supabase SQL editor
│
├── 📁 workflows/
│   ├── ugc-saas-api.json            ← Import to n8n (main API)
│   └── job-status-api.json          ← Import to n8n (status check)
│
└── 📁 docs/
    ├── API_DOCUMENTATION.md         ← API reference for developers
    ├── QUICK_START_GUIDE.md         ← 30-min setup walkthrough
    └── FRONTEND_INTEGRATION.md      ← Build frontend with Bolt/Genspark
```

---

## ⚡ Quick Setup (30 Minutes)

### Step 1: Supabase (10 min)

1. **Create project** at [supabase.com](https://supabase.com)
2. **Run migration:**
   - Open SQL Editor in Supabase
   - Copy/paste `supabase/migrations/001_initial_schema.sql`
   - Click "Run"
3. **Create storage bucket** named `user-videos` (make it public)
4. **Save your keys** from Settings → API

### Step 2: n8n (10 min)

1. **Set environment variables** in n8n (Settings → Environment):
   ```bash
   SUPABASE_URL=https://xxx.supabase.co
   SUPABASE_ANON_KEY=eyJ...
   SUPABASE_SERVICE_ROLE_KEY=eyJ...
   KIE_API_KEY=your-key
   GEMINI_API_KEY=your-key
   API_BASE_URL=https://your-n8n.com/webhook
   ```

2. **Import workflows:**
   - Import `workflows/ugc-saas-api.json`
   - Import `workflows/job-status-api.json`
   - Activate both

3. **Copy webhook URLs** - Share with frontend team

### Step 3: Test (5 min)

1. Create test user in Supabase (Auth → Users)
2. Get JWT token
3. Call generate API with product image
4. Poll status API until complete

### Step 4: Build Frontend (varies)

Use **Bolt.new** or **Genspark Developer** with the guide in:
`docs/FRONTEND_INTEGRATION.md`

---

## 🎨 How Your Frontend Will Work

### 1. User Signs Up / Logs In (Supabase Auth)

```javascript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

// Sign up
await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'password'
})
// → User auto-gets 10 credits (1 free video)
```

### 2. Generate Video

```javascript
// Get JWT token
const { data: { session } } = await supabase.auth.getSession()

// Create form
const formData = new FormData()
formData.append('productImage', imageFile)
formData.append('productName', 'Headphones')
formData.append('ugcType', 'Holding Product - Natural pose')
formData.append('targetAudience', 'Gen Z (18-24)')

// Call your n8n API
const response = await fetch('https://your-n8n.com/webhook/v1/generate-ugc', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${session.access_token}`
  },
  body: formData
})

const { jobId } = await response.json()
// → Credits deducted, processing starts
```

### 3. Check Progress (Poll Every 3 Seconds)

```javascript
const checkStatus = async (jobId) => {
  const response = await fetch(
    `https://your-n8n.com/webhook/v1/job-status/${jobId}`,
    {
      headers: {
        'Authorization': `Bearer ${session.access_token}`
      }
    }
  )

  const status = await response.json()

  console.log(status.progress) // 0-100%
  console.log(status.currentStep) // "Generating scene 2 of 2"

  if (status.status === 'completed') {
    return status.videoUrl // Ready to play!
  }
}
```

### 4. Display Video

```javascript
{status === 'completed' && (
  <video src={videoUrl} controls />
)}
```

---

## 💳 Credit System Explained

### How It Works

1. **New user signs up** → Gets 10 free credits automatically
2. **User clicks "Generate"** → Frontend calls API
3. **Backend checks credits** → Must have ≥ 10 credits
4. **If insufficient** → Returns 402 error "Upgrade your plan"
5. **If sufficient** → Deducts 10 credits, starts processing
6. **If job fails** → Refunds 10 credits automatically

### Subscription Tiers

| Tier | Credits | Videos | Cost |
|------|---------|--------|------|
| Free | 10/month | 1 | $0 |
| Pro | 100/month | 10 | $49/mo |
| Enterprise | 1000/month | 100 | $299/mo |

Add Stripe later to enable payments!

---

## 🔐 Security Built-In

Your backend is **production-ready** with:

✅ **Authentication** - JWT tokens (Supabase)
✅ **Authorization** - Users can only see their own data (RLS)
✅ **Data Isolation** - Each user has separate jobs/videos
✅ **Credit Protection** - Atomic transactions prevent race conditions
✅ **API Key Security** - All secrets in environment variables
✅ **Validation** - Input validation on all endpoints

---

## 📊 Database Tables (Auto-Created)

Your Supabase now has:

1. **`user_profiles`** - User data + credits + subscription
2. **`subscription_plans`** - Plan definitions (Free/Pro/Enterprise)
3. **`video_jobs`** - All video generation jobs with status
4. **`credit_transactions`** - Audit log of all credit changes
5. **`usage_logs`** - API usage analytics

All tables have **Row-Level Security** enabled!

---

## 🎯 Next Steps

### Immediate (This Week)

1. ✅ **Setup Supabase** - Run the migration
2. ✅ **Import workflows** - Into n8n
3. ✅ **Test API** - Generate test video
4. ✅ **Build frontend** - Use Bolt.new (see `docs/FRONTEND_INTEGRATION.md`)

### Short-term (This Month)

- [ ] Add Stripe for payments
- [ ] Create pricing page
- [ ] Add email notifications
- [ ] Build admin dashboard

### Long-term (This Quarter)

- [ ] Add video editing features
- [ ] Implement API keys for enterprise
- [ ] Add webhook notifications
- [ ] Scale infrastructure

---

## 📚 Documentation Index

**Pick your path:**

### 🏃 I want to start quickly
→ Read `docs/QUICK_START_GUIDE.md` (30 minutes)

### 🎨 I'm building the frontend
→ Read `docs/FRONTEND_INTEGRATION.md` (Bolt/Genspark guide)

### 👨‍💻 I need API reference
→ Read `docs/API_DOCUMENTATION.md` (Complete API docs)

### 🔧 I want to understand everything
→ Read `README.md` (Full setup guide)

### 📊 I want to see what was built
→ Read `SUMMARY.md` (Project overview)

---

## 🆘 Need Help?

### Common Issues

**"UNAUTHORIZED: Missing token"**
→ Frontend not sending JWT. Check `Authorization: Bearer ${token}`

**"INSUFFICIENT_CREDITS"**
→ User has 0 credits. Add manually in Supabase or implement Stripe

**"JOB_NOT_FOUND"**
→ User trying to access another user's job (RLS blocking). This is correct behavior!

### Support

**Romuald Członkowski**
- Website: [www.aiadvisors.pl/en](https://www.aiadvisors.pl/en)
- Email: contact@aiadvisors.pl

---

## 🎉 You're Ready!

Your UGC workflow is now a **complete SaaS platform**!

**What you can do now:**

1. ✅ Support unlimited users
2. ✅ Charge per video (credit system)
3. ✅ Offer subscription tiers
4. ✅ Track usage and analytics
5. ✅ Scale to 1000s of users
6. ✅ Build beautiful frontend with Bolt/Genspark
7. ✅ Add payment processing (Stripe)
8. ✅ Launch your SaaS business! 🚀

---

**Start with:** `docs/QUICK_START_GUIDE.md`

**Conceived by Romuald Członkowski** - [www.aiadvisors.pl/en](https://www.aiadvisors.pl/en)
