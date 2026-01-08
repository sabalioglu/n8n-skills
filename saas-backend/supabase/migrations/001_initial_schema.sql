-- =====================================================
-- UGC SaaS Platform - Initial Database Schema
-- =====================================================
-- This migration creates the core tables for the multi-tenant SaaS platform
-- Conceived by Romuald Członkowski - https://www.aiadvisors.pl/en

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. USER PROFILES (extends Supabase auth.users)
-- =====================================================
CREATE TABLE public.user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT,

  -- Subscription info
  subscription_tier TEXT NOT NULL DEFAULT 'free' CHECK (subscription_tier IN ('free', 'pro', 'enterprise')),
  subscription_status TEXT NOT NULL DEFAULT 'active' CHECK (subscription_status IN ('active', 'cancelled', 'expired', 'trial')),
  subscription_start_date TIMESTAMPTZ DEFAULT NOW(),
  subscription_end_date TIMESTAMPTZ,

  -- Credits
  credits_balance INTEGER NOT NULL DEFAULT 10, -- Free tier gets 10 credits (1 video)
  credits_used INTEGER NOT NULL DEFAULT 0,
  total_videos_generated INTEGER NOT NULL DEFAULT 0,

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_activity_at TIMESTAMPTZ,

  -- Settings
  api_key TEXT UNIQUE, -- Optional: for API access
  webhook_url TEXT, -- Optional: callback URL for job completion

  -- Billing (for future Stripe integration)
  stripe_customer_id TEXT UNIQUE,
  stripe_subscription_id TEXT
);

-- Index for fast lookups
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_user_profiles_subscription_tier ON public.user_profiles(subscription_tier);
CREATE INDEX idx_user_profiles_api_key ON public.user_profiles(api_key) WHERE api_key IS NOT NULL;

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- =====================================================
-- 2. SUBSCRIPTION PLANS
-- =====================================================
CREATE TABLE public.subscription_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tier TEXT NOT NULL UNIQUE CHECK (tier IN ('free', 'pro', 'enterprise')),
  name TEXT NOT NULL,
  description TEXT,

  -- Credits allocation
  credits_per_month INTEGER NOT NULL,
  credits_per_video INTEGER NOT NULL DEFAULT 10,
  max_videos_per_month INTEGER,

  -- Pricing
  price_monthly DECIMAL(10, 2),
  price_yearly DECIMAL(10, 2),
  currency TEXT DEFAULT 'USD',

  -- Features
  features JSONB, -- Array of feature descriptions

  -- Limits
  max_duration_seconds INTEGER DEFAULT 64,
  priority_processing BOOLEAN DEFAULT FALSE,
  webhook_notifications BOOLEAN DEFAULT FALSE,
  api_access BOOLEAN DEFAULT FALSE,

  -- Metadata
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER update_subscription_plans_updated_at
  BEFORE UPDATE ON public.subscription_plans
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Insert default plans
INSERT INTO public.subscription_plans (tier, name, description, credits_per_month, credits_per_video, max_videos_per_month, price_monthly, features) VALUES
('free', 'Free', 'Perfect for trying out UGC ads', 10, 10, 1, 0, '["1 video per month", "Up to 64 seconds", "All UGC styles", "9:16 and 16:9 formats"]'::jsonb),
('pro', 'Pro', 'For growing brands and agencies', 100, 10, 10, 49.00, '["10 videos per month", "Up to 64 seconds", "All UGC styles", "All formats", "Priority processing", "Webhook notifications"]'::jsonb),
('enterprise', 'Enterprise', 'Unlimited scale for large teams', 1000, 10, 100, 299.00, '["100 videos per month", "Unlimited duration", "All features", "API access", "Priority support", "Custom integrations"]'::jsonb);

-- =====================================================
-- 3. VIDEO JOBS
-- =====================================================
CREATE TABLE public.video_jobs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id TEXT NOT NULL UNIQUE, -- videoId from workflow

  -- User reference
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  user_email TEXT NOT NULL,

  -- Input data
  product_name TEXT NOT NULL,
  product_description TEXT,
  product_image_url TEXT NOT NULL,

  -- UGC Configuration
  ugc_type TEXT NOT NULL,
  target_audience TEXT NOT NULL,
  platform TEXT NOT NULL,
  duration INTEGER NOT NULL,
  total_scenes INTEGER NOT NULL,
  aspect_ratio TEXT NOT NULL,

  -- AI-generated metadata
  product_category TEXT,
  product_analysis JSONB,
  character_model JSONB,
  grid_strategy JSONB,

  -- Output
  video_url TEXT,
  thumbnail_url TEXT,
  scenes JSONB,

  -- Processing status
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending', 'validating', 'processing', 'grid_generation', 'character_selection',
    'scene_generation', 'video_assembly', 'completed', 'failed'
  )),
  error_message TEXT,

  -- Progress tracking
  progress_percentage INTEGER DEFAULT 0,
  current_step TEXT,

  -- Credits
  credits_cost INTEGER NOT NULL DEFAULT 10,
  credits_refunded INTEGER DEFAULT 0,

  -- Timing
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  processing_time_seconds INTEGER,

  -- Metadata
  file_size BIGINT,
  webhook_notified BOOLEAN DEFAULT FALSE,

  CONSTRAINT valid_progress CHECK (progress_percentage >= 0 AND progress_percentage <= 100)
);

-- Indexes for performance
CREATE INDEX idx_video_jobs_user_id ON public.video_jobs(user_id);
CREATE INDEX idx_video_jobs_job_id ON public.video_jobs(job_id);
CREATE INDEX idx_video_jobs_status ON public.video_jobs(status);
CREATE INDEX idx_video_jobs_created_at ON public.video_jobs(created_at DESC);
CREATE INDEX idx_video_jobs_user_created ON public.video_jobs(user_id, created_at DESC);

-- =====================================================
-- 4. CREDIT TRANSACTIONS
-- =====================================================
CREATE TABLE public.credit_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,

  -- Transaction details
  transaction_type TEXT NOT NULL CHECK (transaction_type IN (
    'purchase', 'refund', 'video_generation', 'subscription_renewal', 'bonus', 'admin_adjustment'
  )),
  amount INTEGER NOT NULL, -- Positive for additions, negative for deductions
  balance_before INTEGER NOT NULL,
  balance_after INTEGER NOT NULL,

  -- Reference
  job_id UUID REFERENCES public.video_jobs(id) ON DELETE SET NULL,
  description TEXT,

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id) -- For admin adjustments
);

-- Indexes
CREATE INDEX idx_credit_transactions_user_id ON public.credit_transactions(user_id);
CREATE INDEX idx_credit_transactions_created_at ON public.credit_transactions(created_at DESC);
CREATE INDEX idx_credit_transactions_job_id ON public.credit_transactions(job_id) WHERE job_id IS NOT NULL;

-- =====================================================
-- 5. USAGE LOGS (for analytics and debugging)
-- =====================================================
CREATE TABLE public.usage_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,

  -- Request details
  endpoint TEXT NOT NULL, -- e.g., '/api/generate-ugc', '/api/job-status'
  method TEXT NOT NULL, -- GET, POST

  -- Authentication
  auth_method TEXT, -- 'jwt', 'api_key'
  ip_address INET,
  user_agent TEXT,

  -- Job reference
  job_id TEXT,

  -- Response
  status_code INTEGER,
  response_time_ms INTEGER,
  error_message TEXT,

  -- Timestamp
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_usage_logs_user_id ON public.usage_logs(user_id);
CREATE INDEX idx_usage_logs_created_at ON public.usage_logs(created_at DESC);
CREATE INDEX idx_usage_logs_endpoint ON public.usage_logs(endpoint);

-- Auto-cleanup old logs (keep 90 days)
-- You can set up a cron job or pg_cron extension to run this
-- DELETE FROM public.usage_logs WHERE created_at < NOW() - INTERVAL '90 days';

-- =====================================================
-- 6. ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.video_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.credit_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usage_logs ENABLE ROW LEVEL SECURITY;

-- User Profiles: Users can only see their own profile
CREATE POLICY "Users can view own profile"
  ON public.user_profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.user_profiles FOR UPDATE
  USING (auth.uid() = id);

-- Video Jobs: Users can only see their own jobs
CREATE POLICY "Users can view own jobs"
  ON public.video_jobs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own jobs"
  ON public.video_jobs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Credit Transactions: Users can only view their own transactions
CREATE POLICY "Users can view own transactions"
  ON public.credit_transactions FOR SELECT
  USING (auth.uid() = user_id);

-- Usage Logs: Users can view their own logs
CREATE POLICY "Users can view own usage logs"
  ON public.usage_logs FOR SELECT
  USING (auth.uid() = user_id);

-- =====================================================
-- 7. HELPER FUNCTIONS
-- =====================================================

-- Function: Check if user has enough credits
CREATE OR REPLACE FUNCTION public.check_user_credits(
  p_user_id UUID,
  p_credits_required INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
  v_balance INTEGER;
BEGIN
  SELECT credits_balance INTO v_balance
  FROM public.user_profiles
  WHERE id = p_user_id;

  RETURN v_balance >= p_credits_required;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Deduct credits and log transaction
CREATE OR REPLACE FUNCTION public.deduct_credits(
  p_user_id UUID,
  p_credits INTEGER,
  p_job_id UUID,
  p_description TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  v_balance_before INTEGER;
  v_balance_after INTEGER;
BEGIN
  -- Get current balance
  SELECT credits_balance INTO v_balance_before
  FROM public.user_profiles
  WHERE id = p_user_id
  FOR UPDATE; -- Lock the row

  -- Check if enough credits
  IF v_balance_before < p_credits THEN
    RETURN FALSE;
  END IF;

  -- Deduct credits
  v_balance_after := v_balance_before - p_credits;

  UPDATE public.user_profiles
  SET
    credits_balance = v_balance_after,
    credits_used = credits_used + p_credits,
    updated_at = NOW()
  WHERE id = p_user_id;

  -- Log transaction
  INSERT INTO public.credit_transactions (
    user_id, transaction_type, amount, balance_before, balance_after, job_id, description
  ) VALUES (
    p_user_id, 'video_generation', -p_credits, v_balance_before, v_balance_after, p_job_id, p_description
  );

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Refund credits
CREATE OR REPLACE FUNCTION public.refund_credits(
  p_user_id UUID,
  p_credits INTEGER,
  p_job_id UUID,
  p_description TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  v_balance_before INTEGER;
  v_balance_after INTEGER;
BEGIN
  -- Get current balance
  SELECT credits_balance INTO v_balance_before
  FROM public.user_profiles
  WHERE id = p_user_id
  FOR UPDATE;

  -- Add credits back
  v_balance_after := v_balance_before + p_credits;

  UPDATE public.user_profiles
  SET
    credits_balance = v_balance_after,
    credits_used = credits_used - p_credits,
    updated_at = NOW()
  WHERE id = p_user_id;

  -- Log transaction
  INSERT INTO public.credit_transactions (
    user_id, transaction_type, amount, balance_before, balance_after, job_id, description
  ) VALUES (
    p_user_id, 'refund', p_credits, v_balance_before, v_balance_after, p_job_id, p_description
  );

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Auto-create user profile on signup (trigger)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: Auto-create profile when user signs up
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON TABLE public.user_profiles IS 'Extended user profiles with subscription and credits info';
COMMENT ON TABLE public.subscription_plans IS 'Available subscription tiers and their limits';
COMMENT ON TABLE public.video_jobs IS 'UGC video generation jobs with full metadata';
COMMENT ON TABLE public.credit_transactions IS 'Audit log of all credit additions and deductions';
COMMENT ON TABLE public.usage_logs IS 'API usage logs for analytics and debugging';

COMMENT ON FUNCTION public.check_user_credits IS 'Check if user has sufficient credits for an operation';
COMMENT ON FUNCTION public.deduct_credits IS 'Atomically deduct credits and log the transaction';
COMMENT ON FUNCTION public.refund_credits IS 'Refund credits to user (e.g., on job failure)';
