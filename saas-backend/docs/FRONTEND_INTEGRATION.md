# 🎨 Frontend Integration Guide

Complete guide for building your UGC SaaS frontend with **Bolt.new** or **Genspark Developer**.

**Conceived by Romuald Członkowski** - [www.aiadvisors.pl/en](https://www.aiadvisors.pl/en)

---

## 📋 Overview

Your backend (n8n workflows) is ready. Now you need a frontend that:

1. **User Authentication** - Sign up / Login via Supabase Auth
2. **Credit Display** - Show user's remaining credits
3. **Video Generation Form** - Upload product image + configure options
4. **Progress Tracking** - Real-time status updates with polling
5. **Video Gallery** - View past videos
6. **Subscription Management** - Upgrade/downgrade plans

---

## 🏗️ Tech Stack Recommendation

### For Bolt.new

```
React + TypeScript + Tailwind CSS
+ Supabase Client Library
+ React Query (for polling)
+ Zustand (state management)
```

### For Genspark Developer

```
Next.js 14 (App Router) + TypeScript + Tailwind CSS
+ Supabase SSR
+ React Query
+ shadcn/ui components
```

---

## 🚀 Quick Start (Bolt.new)

### 1. Bolt Prompt

Copy this prompt into Bolt.new:

```
Create a UGC Video Generator SaaS app with:

TECH STACK:
- React + TypeScript + Vite
- Tailwind CSS
- Supabase for auth & database
- React Query for API calls

PAGES:
1. Landing page with pricing
2. Sign up / Login (Supabase Auth)
3. Dashboard:
   - Credits display
   - "Generate Video" button
   - Recent videos grid
4. Generate page:
   - Product image upload (drag & drop)
   - Product name & description inputs
   - UGC type dropdown (9 options)
   - Target audience dropdown (5 options)
   - Duration dropdown (7 options)
   - Platform dropdown (3 options)
   - "Generate Video" button
5. Progress page:
   - Circular progress indicator (0-100%)
   - Current step text
   - Estimated time remaining
   - Auto-refresh every 3 seconds
6. Video gallery:
   - Grid of generated videos
   - Thumbnail + metadata
   - Download button
7. Settings:
   - Profile
   - Subscription management
   - API key (for enterprise)

SUPABASE SETUP:
- Project URL: [PASTE_YOUR_URL]
- Anon Key: [PASTE_YOUR_KEY]
- Tables: user_profiles, video_jobs, subscription_plans

API ENDPOINTS:
- Generate: POST https://your-n8n.com/webhook/v1/generate-ugc
- Status: GET https://your-n8n.com/webhook/v1/job-status/:jobId

AUTH FLOW:
1. User signs up via Supabase
2. Auto-create profile with 10 free credits
3. Get JWT token from session
4. Use token in all API calls: Authorization: Bearer {token}

CREDITS SYSTEM:
- Display in header: "X credits remaining"
- 1 video = 10 credits
- Show "Insufficient Credits" modal if balance < 10
- Link to upgrade page

GENERATE FLOW:
1. Validate form inputs
2. Check credits >= 10
3. Create FormData with product image
4. POST to generate endpoint with JWT
5. Get jobId from response
6. Redirect to progress page
7. Poll status endpoint every 3 seconds
8. Show progress bar and current step
9. When status = 'completed', show video
10. Update credits in UI

STYLING:
- Modern, clean, professional
- Purple/blue gradient theme
- Glassmorphism cards
- Smooth animations
- Mobile responsive
```

### 2. Environment Variables

Create `.env` file in Bolt project:

```bash
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
VITE_API_BASE_URL=https://your-n8n.com/webhook
```

---

## 🚀 Quick Start (Genspark Developer)

### Genspark Prompt

```
Build a Next.js 14 UGC Video SaaS with:

FRAMEWORK:
- Next.js 14 (App Router)
- TypeScript
- Tailwind CSS
- shadcn/ui components
- Supabase (SSR)

FOLDER STRUCTURE:
app/
├── (auth)/
│   ├── login/page.tsx
│   └── signup/page.tsx
├── (dashboard)/
│   ├── layout.tsx (protected layout with auth check)
│   ├── page.tsx (dashboard)
│   ├── generate/page.tsx
│   ├── progress/[jobId]/page.tsx
│   ├── videos/page.tsx
│   └── settings/page.tsx
├── api/
│   ├── generate/route.ts (proxy to n8n)
│   └── status/[jobId]/route.ts (proxy to n8n)
└── page.tsx (landing page)

FEATURES:
- Server-side Supabase auth
- Protected routes with middleware
- Real-time credit updates (Supabase Realtime)
- Job status polling with React Query
- Optimistic UI updates
- Error boundaries
- Loading states
- Toast notifications (sonner)

API INTEGRATION:
1. Client calls Next.js API route
2. API route validates auth (server-side)
3. API route proxies to n8n with JWT
4. Returns response to client

SUPABASE SETUP:
- Use Supabase SSR package
- Server components for data fetching
- Client components for interactions
- Realtime subscription for credits

COMPONENTS:
- CreditBadge (shows remaining credits)
- VideoCard (thumbnail + metadata + actions)
- UploadZone (drag-drop product image)
- ProgressCircle (animated 0-100%)
- SubscriptionTier (pricing cards)
```

---

## 📝 Code Examples

### 1. Supabase Setup

```typescript
// lib/supabase.ts
import { createClient } from '@supabase/supabase-js'

export const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
)

// Types
export interface UserProfile {
  id: string
  email: string
  credits_balance: number
  subscription_tier: 'free' | 'pro' | 'enterprise'
  total_videos_generated: number
}

export interface VideoJob {
  job_id: string
  product_name: string
  status: string
  progress_percentage: number
  current_step: string
  video_url?: string
  thumbnail_url?: string
  created_at: string
}
```

### 2. Auth Hook

```typescript
// hooks/useAuth.ts
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import type { User } from '@supabase/supabase-js'

export function useAuth() {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null)
      setLoading(false)
    })

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (_event, session) => {
        setUser(session?.user ?? null)
      }
    )

    return () => subscription.unsubscribe()
  }, [])

  return { user, loading }
}
```

### 3. User Profile Hook

```typescript
// hooks/useUserProfile.ts
import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import type { UserProfile } from '@/lib/supabase'

export function useUserProfile(userId: string | undefined) {
  return useQuery({
    queryKey: ['user-profile', userId],
    queryFn: async () => {
      if (!userId) return null

      const { data, error } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', userId)
        .single()

      if (error) throw error
      return data as UserProfile
    },
    enabled: !!userId,
    refetchInterval: 5000 // Refresh every 5s to update credits
  })
}
```

### 4. Generate Video Function

```typescript
// lib/api.ts
import { supabase } from './supabase'

const API_BASE = import.meta.env.VITE_API_BASE_URL

export async function generateVideo(
  productImage: File,
  options: {
    productName: string
    productDescription?: string
    ugcType?: string
    targetAudience?: string
    duration?: string
    platform?: string
  }
) {
  // Get JWT token
  const { data: { session } } = await supabase.auth.getSession()
  if (!session) throw new Error('Not authenticated')

  // Create form data
  const formData = new FormData()
  formData.append('productImage', productImage)
  formData.append('productName', options.productName)
  if (options.productDescription) {
    formData.append('productDescription', options.productDescription)
  }
  formData.append('ugcType', options.ugcType || 'Holding Product - Natural pose')
  formData.append('targetAudience', options.targetAudience || 'Gen Z (18-24)')
  formData.append('duration', options.duration || '16s Problem + Solution')
  formData.append('platform', options.platform || 'TikTok/Reels (9:16)')

  // Call API
  const response = await fetch(`${API_BASE}/v1/generate-ugc`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${session.access_token}`
    },
    body: formData
  })

  if (!response.ok) {
    const error = await response.json()
    throw new Error(error.message || 'Failed to generate video')
  }

  return await response.json()
}
```

### 5. Job Status Hook (with polling)

```typescript
// hooks/useJobStatus.ts
import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'

const API_BASE = import.meta.env.VITE_API_BASE_URL

export function useJobStatus(jobId: string | undefined) {
  return useQuery({
    queryKey: ['job-status', jobId],
    queryFn: async () => {
      if (!jobId) return null

      const { data: { session } } = await supabase.auth.getSession()
      if (!session) throw new Error('Not authenticated')

      const response = await fetch(`${API_BASE}/v1/job-status/${jobId}`, {
        headers: {
          'Authorization': `Bearer ${session.access_token}`
        }
      })

      if (!response.ok) {
        throw new Error('Failed to fetch job status')
      }

      return await response.json()
    },
    enabled: !!jobId,
    refetchInterval: (data) => {
      // Stop polling if completed or failed
      if (!data) return false
      if (data.status === 'completed' || data.status === 'failed') {
        return false
      }
      return 3000 // Poll every 3 seconds
    }
  })
}
```

### 6. Generate Page Component

```tsx
// pages/Generate.tsx
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useMutation } from '@tanstack/react-query'
import { generateVideo } from '@/lib/api'
import { useUserProfile } from '@/hooks/useUserProfile'
import { useAuth } from '@/hooks/useAuth'

export function GeneratePage() {
  const navigate = useNavigate()
  const { user } = useAuth()
  const { data: profile } = useUserProfile(user?.id)

  const [productImage, setProductImage] = useState<File | null>(null)
  const [productName, setProductName] = useState('')
  const [productDescription, setProductDescription] = useState('')
  const [ugcType, setUgcType] = useState('Holding Product - Natural pose')
  const [targetAudience, setTargetAudience] = useState('Gen Z (18-24)')
  const [duration, setDuration] = useState('16s Problem + Solution')
  const [platform, setPlatform] = useState('TikTok/Reels (9:16)')

  const generateMutation = useMutation({
    mutationFn: () => {
      if (!productImage) throw new Error('No image selected')

      return generateVideo(productImage, {
        productName,
        productDescription,
        ugcType,
        targetAudience,
        duration,
        platform
      })
    },
    onSuccess: (data) => {
      // Redirect to progress page
      navigate(`/progress/${data.jobId}`)
    },
    onError: (error: Error) => {
      alert(error.message)
    }
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()

    // Check credits
    if (!profile || profile.credits_balance < 10) {
      alert('Insufficient credits. Please upgrade your plan.')
      return
    }

    generateMutation.mutate()
  }

  return (
    <div className="max-w-2xl mx-auto p-6">
      <h1 className="text-3xl font-bold mb-6">Generate UGC Video</h1>

      {/* Credits Display */}
      <div className="mb-6 p-4 bg-purple-100 rounded-lg">
        <p className="text-sm text-gray-600">Your Credits</p>
        <p className="text-2xl font-bold text-purple-600">
          {profile?.credits_balance || 0} credits
        </p>
        <p className="text-xs text-gray-500 mt-1">
          This video will cost 10 credits
        </p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Product Image Upload */}
        <div>
          <label className="block text-sm font-medium mb-2">
            Product Image
          </label>
          <input
            type="file"
            accept="image/*"
            onChange={(e) => setProductImage(e.target.files?.[0] || null)}
            className="block w-full"
            required
          />
        </div>

        {/* Product Name */}
        <div>
          <label className="block text-sm font-medium mb-2">
            Product Name
          </label>
          <input
            type="text"
            value={productName}
            onChange={(e) => setProductName(e.target.value)}
            className="w-full px-4 py-2 border rounded-lg"
            required
          />
        </div>

        {/* Product Description */}
        <div>
          <label className="block text-sm font-medium mb-2">
            Product Description (Optional)
          </label>
          <textarea
            value={productDescription}
            onChange={(e) => setProductDescription(e.target.value)}
            className="w-full px-4 py-2 border rounded-lg"
            rows={3}
          />
        </div>

        {/* UGC Type */}
        <div>
          <label className="block text-sm font-medium mb-2">
            UGC Style
          </label>
          <select
            value={ugcType}
            onChange={(e) => setUgcType(e.target.value)}
            className="w-full px-4 py-2 border rounded-lg"
          >
            <option>Holding Product - Natural pose</option>
            <option>Using Product - In action</option>
            <option>Unboxing - First impression</option>
            <option>Mirror Selfie - Authentic angle</option>
            <option>Before & After - Transformation</option>
            <option>Cozy at Home - Relaxed setting</option>
            <option>Friend Sharing - Social moment</option>
            <option>ASMR</option>
            <option>Podcast</option>
          </select>
        </div>

        {/* Target Audience */}
        <div>
          <label className="block text-sm font-medium mb-2">
            Target Audience
          </label>
          <select
            value={targetAudience}
            onChange={(e) => setTargetAudience(e.target.value)}
            className="w-full px-4 py-2 border rounded-lg"
          >
            <option>Gen Z (18-24)</option>
            <option>Millennials (25-40)</option>
            <option>Gen X (41-55)</option>
            <option>All Ages</option>
            <option>Business/Professional</option>
          </select>
        </div>

        {/* Duration */}
        <div>
          <label className="block text-sm font-medium mb-2">
            Video Duration
          </label>
          <select
            value={duration}
            onChange={(e) => setDuration(e.target.value)}
            className="w-full px-4 py-2 border rounded-lg"
          >
            <option>16s Problem + Solution</option>
            <option>24s Story Arc</option>
            <option>32s Extended</option>
            <option>40s Detailed</option>
            <option>48s Complete</option>
            <option>56s Premium</option>
            <option>64s Full Story</option>
          </select>
        </div>

        {/* Platform */}
        <div>
          <label className="block text-sm font-medium mb-2">
            Platform
          </label>
          <select
            value={platform}
            onChange={(e) => setPlatform(e.target.value)}
            className="w-full px-4 py-2 border rounded-lg"
          >
            <option>TikTok/Reels (9:16)</option>
            <option>YouTube (16:9)</option>
            <option>Instagram Feed (1:1)</option>
          </select>
        </div>

        {/* Submit Button */}
        <button
          type="submit"
          disabled={generateMutation.isPending || !productImage}
          className="w-full py-3 bg-purple-600 text-white rounded-lg font-semibold
                     hover:bg-purple-700 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {generateMutation.isPending ? 'Generating...' : 'Generate Video (10 credits)'}
        </button>
      </form>
    </div>
  )
}
```

### 7. Progress Page Component

```tsx
// pages/Progress.tsx
import { useParams } from 'react-router-dom'
import { useJobStatus } from '@/hooks/useJobStatus'

export function ProgressPage() {
  const { jobId } = useParams()
  const { data: job, isLoading } = useJobStatus(jobId)

  if (isLoading) {
    return <div>Loading...</div>
  }

  if (!job) {
    return <div>Job not found</div>
  }

  return (
    <div className="max-w-2xl mx-auto p-6 text-center">
      <h1 className="text-3xl font-bold mb-8">Generating Your Video</h1>

      {/* Progress Circle */}
      <div className="relative w-48 h-48 mx-auto mb-6">
        <svg className="transform -rotate-90 w-48 h-48">
          <circle
            cx="96"
            cy="96"
            r="88"
            stroke="#e5e7eb"
            strokeWidth="12"
            fill="none"
          />
          <circle
            cx="96"
            cy="96"
            r="88"
            stroke="#8b5cf6"
            strokeWidth="12"
            fill="none"
            strokeDasharray={`${2 * Math.PI * 88}`}
            strokeDashoffset={`${2 * Math.PI * 88 * (1 - job.progress / 100)}`}
            className="transition-all duration-300"
          />
        </svg>
        <div className="absolute inset-0 flex items-center justify-center">
          <span className="text-4xl font-bold text-purple-600">
            {job.progress}%
          </span>
        </div>
      </div>

      {/* Status Text */}
      <p className="text-xl font-semibold mb-2">{job.currentStep}</p>

      {job.estimatedTimeRemaining && (
        <p className="text-gray-600 mb-8">
          Estimated time remaining: {Math.ceil(job.estimatedTimeRemaining / 60)} minutes
        </p>
      )}

      {/* Completed State */}
      {job.status === 'completed' && job.videoUrl && (
        <div className="mt-8">
          <h2 className="text-2xl font-bold text-green-600 mb-4">
            ✅ Video Ready!
          </h2>
          <video
            src={job.videoUrl}
            controls
            className="w-full max-w-md mx-auto rounded-lg shadow-lg"
          />
          <div className="mt-4 space-x-4">
            <a
              href={job.videoUrl}
              download
              className="inline-block px-6 py-3 bg-purple-600 text-white rounded-lg"
            >
              Download Video
            </a>
            <button
              onClick={() => navigator.clipboard.writeText(job.videoUrl!)}
              className="inline-block px-6 py-3 bg-gray-200 rounded-lg"
            >
              Copy URL
            </button>
          </div>
        </div>
      )}

      {/* Failed State */}
      {job.status === 'failed' && (
        <div className="mt-8 p-6 bg-red-50 rounded-lg">
          <h2 className="text-2xl font-bold text-red-600 mb-2">
            ❌ Generation Failed
          </h2>
          <p className="text-gray-700 mb-4">{job.error}</p>
          <p className="text-sm text-gray-600">
            Your {job.creditsRefunded} credits have been refunded.
          </p>
        </div>
      )}
    </div>
  )
}
```

---

## 🎨 UI Components Library

### Recommended: shadcn/ui

```bash
npx shadcn-ui@latest init
npx shadcn-ui@latest add button card input select textarea
npx shadcn-ui@latest add progress badge alert dialog
```

Use for:
- Form inputs
- Buttons
- Cards
- Modals
- Toasts

---

## 🔔 Real-time Updates (Optional)

Instead of polling, use Supabase Realtime:

```typescript
// hooks/useRealtimeJob.ts
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'

export function useRealtimeJob(jobId: string) {
  const [job, setJob] = useState(null)

  useEffect(() => {
    // Subscribe to changes
    const channel = supabase
      .channel(`job-${jobId}`)
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'video_jobs',
          filter: `job_id=eq.${jobId}`
        },
        (payload) => {
          setJob(payload.new)
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [jobId])

  return job
}
```

---

## ✅ Testing Checklist

- [ ] User can sign up and auto-get 10 credits
- [ ] Credits display updates in real-time
- [ ] Form validation works (required fields)
- [ ] File upload accepts images only
- [ ] Generate button disabled when < 10 credits
- [ ] Progress page polls every 3 seconds
- [ ] Progress circle animates smoothly
- [ ] Video plays when completed
- [ ] Download button works
- [ ] Failed jobs show error + refund message
- [ ] Video gallery shows all user's videos
- [ ] Mobile responsive

---

## 🚀 Deployment

### Vercel (Recommended for Next.js)

```bash
vercel deploy
```

Add environment variables in Vercel dashboard.

### Netlify (For React/Vite)

```bash
npm run build
netlify deploy --prod --dir=dist
```

---

## 📱 Mobile App (Optional)

Use **React Native** + **Expo** with same logic:

```bash
npx create-expo-app ugc-mobile --template
npm install @supabase/supabase-js
```

All hooks and API functions work the same!

---

## 🎉 You're Ready!

You now have everything to build a complete UGC SaaS frontend.

**Need help?** Contact: [www.aiadvisors.pl/en](https://www.aiadvisors.pl/en)

Conceived by Romuald Członkowski - [www.aiadvisors.pl/en](https://www.aiadvisors.pl/en)
