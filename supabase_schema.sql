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

-- Notas por materia (detalhamento da nota final de cada candidato).
-- Mesma logica de RLS da tabela candidatos: leitura publica, escrita so autenticado.
create table if not exists public.notas_materias (
    id bigint generated always as identity primary key,
    candidato_id bigint not null references public.candidatos(id) on delete cascade,
    materia text not null,
    nota numeric,
    ordem integer not null default 0
);

create index if not exists notas_materias_candidato_idx on public.notas_materias (candidato_id);

-- Impede duplicar a mesma materia para o mesmo candidato (ex.: rodar um
-- arquivo de seed duas vezes por engano) e permite corrigir com ON CONFLICT.
alter table public.notas_materias
    drop constraint if exists notas_materias_candidato_materia_key;
alter table public.notas_materias
    add constraint notas_materias_candidato_materia_key unique (candidato_id, materia);

alter table public.notas_materias enable row level security;

drop policy if exists "Leitura publica" on public.notas_materias;
create policy "Leitura publica"
    on public.notas_materias
    for select
    using (true);

drop policy if exists "Escrita somente autenticado" on public.notas_materias;
create policy "Escrita somente autenticado"
    on public.notas_materias
    for all
    using (auth.role() = 'authenticated')
    with check (auth.role() = 'authenticated');

-- Autocadastro publico de telefone/cidade (o candidato preenche sem login).
-- Ao contrario das tabelas acima, aqui e o publico que precisa GRAVAR (insert),
-- mas ninguem sem login pode LER (protege telefone/cidade de todo mundo).
create table if not exists public.atualizacoes_contato (
    id bigint generated always as identity primary key,
    candidato_id bigint not null references public.candidatos(id) on delete cascade,
    telefone text not null,
    cidade text not null,
    created_at timestamptz not null default now()
);

-- Um cadastro por candidato; tentar inserir de novo gera erro de unicidade
-- (codigo 23505), que o site usa para mostrar "candidato ja possui cadastro".
alter table public.atualizacoes_contato
    drop constraint if exists atualizacoes_contato_candidato_key;
alter table public.atualizacoes_contato
    add constraint atualizacoes_contato_candidato_key unique (candidato_id);

alter table public.atualizacoes_contato enable row level security;

drop policy if exists "Insercao publica" on public.atualizacoes_contato;
create policy "Insercao publica"
    on public.atualizacoes_contato
    for insert
    with check (true);

drop policy if exists "Leitura e gestao somente autenticado" on public.atualizacoes_contato;
create policy "Leitura e gestao somente autenticado"
    on public.atualizacoes_contato
    for all
    using (auth.role() = 'authenticated')
    with check (auth.role() = 'authenticated');

-- Relatos publicos de divergencia na lista de classificacao (botao "Lista").
-- Mesma logica de RLS de atualizacoes_contato: qualquer um pode enviar,
-- so o admin autenticado pode ler.
create table if not exists public.solicitacoes_alteracao (
    id bigint generated always as identity primary key,
    candidato_id bigint not null references public.candidatos(id) on delete cascade,
    motivo text not null,
    created_at timestamptz not null default now()
);

-- Adiciona a coluna caso a tabela ja existisse de uma versao anterior deste
-- script (o "create table if not exists" acima nao alteraria uma tabela ja
-- existente para incluir essa coluna).
alter table public.solicitacoes_alteracao
    add column if not exists status text not null default 'pendente';

alter table public.solicitacoes_alteracao
    drop constraint if exists solicitacoes_alteracao_status_check;
alter table public.solicitacoes_alteracao
    add constraint solicitacoes_alteracao_status_check check (status in ('pendente', 'resolvido'));

alter table public.solicitacoes_alteracao enable row level security;

drop policy if exists "Insercao publica" on public.solicitacoes_alteracao;
create policy "Insercao publica"
    on public.solicitacoes_alteracao
    for insert
    with check (true);

drop policy if exists "Leitura e gestao somente autenticado" on public.solicitacoes_alteracao;
create policy "Leitura e gestao somente autenticado"
    on public.solicitacoes_alteracao
    for all
    using (auth.role() = 'authenticated')
    with check (auth.role() = 'authenticated');

-- Habilita Realtime (atualizacoes ao vivo) na tabela de autocadastro de
-- contato. E o que faz o "Mapa por cidade" (painel admin) atualizar as
-- contagens sozinho conforme os candidatos vao se autocadastrando, sem
-- precisar recarregar a pagina. Bloco idempotente: pode rodar de novo sem
-- erro mesmo se a tabela ja estiver na publicacao.
do $$
begin
    if not exists (
        select 1 from pg_publication_tables
        where pubname = 'supabase_realtime'
          and schemaname = 'public'
          and tablename = 'atualizacoes_contato'
    ) then
        alter publication supabase_realtime add table public.atualizacoes_contato;
    end if;
end $$;
