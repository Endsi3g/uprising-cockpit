-- ================================================
-- Uprising Emergency Cockpit – Supabase Schema
-- ================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ------------------------------------------------
-- BUSINESSES
-- ------------------------------------------------
CREATE TABLE IF NOT EXISTS businesses (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  trade_type  TEXT NOT NULL CHECK (trade_type IN ('plombier', 'couvreur')),
  phone       TEXT,
  city        TEXT,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- Dev seed business
INSERT INTO businesses (id, name, trade_type, phone, city)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'Plomberie Tremblay',
  'plombier',
  '+15141234567',
  'Laval'
) ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------
-- CLIENTS
-- ------------------------------------------------
CREATE TABLE IF NOT EXISTS clients (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  phone       TEXT,
  address     TEXT,
  city        TEXT,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- ------------------------------------------------
-- VALUE PRESETS
-- ------------------------------------------------
CREATE TABLE IF NOT EXISTS value_presets (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id         UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  job_type            TEXT NOT NULL,
  estimated_value_cad NUMERIC(10,2) NOT NULL,
  UNIQUE (business_id, job_type)
);

-- Dev seed presets
INSERT INTO value_presets (business_id, job_type, estimated_value_cad) VALUES
  ('00000000-0000-0000-0000-000000000001', 'Fuite mineure', 800),
  ('00000000-0000-0000-0000-000000000001', 'Fuite majeure', 2500),
  ('00000000-0000-0000-0000-000000000001', 'Toiture complète', 12000),
  ('00000000-0000-0000-0000-000000000001', 'Réparation toiture', 3500),
  ('00000000-0000-0000-0000-000000000001', 'Gel/dégel', 1800),
  ('00000000-0000-0000-0000-000000000001', 'Urgence générale', 1500)
ON CONFLICT DO NOTHING;

-- ------------------------------------------------
-- LEADS
-- ------------------------------------------------
CREATE TABLE IF NOT EXISTS leads (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id         UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  client_id           UUID REFERENCES clients(id),
  source              TEXT NOT NULL CHECK (source IN ('call', 'sms', 'form')),
  status              TEXT NOT NULL DEFAULT 'nouveau'
                        CHECK (status IN ('nouveau','qualifie','booke','perdu','complete')),
  estimated_value_cad NUMERIC(10,2),
  ai_handled          BOOLEAN DEFAULT FALSE,
  missed_by_human     BOOLEAN DEFAULT FALSE,
  triggered_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  summary             TEXT,
  client_phone        TEXT,
  client_address      TEXT,
  job_type            TEXT,
  created_at          TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS leads_business_triggered
  ON leads(business_id, triggered_at DESC);
CREATE INDEX IF NOT EXISTS leads_status ON leads(status);

-- ------------------------------------------------
-- CALLS
-- ------------------------------------------------
CREATE TABLE IF NOT EXISTS calls (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id          UUID REFERENCES leads(id) ON DELETE CASCADE,
  twilio_call_sid  TEXT UNIQUE,
  direction        TEXT CHECK (direction IN ('inbound', 'outbound')),
  duration_seconds INTEGER,
  recording_url    TEXT,
  status           TEXT,
  created_at       TIMESTAMPTZ DEFAULT now()
);

-- ------------------------------------------------
-- TRANSCRIPTS
-- ------------------------------------------------
CREATE TABLE IF NOT EXISTS transcripts (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id    UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE UNIQUE,
  content    JSONB NOT NULL DEFAULT '[]',
  summary    TEXT,
  ai_model   TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ------------------------------------------------
-- BOOKINGS
-- ------------------------------------------------
CREATE TABLE IF NOT EXISTS bookings (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id             UUID REFERENCES leads(id),
  client_id           UUID REFERENCES clients(id),
  business_id         UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  scheduled_at        TIMESTAMPTZ NOT NULL,
  duration_minutes    INTEGER DEFAULT 60,
  job_type            TEXT,
  address             TEXT,
  notes               TEXT,
  status              TEXT DEFAULT 'planifie'
                        CHECK (status IN ('planifie','complete','annule')),
  estimated_value_cad NUMERIC(10,2),
  client_name         TEXT,
  client_phone        TEXT,
  created_at          TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS bookings_business_scheduled
  ON bookings(business_id, scheduled_at);

-- ------------------------------------------------
-- ROW LEVEL SECURITY (disabled for dev)
-- Enable when auth is added
-- ------------------------------------------------
ALTER TABLE businesses DISABLE ROW LEVEL SECURITY;
ALTER TABLE clients DISABLE ROW LEVEL SECURITY;
ALTER TABLE leads DISABLE ROW LEVEL SECURITY;
ALTER TABLE calls DISABLE ROW LEVEL SECURITY;
ALTER TABLE transcripts DISABLE ROW LEVEL SECURITY;
ALTER TABLE bookings DISABLE ROW LEVEL SECURITY;
ALTER TABLE value_presets DISABLE ROW LEVEL SECURITY;

-- ------------------------------------------------
-- SEED: Demo data for local testing
-- ------------------------------------------------
DO $$
DECLARE
  b_id UUID := '00000000-0000-0000-0000-000000000001';
  c1 UUID := gen_random_uuid();
  c2 UUID := gen_random_uuid();
  l1 UUID := gen_random_uuid();
  l2 UUID := gen_random_uuid();
  l3 UUID := gen_random_uuid();
BEGIN
  -- Clients
  INSERT INTO clients (id, business_id, name, phone, address, city) VALUES
    (c1, b_id, 'Jean-Michel Bouchard', '+15144561234', '123 rue des Érables', 'Montréal'),
    (c2, b_id, 'Sophie Tremblay', '+15149876543', '456 boul. Laval', 'Laval')
  ON CONFLICT DO NOTHING;

  -- Leads
  INSERT INTO leads (id, business_id, client_id, source, status, estimated_value_cad,
    ai_handled, missed_by_human, triggered_at, job_type, client_phone, client_address, summary) VALUES
    (l1, b_id, c1, 'call', 'booke', 3200, TRUE, TRUE,
      now() - interval '2 hours', 'Toiture', '+15144561234', '123 rue des Érables, Montréal',
      'Client rapporte une toiture qui coule suite aux pluies. RDV confirmé pour demain 9h. Estimation: 3 200$.'),
    (l2, b_id, c2, 'call', 'nouveau', 800, TRUE, TRUE,
      now() - interval '30 minutes', 'Fuite mineure', '+15149876543', '456 boul. Laval, Laval',
      'Fuite sous l''évier de cuisine. IA a qualifié l''urgence, en attente de confirmation.'),
    (l3, b_id, NULL, 'sms', 'perdu', 1800, FALSE, TRUE,
      now() - interval '5 hours', 'Gel/dégel', '+15141112222', '789 rue Sherbrooke, Brossard',
      NULL)
  ON CONFLICT DO NOTHING;

  -- Transcript for l1
  INSERT INTO transcripts (lead_id, content, summary, ai_model) VALUES
    (l1, '[
      {"role":"ai","text":"Bonjour! Vous avez joint Plomberie Tremblay, je suis l''assistante IA. Comment puis-je vous aider?","ts":"2026-03-25T20:07:00Z"},
      {"role":"client","text":"Bonjour, mon toit coule depuis ce matin, c''est urgent, y''a de l''eau au plafond.","ts":"2026-03-25T20:07:15Z"},
      {"role":"ai","text":"Je comprends, c''est urgent! Est-ce que vous pouvez me donner votre adresse?","ts":"2026-03-25T20:07:20Z"},
      {"role":"client","text":"123 rue des Érables, Montréal.","ts":"2026-03-25T20:07:35Z"},
      {"role":"ai","text":"Parfait. Je vous réserve un rendez-vous pour demain matin à 9h00. Une équipe sera chez vous. Estimation: 3 200$.","ts":"2026-03-25T20:08:00Z"}
    ]',
    'Client: fuite toiture active, eau au plafond. RDV demain 9h00. Estimation: 3 200$.', 'llama-3.3-70b-versatile')
  ON CONFLICT DO NOTHING;

  -- Booking for l1
  INSERT INTO bookings (lead_id, client_id, business_id, scheduled_at, duration_minutes,
    job_type, address, status, estimated_value_cad, client_name, client_phone) VALUES
    (l1, c1, b_id, now() + interval '14 hours', 120, 'Toiture',
    '123 rue des Érables, Montréal', 'planifie', 3200, 'Jean-Michel Bouchard', '+15144561234')
  ON CONFLICT DO NOTHING;
END $$;
