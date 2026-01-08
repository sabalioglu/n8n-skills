# 🚀 Quick Start Guide - UGC SaaS Backend

Get your multi-tenant UGC video generation backend running in 30 minutes.

**Conceived by Romuald Członkowski** - [www.aiadvisors.pl/en](https://www.aiadvisors.pl/en)

---

## ⏱️ Timeline

- **10 min:** Supabase setup
- **5 min:** Get API keys
- **10 min:** Import n8n workflows
- **5 min:** Test & verify

**Total: ~30 minutes**

---

## Step 1: Create Supabase Project (10 min)

### 1.1 Sign Up & Create Project

1. Go to [supabase.com](https://supabase.com)
2. Click "Start your project"
3. Create new organization
4. Create new project:
   - **Name:** ugc-video-saas
   - **Database Password:** (save this!)
   - **Region:** Choose closest to you
   - **Plan:** Free (upgrade later)

⏱️ *Wait 2-3 minutes for project to be ready*

### 1.2 Run Database Migration

1. In Supabase dashboard → **SQL Editor**
2. Click "New query"
3. Open `supabase/migrations/001_initial_schema.sql` from this repo
4. Copy ALL contents and paste into SQL Editor
5. Click **Run**

✅ You should see: "Success. No rows returned"

### 1.3 Verify Tables Created

In Supabase → **Table Editor**, you should see:
- `user_profiles`
- `subscription_plans` (with 3 rows: free, pro, enterprise)
- `video_jobs`
- `credit_transactions`
- `usage_logs`

### 1.4 Create Storage Bucket

1. Go to **Storage** in Supabase
2. Click "Create bucket"
3. **Name:** `user-videos`
4. **Public:** ✅ Yes (or set up signed URLs later)
5. Click "Create bucket"

### 1.5 Save Your Keys

Go to **Settings** → **API**

Copy these (you'll need them later):
- ✅ Project URL
- ✅ `anon` `public` key
- ✅ `service_role` `secret` key

---

## Step 2: Get API Keys (5 min)

### 2.1 Kie.ai API Key

1. Go to [kie.ai](https://kie.ai) or your Kie.ai provider
2. Sign up / Log in
3. Go to **API Keys** or **Settings**
4. Create new API key
5. **Save the key** (you won't see it again)
6. Add credits to your account

### 2.2 Google Gemini API Key

1. Go to [ai.google.dev](https://ai.google.dev)
2. Click "Get API key in Google AI Studio"
3. Create project if needed
4. Create API key
5. **Save the key**

---

## Step 3: Set Up n8n (10 min)

### 3.1 Install n8n (if needed)

**Cloud:** [n8n.cloud](https://n8n.cloud) (recommended for quick start)

**Self-hosted:**
```bash
npx n8n
# Visit http://localhost:5678
```

### 3.2 Set Environment Variables

In n8n dashboard:
1. Go to **Settings** → **Environment Variables**
2. Add these:

```bash
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=eyJhbG...
SUPABASE_SERVICE_ROLE_KEY=eyJhbG...
KIE_API_URL=https://api.kie.ai
KIE_API_KEY=your-kie-key
GEMINI_API_KEY=your-gemini-key
API_BASE_URL=https://YOUR_N8N_URL/webhook
```

**For n8n cloud:** Use your cloud URL (e.g., `https://your-instance.app.n8n.cloud/webhook`)

**For self-hosted:** Use your public URL or ngrok for testing

### 3.3 Import Workflows

1. Download these workflow files:
   - `workflows/ugc-saas-api.json`
   - `workflows/job-status-api.json`

2. In n8n → **Workflows** → Click "+" → **Import from File**

3. Import `ugc-saas-api.json`
   - Click "Save"
   - Click "Activate" (toggle in top-right)

4. Import `job-status-api.json`
   - Click "Save"
   - Click "Activate"

### 3.4 Get Webhook URLs

1. Open **ugc-saas-api** workflow
2. Click the "API Webhook" node (first node)
3. Copy the **Production URL**
   - Example: `https://your-n8n.com/webhook/v1/generate-ugc`

4. Repeat for **job-status-api** workflow
   - Example: `https://your-n8n.com/webhook/v1/job-status/:jobId`

✅ **Save these URLs** - your frontend will use them!

---

## Step 4: Test Everything (5 min)

### 4.1 Create Test User in Supabase

1. Supabase → **Authentication** → **Users**
2. Click "Add user"
3. **Email:** test@example.com
4. **Password:** TestPassword123!
5. **Auto Confirm User:** ✅ Yes
6. Click "Create user"

### 4.2 Get JWT Token

Run this in your terminal (replace with your Supabase URL and anon key):

```bash
curl -X POST 'https://YOUR_PROJECT.supabase.co/auth/v1/token?grant_type=password' \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPassword123!"
  }'
```

**Copy the `access_token` from response** - this is your JWT token!

### 4.3 Test Video Generation API

Save this as `test.sh`:

```bash
#!/bin/bash

# Replace these with your values
JWT_TOKEN="YOUR_ACCESS_TOKEN_HERE"
N8N_URL="https://your-n8n.com/webhook"

# Download a test product image (or use your own)
curl -o product.jpg https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500

# Generate UGC video
curl -X POST "$N8N_URL/v1/generate-ugc" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -F "productImage=@product.jpg" \
  -F "productName=Wireless Headphones" \
  -F "productDescription=Premium noise-cancelling headphones" \
  -F "ugcType=Holding Product - Natural pose" \
  -F "targetAudience=Gen Z (18-24)" \
  -F "duration=16s Problem + Solution" \
  -F "platform=TikTok/Reels (9:16)"
```

Run it:
```bash
chmod +x test.sh
./test.sh
```

**Expected Response:**
```json
{
  "success": true,
  "status": "processing",
  "jobId": "ugc_1234567890_abc123",
  "creditsCharged": 10,
  "statusUrl": "https://your-n8n.com/webhook/v1/job-status/ugc_1234567890_abc123"
}
```

### 4.4 Check Job Status

Use the `jobId` from previous response:

```bash
curl -X GET "$N8N_URL/v1/job-status/ugc_1234567890_abc123" \
  -H "Authorization: Bearer $JWT_TOKEN"
```

**Expected Response:**
```json
{
  "success": true,
  "status": "processing",
  "progress": 35,
  "currentStep": "Generating scene 2 of 2",
  "estimatedTimeRemaining": 30
}
```

Keep polling every 3-5 seconds until `status` is `completed`!

### 4.5 Verify in Database

In Supabase → **SQL Editor**:

```sql
-- Check user credits (should be 0 after first video)
SELECT credits_balance, credits_used, total_videos_generated
FROM user_profiles
WHERE email = 'test@example.com';

-- Check job status
SELECT job_id, status, progress_percentage, current_step, video_url
FROM video_jobs
WHERE user_email = 'test@example.com'
ORDER BY created_at DESC
LIMIT 1;

-- Check credit transaction
SELECT transaction_type, amount, description
FROM credit_transactions
WHERE user_id IN (
  SELECT id FROM user_profiles WHERE email = 'test@example.com'
)
ORDER BY created_at DESC
LIMIT 1;
```

---

## ✅ Success Checklist

- [ ] Supabase project created with all tables
- [ ] Storage bucket `user-videos` exists
- [ ] n8n workflows imported and activated
- [ ] Environment variables configured
- [ ] Test user created with 10 credits
- [ ] Video generation request succeeded
- [ ] Credits deducted from user account
- [ ] Job record created in `video_jobs` table
- [ ] Can poll job status endpoint
- [ ] Video URL returned when completed

---

## 🎉 Next Steps

### For Development

1. **Build Frontend**
   - Use Bolt.new or Genspark Developer
   - Integrate Supabase Auth
   - Call your n8n webhook URLs
   - See `docs/API_DOCUMENTATION.md` for examples

2. **Test Thoroughly**
   - Try different UGC styles
   - Test with various product images
   - Verify credit system works
   - Test error cases (no credits, invalid image, etc.)

3. **Add Features**
   - Webhook notifications
   - Email alerts
   - Usage dashboard
   - Credit purchase flow

### For Production

1. **Security Hardening**
   - Enable rate limiting
   - Set up CORS properly
   - Rotate API keys
   - Enable Supabase RLS (already done in migration)

2. **Set Up Payments**
   - Integrate Stripe
   - Create checkout flow
   - Add subscription management
   - Implement credit top-ups

3. **Monitoring**
   - Set up Sentry for errors
   - Configure uptime monitoring
   - Add analytics (Mixpanel, PostHog)
   - Create admin dashboard

4. **Scale Infrastructure**
   - Upgrade Supabase plan
   - Use n8n cloud or scale self-hosted
   - Set up CDN for videos
   - Implement job queue for high volume

---

## 🆘 Troubleshooting

### "UNAUTHORIZED: Missing authorization token"

❌ **Problem:** JWT token not sent or invalid

✅ **Fix:**
```javascript
// Make sure you're sending the token
headers: {
  'Authorization': `Bearer ${accessToken}`
}
```

### "INSUFFICIENT_CREDITS"

❌ **Problem:** User has 0 credits

✅ **Fix:** Add credits manually:
```sql
UPDATE user_profiles
SET credits_balance = credits_balance + 10
WHERE email = 'test@example.com';
```

### Workflow not executing

❌ **Problem:** Workflow not activated or webhook URL wrong

✅ **Fix:**
1. Check workflow is **Activated** (toggle in top-right)
2. Verify webhook URL matches your request URL
3. Check n8n logs for errors

### "Failed to upload product image"

❌ **Problem:** Kie.ai API key invalid or no credits

✅ **Fix:**
1. Verify `KIE_API_KEY` in n8n environment variables
2. Check Kie.ai account has credits
3. Test Kie.ai API directly with curl

### Video stuck at "scene_generation"

❌ **Problem:** AI service timeout or error

✅ **Fix:**
1. Check n8n workflow execution logs
2. Verify all API keys are valid
3. Check `video_jobs.error_message` in database
4. Try with a different/simpler product image

---

## 📞 Support

Need help? Contact:

**Romuald Członkowski**
- Website: [www.aiadvisors.pl/en](https://www.aiadvisors.pl/en)
- Email: contact@aiadvisors.pl

---

## 🎓 Learning Resources

- **API Documentation:** `docs/API_DOCUMENTATION.md`
- **Full Setup Guide:** `README.md`
- **Database Schema:** `supabase/migrations/001_initial_schema.sql`
- **n8n Docs:** https://docs.n8n.io
- **Supabase Docs:** https://supabase.com/docs

---

**You're all set! 🚀 Start building your UGC SaaS frontend!**

Conceived by Romuald Członkowski - [www.aiadvisors.pl/en](https://www.aiadvisors.pl/en)
