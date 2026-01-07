# UGC SaaS Platform - API Documentation

**Version:** 1.0.0
**Base URL:** `https://your-n8n-instance.com/webhook`

Conceived by Romuald Członkowski - [www.aiadvisors.pl/en](https://www.aiadvisors.pl/en)

---

## Table of Contents

1. [Authentication](#authentication)
2. [API Endpoints](#api-endpoints)
   - [Generate UGC Video](#1-generate-ugc-video)
   - [Get Job Status](#2-get-job-status)
3. [Data Models](#data-models)
4. [Error Handling](#error-handling)
5. [Rate Limits & Quotas](#rate-limits--quotas)
6. [Webhooks (Optional)](#webhooks-optional)
7. [Code Examples](#code-examples)

---

## Authentication

All API requests require authentication using **Supabase JWT tokens**.

### How to Authenticate

1. User signs up/logs in via Supabase Auth
2. Supabase returns a JWT access token
3. Include the token in the `Authorization` header:

```http
Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN
```

### Example (JavaScript)

```javascript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

// Sign in
const { data: { session } } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'password'
})

const accessToken = session.access_token // Use this in API calls
```

---

## API Endpoints

### 1. Generate UGC Video

**Endpoint:** `POST /webhook/v1/generate-ugc`

Generates an AI-powered UGC (User Generated Content) video ad from a product image.

#### Request

**Headers:**
```http
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: multipart/form-data
```

**Body (multipart/form-data):**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `productImage` | File | ✅ | Product image (JPG, PNG). Max 10MB |
| `productName` | String | ✅ | Name of the product |
| `productDescription` | String | ❌ | Description of the product |
| `ugcType` | String | ❌ | UGC style (see options below). Default: "Holding Product - Natural pose" |
| `targetAudience` | String | ❌ | Target demographic. Default: "Gen Z (18-24)" |
| `duration` | String | ❌ | Video length. Default: "16s Problem + Solution" |
| `platform` | String | ❌ | Platform format. Default: "TikTok/Reels (9:16)" |

**UGC Type Options:**
- `Holding Product - Natural pose` (default)
- `Using Product - In action`
- `Unboxing - First impression`
- `Mirror Selfie - Authentic angle`
- `Before & After - Transformation`
- `Cozy at Home - Relaxed setting`
- `Friend Sharing - Social moment`
- `ASMR`
- `Podcast`

**Target Audience Options:**
- `Gen Z (18-24)` (default)
- `Millennials (25-40)`
- `Gen X (41-55)`
- `All Ages`
- `Business/Professional`

**Duration Options:**
- `16s Problem + Solution` (2 scenes, 10 credits)
- `24s Story Arc` (3 scenes, 10 credits)
- `32s Extended` (4 scenes, 10 credits)
- `40s Detailed` (5 scenes, 10 credits)
- `48s Complete` (6 scenes, 10 credits)
- `56s Premium` (7 scenes, 10 credits)
- `64s Full Story` (8 scenes, 10 credits)

**Platform Options:**
- `TikTok/Reels (9:16)` (default)
- `YouTube (16:9)`
- `Instagram Feed (1:1)`

#### Response (200 OK)

```json
{
  "success": true,
  "status": "processing",
  "message": "UGC Ad generation started",
  "jobId": "ugc_1704123456789_abc123xyz",
  "ugcType": "Holding Product - Natural pose",
  "targetAudience": "Gen Z (18-24)",
  "duration": "16s",
  "totalScenes": 2,
  "creditsCharged": 10,
  "estimatedTime": "48-80 seconds",
  "statusUrl": "https://your-api.com/webhook/v1/job-status/ugc_1704123456789_abc123xyz"
}
```

#### Error Responses

**401 Unauthorized** - Invalid or missing JWT token
```json
{
  "success": false,
  "error": "UNAUTHORIZED",
  "message": "Missing or invalid authorization token"
}
```

**402 Payment Required** - Insufficient credits
```json
{
  "success": false,
  "error": "INSUFFICIENT_CREDITS",
  "message": "You don't have enough credits to generate a video. Each video costs 10 credits.",
  "creditsRequired": 10,
  "creditsAvailable": 0,
  "upgradeUrl": "https://your-app.com/upgrade"
}
```

**400 Bad Request** - Missing or invalid parameters
```json
{
  "success": false,
  "error": "VALIDATION_ERROR",
  "message": "No product image uploaded. Please include product image in request."
}
```

---

### 2. Get Job Status

**Endpoint:** `GET /webhook/v1/job-status/:jobId`

Check the status of a video generation job.

#### Request

**Headers:**
```http
Authorization: Bearer YOUR_JWT_TOKEN
```

**URL Parameters:**
- `jobId` - The job ID returned from the generate endpoint

#### Response (200 OK)

**Processing:**
```json
{
  "success": true,
  "jobId": "ugc_1704123456789_abc123xyz",
  "status": "scene_generation",
  "progress": 65,
  "currentStep": "Generating scene 4 of 8",
  "productName": "Premium Headphones",
  "ugcType": "Holding Product - Natural pose",
  "targetAudience": "Gen Z (18-24)",
  "duration": 64,
  "totalScenes": 8,
  "aspectRatio": "9:16",
  "platform": "TikTok/Reels (9:16)",
  "videoUrl": null,
  "thumbnailUrl": null,
  "error": null,
  "createdAt": "2024-01-02T10:30:00Z",
  "startedAt": "2024-01-02T10:30:05Z",
  "completedAt": null,
  "processingTimeSeconds": null,
  "estimatedTimeRemaining": 45,
  "creditsCharged": 10,
  "creditsRefunded": 0,
  "category": "electronics",
  "character": {
    "age": 22,
    "gender": "Female",
    "style": "trendy"
  }
}
```

**Completed:**
```json
{
  "success": true,
  "jobId": "ugc_1704123456789_abc123xyz",
  "status": "completed",
  "progress": 100,
  "currentStep": "Video ready",
  "productName": "Premium Headphones",
  "ugcType": "Holding Product - Natural pose",
  "targetAudience": "Gen Z (18-24)",
  "duration": 64,
  "totalScenes": 8,
  "aspectRatio": "9:16",
  "platform": "TikTok/Reels (9:16)",
  "videoUrl": "https://your-storage.supabase.co/storage/v1/object/public/user-videos/videos/ugc_123/final.mp4",
  "thumbnailUrl": "https://example.com/scene_0.jpg",
  "error": null,
  "createdAt": "2024-01-02T10:30:00Z",
  "startedAt": "2024-01-02T10:30:05Z",
  "completedAt": "2024-01-02T10:32:15Z",
  "processingTimeSeconds": 130,
  "estimatedTimeRemaining": 0,
  "creditsCharged": 10,
  "creditsRefunded": 0,
  "category": "electronics",
  "character": {
    "age": 22,
    "gender": "Female",
    "style": "trendy"
  }
}
```

**Failed:**
```json
{
  "success": true,
  "jobId": "ugc_1704123456789_abc123xyz",
  "status": "failed",
  "progress": 45,
  "currentStep": "Scene generation failed",
  "error": "AI generation service timeout",
  "videoUrl": null,
  "thumbnailUrl": null,
  "creditsCharged": 10,
  "creditsRefunded": 10,
  ...
}
```

#### Status Values

| Status | Description |
|--------|-------------|
| `pending` | Job created, waiting to start |
| `validating` | Validating input data |
| `processing` | Initial processing |
| `grid_generation` | Generating 2x2 product grid |
| `character_selection` | Selecting character model |
| `scene_generation` | Generating video scenes |
| `video_assembly` | Assembling final video |
| `completed` | ✅ Video ready |
| `failed` | ❌ Generation failed (credits refunded) |

#### Error Response (404 Not Found)

```json
{
  "success": false,
  "error": "JOB_NOT_FOUND",
  "message": "Job not found or you don't have permission to access it"
}
```

---

## Data Models

### User Profile

```typescript
interface UserProfile {
  id: string                    // UUID
  email: string
  full_name?: string

  // Subscription
  subscription_tier: 'free' | 'pro' | 'enterprise'
  subscription_status: 'active' | 'cancelled' | 'expired' | 'trial'
  subscription_start_date: string
  subscription_end_date?: string

  // Credits
  credits_balance: number
  credits_used: number
  total_videos_generated: number

  // Timestamps
  created_at: string
  updated_at: string
  last_activity_at?: string
}
```

### Video Job

```typescript
interface VideoJob {
  id: string                    // UUID (database ID)
  job_id: string                // Public job ID
  user_id: string
  user_email: string

  // Input
  product_name: string
  product_description?: string
  product_image_url: string

  // Configuration
  ugc_type: string
  target_audience: string
  platform: string
  duration: number              // seconds
  total_scenes: number
  aspect_ratio: string

  // AI Metadata
  product_category?: string
  product_analysis?: object
  character_model?: {
    age: number
    gender: string
    style: string
    // ... more character details
  }

  // Output
  video_url?: string
  thumbnail_url?: string
  scenes?: Array<{
    sceneNumber: number
    imageUrl: string
  }>

  // Status
  status: JobStatus
  progress_percentage: number   // 0-100
  current_step?: string
  error_message?: string

  // Credits
  credits_cost: number
  credits_refunded: number

  // Timing
  created_at: string
  started_at?: string
  completed_at?: string
  processing_time_seconds?: number

  // Metadata
  file_size?: number
  webhook_notified: boolean
}
```

---

## Error Handling

All errors follow this format:

```json
{
  "success": false,
  "error": "ERROR_CODE",
  "message": "Human-readable error message"
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `UNAUTHORIZED` | 401 | Missing or invalid JWT token |
| `INSUFFICIENT_CREDITS` | 402 | Not enough credits to perform action |
| `JOB_NOT_FOUND` | 404 | Job doesn't exist or no access |
| `VALIDATION_ERROR` | 400 | Invalid input parameters |
| `FREE_TIER_LIMIT` | 403 | Operation not allowed on free tier |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error (credits refunded if charged) |

---

## Rate Limits & Quotas

### Free Tier
- **Credits:** 10 per month (1 video)
- **Video Duration:** Max 64 seconds
- **Rate Limit:** 5 requests/hour
- **Concurrent Jobs:** 1

### Pro Tier
- **Credits:** 100 per month (10 videos)
- **Video Duration:** Max 64 seconds
- **Rate Limit:** 60 requests/hour
- **Concurrent Jobs:** 3
- **Priority Processing:** Yes

### Enterprise Tier
- **Credits:** 1000 per month (100 videos)
- **Video Duration:** Unlimited
- **Rate Limit:** Custom
- **Concurrent Jobs:** 10
- **Priority Processing:** Yes
- **API Access:** Yes
- **Dedicated Support:** Yes

---

## Webhooks (Optional)

Users can optionally register a webhook URL to receive notifications when jobs complete.

### Webhook Payload (POST to your URL)

```json
{
  "event": "job.completed",
  "jobId": "ugc_1704123456789_abc123xyz",
  "status": "completed",
  "videoUrl": "https://...",
  "thumbnailUrl": "https://...",
  "processingTimeSeconds": 130,
  "completedAt": "2024-01-02T10:32:15Z"
}
```

### Webhook Events
- `job.completed` - Job finished successfully
- `job.failed` - Job failed (includes error details)

---

## Code Examples

### React + Supabase Example

```jsx
import { createClient } from '@supabase/supabase-js'
import { useState } from 'react'

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
const API_BASE_URL = 'https://your-n8n-instance.com/webhook'

function UGCGenerator() {
  const [jobId, setJobId] = useState(null)
  const [status, setStatus] = useState(null)

  async function generateVideo(productImage, productName) {
    // Get JWT token
    const { data: { session } } = await supabase.auth.getSession()
    const token = session.access_token

    // Create FormData
    const formData = new FormData()
    formData.append('productImage', productImage)
    formData.append('productName', productName)
    formData.append('ugcType', 'Holding Product - Natural pose')
    formData.append('targetAudience', 'Gen Z (18-24)')
    formData.append('duration', '16s Problem + Solution')

    // Generate video
    const response = await fetch(`${API_BASE_URL}/v1/generate-ugc`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`
      },
      body: formData
    })

    const result = await response.json()

    if (!result.success) {
      throw new Error(result.message)
    }

    setJobId(result.jobId)
    pollStatus(result.jobId, token)
  }

  async function pollStatus(jobId, token) {
    const interval = setInterval(async () => {
      const response = await fetch(`${API_BASE_URL}/v1/job-status/${jobId}`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      })

      const status = await response.json()
      setStatus(status)

      if (status.status === 'completed' || status.status === 'failed') {
        clearInterval(interval)
      }
    }, 3000) // Poll every 3 seconds
  }

  return (
    <div>
      {/* Your UI here */}
      {status?.status === 'completed' && (
        <video src={status.videoUrl} controls />
      )}
    </div>
  )
}
```

### Next.js API Route Example

```typescript
// app/api/generate-ugc/route.ts
import { createClient } from '@supabase/supabase-js'

export async function POST(request: Request) {
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
  )

  // Get authenticated user
  const { data: { user } } = await supabase.auth.getUser(
    request.headers.get('Authorization')?.replace('Bearer ', '') || ''
  )

  if (!user) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 })
  }

  // Forward to n8n workflow
  const formData = await request.formData()
  const response = await fetch(
    `${process.env.N8N_WEBHOOK_URL}/v1/generate-ugc`,
    {
      method: 'POST',
      headers: {
        'Authorization': request.headers.get('Authorization')!
      },
      body: formData
    }
  )

  return Response.json(await response.json())
}
```

### Python Example

```python
import requests
from supabase import create_client

# Initialize Supabase
supabase = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)

# Sign in
session = supabase.auth.sign_in_with_password({
    "email": "user@example.com",
    "password": "password"
})
token = session.session.access_token

# Generate video
files = {'productImage': open('product.jpg', 'rb')}
data = {
    'productName': 'Premium Headphones',
    'ugcType': 'Holding Product - Natural pose',
    'targetAudience': 'Gen Z (18-24)',
    'duration': '16s Problem + Solution'
}
headers = {'Authorization': f'Bearer {token}'}

response = requests.post(
    'https://your-n8n-instance.com/webhook/v1/generate-ugc',
    headers=headers,
    data=data,
    files=files
)

result = response.json()
job_id = result['jobId']

# Poll for status
import time
while True:
    status_response = requests.get(
        f'https://your-n8n-instance.com/webhook/v1/job-status/{job_id}',
        headers=headers
    )
    status = status_response.json()

    print(f"Status: {status['status']} - {status['progress']}%")

    if status['status'] in ['completed', 'failed']:
        break

    time.sleep(3)

if status['status'] == 'completed':
    print(f"Video URL: {status['videoUrl']}")
```

---

## Support

For questions or issues:
- Email: support@your-saas.com
- Documentation: https://docs.your-saas.com
- Status Page: https://status.your-saas.com

---

**Conceived by Romuald Członkowski** - [www.aiadvisors.pl/en](https://www.aiadvisors.pl/en)
