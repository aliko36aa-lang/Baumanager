-- ============================================================
-- Baumanager – Supabase Setup SQL
-- Einmalig im Supabase SQL Editor ausführen
-- ============================================================

-- KUNDEN
create table if not exists kunden (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  telefon text,
  email text,
  adresse text,
  notiz text,
  user_id uuid references auth.users(id),
  created_at timestamptz default now()
);
alter table kunden enable row level security;
create policy "kunden_own" on kunden for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

-- PROJEKTE
create table if not exists projekte (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  kunden_id uuid references kunden(id),
  kunde text,
  kunde_name text,
  adresse text,
  beschreibung text,
  status text default 'Aktiv',
  datum_start date,
  datum_end date,
  user_id uuid references auth.users(id),
  created_at timestamptz default now()
);
alter table projekte enable row level security;
create policy "projekte_own" on projekte for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

-- OBJEKTE (Gebäude / Liegenschaften)
create table if not exists objekte (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  adresse text,
  typ text default 'Sonstiges',
  status text default 'Aktiv',
  kunden_id uuid references kunden(id),
  beschreibung text,
  user_id uuid references auth.users(id),
  created_at timestamptz default now()
);
alter table objekte enable row level security;
create policy "objekte_own" on objekte for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

-- AUFGABEN
create table if not exists aufgaben (
  id uuid default gen_random_uuid() primary key,
  titel text not null,
  beschreibung text,
  prioritaet text default 'B',
  zustaendig text,
  faellig date,
  status text default 'offen',
  projekt_id uuid references projekte(id),
  lead_id uuid,
  objekt_id uuid references objekte(id),
  wiederholung text,   -- taeglich | woechentlich | monatlich | jaehrlich
  user_id uuid references auth.users(id),
  created_at timestamptz default now()
);
alter table aufgaben enable row level security;
create policy "aufgaben_own" on aufgaben for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

-- MITARBEITER
create table if not exists mitarbeiter (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  telefon text,
  rolle text default 'Mitarbeiter',
  stundensatz numeric,
  farbe text default '#1D4ED8',
  user_id uuid references auth.users(id),
  created_at timestamptz default now()
);
alter table mitarbeiter enable row level security;
create policy "mitarbeiter_own" on mitarbeiter for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

-- STUNDEN (Zeiterfassung)
create table if not exists stunden (
  id uuid default gen_random_uuid() primary key,
  mitarbeiter_name text,
  projekt_id uuid references projekte(id),
  datum date,
  stunden numeric,
  stundensatz numeric,
  notiz text,
  user_id uuid references auth.users(id),
  created_at timestamptz default now()
);
alter table stunden enable row level security;
create policy "stunden_own" on stunden for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

-- TERMINE
create table if not exists termine (
  id uuid default gen_random_uuid() primary key,
  titel text not null,
  datum date,
  uhrzeit text,
  status text default 'geplant',
  projekt_id uuid references projekte(id),
  user_id uuid references auth.users(id),
  created_at timestamptz default now()
);
alter table termine enable row level security;
create policy "termine_own" on termine for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

-- ANGEBOTE
create table if not exists angebote (
  id uuid default gen_random_uuid() primary key,
  nummer text,
  titel text,
  projekt_id uuid references projekte(id),
  positionen jsonb,
  gesamt numeric,
  status text default 'Entwurf',
  user_id uuid references auth.users(id),
  created_at timestamptz default now()
);
alter table angebote enable row level security;
create policy "angebote_own" on angebote for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

-- RECHNUNGEN
create table if not exists rechnungen (
  id uuid default gen_random_uuid() primary key,
  nummer text,
  titel text,
  projekt_id uuid references projekte(id),
  betrag numeric,
  status text default 'offen',
  faellig date,
  user_id uuid references auth.users(id),
  created_at timestamptz default now()
);
alter table rechnungen enable row level security;
create policy "rechnungen_own" on rechnungen for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

-- MATERIAL
create table if not exists material (
  id uuid default gen_random_uuid() primary key,
  name text,
  menge numeric,
  preis numeric,
  projekt_id uuid references projekte(id),
  user_id uuid references auth.users(id),
  created_at timestamptz default now()
);
alter table material enable row level security;
create policy "material_own" on material for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

-- BAUTAGEBUCH
create table if not exists bautagebuch (
  id uuid default gen_random_uuid() primary key,
  datum date,
  eintrag text,
  projekt_id uuid references projekte(id),
  user_id uuid references auth.users(id),
  created_at timestamptz default now()
);
alter table bautagebuch enable row level security;
create policy "bautagebuch_own" on bautagebuch for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

-- LEADS
create table if not exists leads (
  id uuid default gen_random_uuid() primary key,
  firma text not null,
  ansprechpartner text,
  telefon text,
  email text,
  adresse text,
  bezirk text,
  status text default 'neu',
  quelle text,
  zustaendig text,
  naechste_aktion text,
  naechste_aktion_datum date,
  notiz text,
  einwilligung boolean default false,
  user_id uuid references auth.users(id),
  created_at timestamptz default now()
);
alter table leads enable row level security;
create policy "leads_own" on leads for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

-- ANFRAGEN (Website-Kontaktformular)
create table if not exists anfragen (
  id uuid default gen_random_uuid() primary key,
  name text,
  kontakt text,
  adresse text,
  beschreibung text,
  status text default 'neu',
  prioritaet text default 'medium',
  notiz text,
  aufgabe_id uuid,
  user_id uuid references auth.users(id),
  created_at timestamptz default now()
);
alter table anfragen enable row level security;
create policy "anfragen_own" on anfragen for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

-- VERTRÄGE
create table if not exists vertraege (
  id uuid default gen_random_uuid() primary key,
  titel text,
  typ text,
  inhalt text,
  user_id uuid references auth.users(id),
  created_at timestamptz default now()
);
alter table vertraege enable row level security;
create policy "vertraege_own" on vertraege for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

-- EINSTELLUNGEN
create table if not exists einstellungen (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) unique,
  firma text,
  adresse text,
  telefon text,
  email text,
  mwst numeric default 19,
  zahlungsziel integer default 14,
  iban text,
  bank text,
  ustid text,
  steuernr text,
  created_at timestamptz default now()
);
alter table einstellungen enable row level security;
create policy "einstellungen_own" on einstellungen for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

-- USER ROLES (für Rollenbasierter Zugriff)
create table if not exists user_roles (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id),
  email text,
  rolle text default 'mitarbeiter',  -- admin | mitarbeiter | kunde
  created_at timestamptz default now()
);
alter table user_roles enable row level security;
create policy "user_roles_own" on user_roles for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

-- SCHNELLANGEBOT LEISTUNGEN
create table if not exists schnellangebot_leistungen (
  id uuid default gen_random_uuid() primary key,
  gewerk text,
  name text,
  einheit text,
  preis numeric,
  sort_order integer default 0,
  user_id uuid references auth.users(id),
  created_at timestamptz default now()
);
alter table schnellangebot_leistungen enable row level security;
create policy "schnellangebot_own" on schnellangebot_leistungen for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

-- ============================================================
-- FERTIG – Alle Tabellen sind eingerichtet
-- ============================================================
