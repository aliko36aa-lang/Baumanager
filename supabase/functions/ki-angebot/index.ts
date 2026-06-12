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
    const { text } = await req.json()
    if (!text || String(text).trim().length < 5) throw new Error('Beschreibung fehlt')

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('Nicht autorisiert')

    // Nur eingeloggte Benutzer dürfen die KI nutzen
    const userClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )
    const { data: { user } } = await userClient.auth.getUser()
    if (!user) throw new Error('Nicht eingeloggt')

    const apiKey = Deno.env.get('ANTHROPIC_API_KEY')
    if (!apiKey) throw new Error('ANTHROPIC_API_KEY ist nicht konfiguriert (supabase secrets set)')

    const res = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        model: 'claude-haiku-4-5-20251001',
        max_tokens: 1500,
        system:
          'Du bist Kalkulator in einem deutschen Bau- und Facility-Unternehmen. ' +
          'Erstelle aus der Beschreibung realistische Angebotspositionen mit marktüblichen Netto-Preisen (Deutschland). ' +
          'Antworte AUSSCHLIESSLICH mit einem JSON-Array, ohne Markdown, ohne Erklärung: ' +
          '[{"name":"Leistungsbeschreibung","preis":123.45}]. Maximal 15 Positionen.',
        messages: [{ role: 'user', content: String(text).slice(0, 4000) }],
      }),
    })

    if (!res.ok) {
      const err = await res.text()
      throw new Error('KI-Anfrage fehlgeschlagen: ' + res.status + ' ' + err.slice(0, 200))
    }

    const data = await res.json()
    let raw = data?.content?.[0]?.text ?? '[]'
    // Falls das Modell doch Markdown-Zäune liefert
    raw = raw.replace(/```json|```/g, '').trim()
    const start = raw.indexOf('[')
    const end = raw.lastIndexOf(']')
    if (start === -1 || end === -1) throw new Error('Unerwartete KI-Antwort')

    const positionen = JSON.parse(raw.slice(start, end + 1))
      .filter((p: { name?: string; preis?: number }) => p && p.name)
      .slice(0, 15)
      .map((p: { name: string; preis?: number }) => ({
        name: String(p.name).slice(0, 120),
        preis: Math.max(0, Number(p.preis) || 0),
      }))

    return new Response(JSON.stringify({ positionen }), {
      headers: { ...cors, 'Content-Type': 'application/json' },
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      status: 400,
      headers: { ...cors, 'Content-Type': 'application/json' },
    })
  }
})
