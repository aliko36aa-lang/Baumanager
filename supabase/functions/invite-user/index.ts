import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.4'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: cors })
  }

  try {
    const { email } = await req.json()
    if (!email) throw new Error('E-Mail fehlt')

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('Nicht autorisiert')

    // Verify caller is a logged-in admin
    const userClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )
    const { data: { user } } = await userClient.auth.getUser()
    if (!user) throw new Error('Nicht eingeloggt')

    const { data: role } = await userClient
      .from('user_roles')
      .select('rolle')
      .eq('email', user.email)
      .maybeSingle()
    if (!role || role.rolle !== 'admin') throw new Error('Nur Admins dürfen einladen')

    // Send the invitation email via admin client
    const adminClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )
    const { error } = await adminClient.auth.admin.inviteUserByEmail(email, {
      redirectTo: 'https://aliko36aa-lang.github.io/Baumanager',
    })
    if (error) throw error

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...cors, 'Content-Type': 'application/json' },
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), {
      headers: { ...cors, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
