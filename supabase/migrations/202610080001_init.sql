create extension if not exists pgcrypto;
create table if not exists public.profiles(id uuid primary key references auth.users(id) on delete cascade,name text,company_name text,created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table if not exists public.leads(
 id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,provider_place_id text not null,company_name text not null,
 country text,region text,city text,category text,address text,phone text,website text,source text not null default 'manual',
 status text not null default 'Novo' check(status in('Novo','Aguardando contato','Contatado','Aguardando resposta','Interessado','Negociação','Proposta enviada','Cliente fechado','Recusado','Não contatar','Sem resposta')),
 notes text,opportunity_score integer check(opportunity_score between 0 and 100),opportunity_confidence text check(opportunity_confidence in('alta','media','baixa','insuficiente')),
 last_contact_at timestamptz,next_follow_up_at timestamptz,estimated_value numeric(12,2) check(estimated_value is null or estimated_value>=0),closed_value numeric(12,2) check(closed_value is null or closed_value>=0),
 archived_at timestamptz,created_at timestamptz not null default now(),updated_at timestamptz not null default now(),unique(user_id,provider_place_id));
create index if not exists leads_user_created_idx on public.leads(user_id,created_at desc);
create index if not exists leads_user_status_idx on public.leads(user_id,status);
create table if not exists public.lead_notes(id uuid primary key default gen_random_uuid(),lead_id uuid not null references public.leads(id) on delete cascade,user_id uuid not null references auth.users(id) on delete cascade,content text not null check(length(trim(content))>0),created_at timestamptz not null default now());
create table if not exists public.lead_activities(id uuid primary key default gen_random_uuid(),lead_id uuid not null references public.leads(id) on delete cascade,user_id uuid not null references auth.users(id) on delete cascade,activity_type text not null,description text not null,metadata jsonb not null default '{}'::jsonb,created_at timestamptz not null default now());
create table if not exists public.deals(id uuid primary key default gen_random_uuid(),lead_id uuid not null references public.leads(id) on delete cascade,user_id uuid not null references auth.users(id) on delete cascade,stage text not null default 'Novo',estimated_value numeric(12,2),closed_value numeric(12,2),created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table if not exists public.follow_ups(id uuid primary key default gen_random_uuid(),lead_id uuid not null references public.leads(id) on delete cascade,user_id uuid not null references auth.users(id) on delete cascade,scheduled_at timestamptz not null,status text not null default 'pendente' check(status in('pendente','concluido','cancelado')),created_at timestamptz not null default now());
create table if not exists public.search_history(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,filters jsonb not null default '{}'::jsonb,result_count integer not null default 0,created_at timestamptz not null default now());
create table if not exists public.user_preferences(user_id uuid primary key references auth.users(id) on delete cascade,default_country text not null default 'Brasil',default_region text,default_city text,preferred_niches text[] not null default '{}',whatsapp_template text,updated_at timestamptz not null default now());
create or replace function public.touch_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end; $$;
drop trigger if exists leads_touch_updated_at on public.leads; create trigger leads_touch_updated_at before update on public.leads for each row execute function public.touch_updated_at();
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$ begin insert into public.profiles(id,name) values(new.id,coalesce(new.raw_user_meta_data->>'name','')) on conflict(id) do nothing; insert into public.user_preferences(user_id) values(new.id) on conflict(user_id) do nothing; return new; end; $$;
drop trigger if exists on_auth_user_created on auth.users; create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();
alter table public.profiles enable row level security; alter table public.leads enable row level security; alter table public.lead_notes enable row level security; alter table public.lead_activities enable row level security; alter table public.deals enable row level security; alter table public.follow_ups enable row level security; alter table public.search_history enable row level security; alter table public.user_preferences enable row level security;
create policy "profiles own row" on public.profiles for all to authenticated using(id=auth.uid()) with check(id=auth.uid());
create policy "leads own rows" on public.leads for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "notes own rows" on public.lead_notes for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "activities own rows" on public.lead_activities for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "deals own rows" on public.deals for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "followups own rows" on public.follow_ups for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "search history own rows" on public.search_history for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "preferences own row" on public.user_preferences for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
grant usage on schema public to authenticated;
grant select,insert,update,delete on public.profiles,public.leads,public.lead_notes,public.lead_activities,public.deals,public.follow_ups,public.search_history,public.user_preferences to authenticated;
