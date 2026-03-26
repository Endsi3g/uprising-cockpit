// Static seed data for local development without Supabase auth
// Replace with real business_id when auth is implemented
const String kDevBusinessId = '00000000-0000-0000-0000-000000000001';

// Supabase table names
const String kTableBusinesses = 'businesses';
const String kTableClients = 'clients';
const String kTableLeads = 'leads';
const String kTableTranscripts = 'transcripts';
const String kTableBookings = 'bookings';
const String kTableCalls = 'calls';
const String kTableValuePresets = 'value_presets';

// Groq
const String kGroqBaseUrl = 'https://api.groq.com/openai/v1';
const String kGroqModel = 'llama-3.3-70b-versatile';

// Ollama
const String kOllamaBaseUrl = 'http://localhost:11434';
const String kOllamaModel = 'llama3.2';

// Lead sources
enum LeadSource { call, sms, form }
enum LeadStatus { nouveau, qualifie, booke, perdu, complete }
enum BookingStatus { planifie, complete, annule }
enum TradeType { plombier, couvreur }

extension LeadSourceLabel on LeadSource {
  String get label {
    switch (this) {
      case LeadSource.call: return 'Appel';
      case LeadSource.sms: return 'SMS';
      case LeadSource.form: return 'Formulaire';
    }
  }
}

extension LeadStatusLabel on LeadStatus {
  String get label {
    switch (this) {
      case LeadStatus.nouveau: return 'Nouveau';
      case LeadStatus.qualifie: return 'Qualifié';
      case LeadStatus.booke: return 'Booké';
      case LeadStatus.perdu: return 'Perdu';
      case LeadStatus.complete: return 'Complété';
    }
  }
}
