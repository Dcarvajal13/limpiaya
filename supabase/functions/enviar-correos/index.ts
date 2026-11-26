// HU-49 · Despacho de correos transaccionales desde `public.cola_correos`.
//
// Se puede ejecutar con un cron de Supabase (pg_cron / Scheduled Edge Functions)
// cada 5 minutos. Requiere configurar los secretos en Supabase:
//   - SUPABASE_URL
//   - SUPABASE_SERVICE_ROLE_KEY
//   - RESEND_API_KEY (o proveedor SMTP equivalente)
//   - EMAIL_FROM (ej. "LimpiaYa <avisos@limpiaya.app>")

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const RESEND_KEY = Deno.env.get('RESEND_API_KEY') ?? '';
const EMAIL_FROM = Deno.env.get('EMAIL_FROM') ?? 'LimpiaYa <avisos@limpiaya.app>';

Deno.serve(async () => {
  if (!SUPABASE_URL || !SERVICE_KEY) {
    return new Response(
      JSON.stringify({ error: 'Faltan variables de Supabase' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

  const { data: pendientes, error } = await supabase
    .from('cola_correos')
    .select('id, usuario_id, asunto, cuerpo, tipo')
    .eq('estado', 'pendiente')
    .lte('programado_para', new Date().toISOString())
    .order('programado_para', { ascending: true })
    .limit(50);

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  let enviados = 0;
  let fallidos = 0;

  for (const correo of pendientes ?? []) {
    const { data: userRes } = await supabase.auth.admin.getUserById(
      correo.usuario_id,
    );
    const destino = userRes?.user?.email;
    if (!destino) {
      await supabase
        .from('cola_correos')
        .update({ estado: 'error' })
        .eq('id', correo.id);
      fallidos++;
      continue;
    }

    if (!RESEND_KEY) {
      // Sin proveedor configurado aún: deja el registro pendiente sin fallar.
      continue;
    }

    const resp = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${RESEND_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: EMAIL_FROM,
        to: [destino],
        subject: correo.asunto,
        text: correo.cuerpo,
      }),
    });

    if (resp.ok) {
      await supabase
        .from('cola_correos')
        .update({ estado: 'enviado', enviado_en: new Date().toISOString() })
        .eq('id', correo.id);
      enviados++;
    } else {
      await supabase
        .from('cola_correos')
        .update({ estado: 'error' })
        .eq('id', correo.id);
      fallidos++;
    }
  }

  return new Response(
    JSON.stringify({
      procesados: (pendientes ?? []).length,
      enviados,
      fallidos,
      proveedorConfigurado: Boolean(RESEND_KEY),
    }),
    { headers: { 'Content-Type': 'application/json' } },
  );
});
