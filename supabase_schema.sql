-- Execute este script primeiro no SQL Editor do Supabase.
-- Cria a tabela, ativa Row Level Security (RLS) e define as regras de acesso:
--   - Qualquer pessoa pode LER (SELECT) a lista (o site é público).
--   - Só um usuário autenticado (logado) pode INSERIR, ATUALIZAR ou EXCLUIR.
-- Essa checagem roda dentro do banco de dados (Postgres), não no navegador,
-- então não pode ser burlada abrindo o F12 do navegador.

create table if not exists public.candidatos (
    id bigint generated always as identity primary key,
    ordem integer not null,
    nome text not null,
    matricula text not null default '',
    modalidade text not null check (modalidade in ('AC','PN')),
    nota numeric,
    acertos integer,
    created_at timestamptz not null default now()
);

create index if not exists candidatos_ordem_idx on public.candidatos (ordem);

alter table public.candidatos enable row level security;

-- Qualquer visitante (mesmo sem login) pode ver a lista
drop policy if exists "Leitura publica" on public.candidatos;
create policy "Leitura publica"
    on public.candidatos
    for select
    using (true);

-- Só usuários logados (autenticados) podem alterar
drop policy if exists "Escrita somente autenticado" on public.candidatos;
create policy "Escrita somente autenticado"
    on public.candidatos
    for all
    using (auth.role() = 'authenticated')
    with check (auth.role() = 'authenticated');
