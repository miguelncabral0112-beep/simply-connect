# Simply Connect
Plataforma SaaS de prospecção B2B para encontrar empresas reais, organizar leads e acompanhar o processo comercial.

## Stack
- React + TypeScript + TanStack Start
- Tailwind CSS v4 e Lucide
- Supabase Auth, PostgreSQL, RLS e Edge Functions
- Google Places API (New)
- WhatsApp por link oficial, contato manual

## Desenvolvimento local
```sh
bun install
cp .env.example .env
bun run dev
```
Configure `VITE_SUPABASE_URL` e `VITE_SUPABASE_ANON_KEY`. Nunca coloque service role do Supabase ou chave privada do Google em variáveis `VITE_*`.

## Supabase
1. Crie um projeto Supabase.
2. Execute `supabase/migrations/202610080001_init.sql` no SQL Editor.
3. Configure URL e chave anon/publishable no frontend.
4. Publique `supabase/functions/search-places`.
5. Configure o secret `GOOGLE_PLACES_API_KEY` e habilite Google Places API (New).

```sh
supabase secrets set GOOGLE_PLACES_API_KEY=YOUR_KEY
supabase functions deploy search-places
```

A busca exige usuário autenticado e usa a API oficial. A cobertura depende do provedor. Website vazio significa apenas “Site não informado no Google”, não prova ausência de site. RLS isola os dados por usuário. Abrir o WhatsApp não confirma envio. Sem credenciais, o app informa a configuração pendente em vez de inventar resultados.

A base inicial de busca e CRM está implementada. Histórico detalhado, tarefas agendadas, auditoria técnica de sites, exportação e métricas avançadas são etapas posteriores.
