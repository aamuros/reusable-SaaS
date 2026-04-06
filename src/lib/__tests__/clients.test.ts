import { describe, it, expect } from 'vitest'

describe('lib clients', () => {
  it('supabase browser client is defined', async () => {
    process.env.NEXT_PUBLIC_SUPABASE_URL = 'https://test.supabase.co'
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = 'test-anon-key'
    const { createBrowserClient } = await import('../supabase/client')
    const client = createBrowserClient()
    expect(client).toBeDefined()
  })

  it('resend client is defined', async () => {
    process.env.RESEND_API_KEY = 'test-resend-key'
    const { createResendClient } = await import('../resend')
    const client = createResendClient()
    expect(client).toBeDefined()
  })
})
