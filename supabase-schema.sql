-- Zombie Genetix — Supabase Schema
-- Run this in your Supabase project's SQL editor.

-- ── STRAINS ──────────────────────────────────────────────────────────────────
create table if not exists strains (
  id           uuid primary key default gen_random_uuid(),
  breeder      text not null,
  strain       text not null,
  type         text check (type in ('Auto','Photo')) not null,
  sex          text check (sex in ('Fem','Reg'))    not null,
  thc_cbd      text,
  hybrid_type  text check (hybrid_type in ('Indica','Sativa','Hybrid')),
  hybrid_detail text,
  lineage      text,
  notes        text,
  flower_time  text,
  status       text check (status in ('house','featured','new') or status is null),
  image_url    text,
  sort_order   integer default 0,
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);

-- ── GALLERY PHOTOS ───────────────────────────────────────────────────────────
create table if not exists gallery_photos (
  id          uuid primary key default gen_random_uuid(),
  strain_id   uuid references strains(id) on delete set null,
  url         text not null,
  caption     text,
  credit      text,
  credit_url  text,
  tags        text[] default '{}',
  taken_at    date,
  created_at  timestamptz default now()
);

-- ── ROW LEVEL SECURITY ───────────────────────────────────────────────────────
alter table strains        enable row level security;
alter table gallery_photos enable row level security;

-- Public read
create policy "public read strains"
  on strains for select using (true);

create policy "public read gallery"
  on gallery_photos for select using (true);

-- Authenticated write (used by admin page with service role key)
create policy "auth write strains"
  on strains for all using (auth.role() = 'service_role');

create policy "auth write gallery"
  on gallery_photos for all using (auth.role() = 'service_role');

-- ── UPDATED_AT TRIGGER ───────────────────────────────────────────────────────
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

create trigger strains_updated_at
  before update on strains
  for each row execute function set_updated_at();

-- ── STORAGE BUCKET ───────────────────────────────────────────────────────────
-- Run in Supabase dashboard → Storage → New bucket:
--   Name: genetics-images   Public: yes
--   Name: gallery-photos    Public: yes
--
-- Or via SQL (requires pg_storage extension):
-- insert into storage.buckets (id, name, public) values
--   ('genetics-images', 'genetics-images', true),
--   ('gallery-photos',  'gallery-photos',  true)
-- on conflict do nothing;
