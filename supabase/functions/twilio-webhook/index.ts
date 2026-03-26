import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const twilioResponseCall = `<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say voice="alice" language="fr-CA">Bonjour, vous avez joint notre entreprise de plomberie et toiture. Nos équipes sont sur le terrain. Laissez votre nom, adresse et la nature de votre urgence après le bip, un technicien sera averti immédiatement et vous rappellera dans les 5 minutes.</Say>
    <Record maxLength="60" action="/call-recorded" transcribe="false" />
</Response>`;

const twilioResponseSMS = `<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Message>Bonjour, notre IA a bien reçu votre demande d'urgence. Un technicien a été alerté et va vous recontacter d'ici quelques minutes. Merci.</Message>
</Response>`;

serve(async (req) => {
  const url = new URL(req.url);

  // Gérer l'action après enregistrement vocal (si Twilio appelle /call-recorded)
  if (url.pathname.endsWith('/call-recorded')) {
    return new Response('<?xml version="1.0" encoding="UTF-8"?><Response><Hangup/></Response>', {
      headers: { 'Content-Type': 'text/xml' }
    });
  }

  try {
    const bodyText = await req.text();
    const params = new URLSearchParams(bodyText);

    const fromNumber = params.get('From');
    const callSid = params.get('CallSid');       // Si appel vocal
    const messageBody = params.get('Body');      // Si SMS
    const businessId = Deno.env.get('DEV_BUSINESS_ID') || 'test-business-id';

    // Initialiser Supabase (Service Role Key pour outrepasser RLS)
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Déterminer la source
    const source = messageBody ? 'sms' : 'call';
    const status = 'new';
    const triggeredAt = new Date().toISOString();

    // Créer le client (si n'existe pas)
    let clientId = null;
    if (fromNumber) {
      const { data: existingClient } = await supabase
        .from('clients')
        .select('id')
        .eq('phone', fromNumber)
        .eq('business_id', businessId)
        .maybeSingle();
      
      if (existingClient) {
        clientId = existingClient.id;
      } else {
        const { data: newClient } = await supabase
          .from('clients')
          .insert({ name: 'Client Inconnu', phone: fromNumber, business_id: businessId })
          .select()
          .single();
        if (newClient) clientId = newClient.id;
      }
    }

    // Insérer le Lead
    const { data: lead } = await supabase
      .from('leads')
      .insert({
        business_id: businessId,
        client_id: clientId,
        source: source,
        status: status,
        triggered_at: triggeredAt,
        ai_handled: true,
        missed_by_human: true,
      })
      .select()
      .single();

    if (lead) {
      if (source === 'sms') {
        // Enregistrer le SMS dans les transcripts simulés
        await supabase.from('transcripts').insert({
          lead_id: lead.id,
          summary: messageBody,
          content: JSON.stringify([{ role: 'client', text: messageBody }])
        });
      } else if (source === 'call') {
        // Enregistrer l'appel
        await supabase.from('calls').insert({
          lead_id: lead.id,
          twilio_call_sid: callSid,
          direction: 'inbound',
          status: 'completed'
        });
      }
    }

    // Retourner le TwiML approprié
    return new Response(source === 'sms' ? twilioResponseSMS : twilioResponseCall, {
      headers: { 'Content-Type': 'text/xml' }
    });

  } catch (error) {
    console.error('Erreur Twilio Webhook:', error);
    return new Response('<?xml version="1.0" encoding="UTF-8"?><Response><Say>Erreur système.</Say></Response>', {
      headers: { 'Content-Type': 'text/xml' },
      status: 500
    });
  }
});
