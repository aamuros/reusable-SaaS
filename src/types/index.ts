export type UserRole = 'user' | 'moderator' | 'admin'

export type PlanName = 'free' | 'basic' | 'pro' | 'enterprise'

export type BillingPeriod = 'monthly' | 'annual'

export type SubscriptionStatus = 'active' | 'cancelled' | 'past_due' | 'trialing'

export type Database = {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string
          email: string
          role: UserRole
          is_suspended: boolean
          created_at: string
          updated_at: string
        }
        Insert: Omit<Database['public']['Tables']['profiles']['Row'], 'created_at' | 'updated_at'>
        Update: Partial<Database['public']['Tables']['profiles']['Insert']>
      }
      plans: {
        Row: {
          id: string
          name: PlanName
          price_monthly: number
          price_annual: number
          features: string[]
          is_active: boolean
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['plans']['Row'], 'id' | 'created_at'>
        Update: Partial<Database['public']['Tables']['plans']['Insert']>
      }
      subscriptions: {
        Row: {
          id: string
          user_id: string
          plan_id: string
          status: SubscriptionStatus
          paymongo_subscription_id: string | null
          period_end: string | null
          billing_period: BillingPeriod
          created_at: string
          updated_at: string
        }
        Insert: Omit<Database['public']['Tables']['subscriptions']['Row'], 'id' | 'created_at' | 'updated_at'>
        Update: Partial<Database['public']['Tables']['subscriptions']['Insert']>
      }
      purchases: {
        Row: {
          id: string
          user_id: string
          product: string
          amount: number
          paymongo_payment_id: string
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['purchases']['Row'], 'id' | 'created_at'>
        Update: Partial<Database['public']['Tables']['purchases']['Insert']>
      }
      audit_logs: {
        Row: {
          id: string
          admin_id: string
          action: string
          target_id: string | null
          metadata: Record<string, unknown>
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['audit_logs']['Row'], 'id' | 'created_at'>
        Update: never
      }
      feature_flags: {
        Row: {
          id: string
          name: string
          enabled_for_plans: PlanName[]
          enabled_for_users: string[]
          created_at: string
          updated_at: string
        }
        Insert: Omit<Database['public']['Tables']['feature_flags']['Row'], 'id' | 'created_at' | 'updated_at'>
        Update: Partial<Database['public']['Tables']['feature_flags']['Insert']>
      }
      coupons: {
        Row: {
          id: string
          code: string
          discount_type: 'percent' | 'fixed'
          discount_value: number
          expires_at: string | null
          max_uses: number | null
          use_count: number
          created_at: string
        }
        Insert: Omit<Database['public']['Tables']['coupons']['Row'], 'id' | 'use_count' | 'created_at'>
        Update: Partial<Database['public']['Tables']['coupons']['Insert']>
      }
    }
  }
}
