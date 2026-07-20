# Cadastro Reserva CSPM 2025

Sistema web para gerenciar candidatos aprovados na prova objetiva do concurso para Capitão da Brigada Militar (CSPM 2025) que não foram convocados para a prova dissertativa.

## Arquivos

- **cadastro-reserva-cspm.html** - Interface web com:
  - Busca por nome ou matrícula
  - Filtro por modalidade (AC/PN)
  - Paginação
  - Modo admin com edição inline (requer login)
  - Movimentação de candidatos entre posições

- **supabase_schema.sql** - Schema do banco de dados Supabase com:
  - Tabela de candidatos
  - Row Level Security (RLS) para segurança
  - Política de leitura pública (qualquer pessoa vê)
  - Política de escrita apenas para usuários autenticados

- **supabase_seed.sql** - Dados iniciais com 1780 candidatos

## Setup

### 1. Criar projeto Supabase
1. Ir para https://supabase.com e criar uma conta
2. Criar um novo projeto
3. Copiar as credenciais (URL e Anon Key)

### 2. Configurar banco de dados
1. No Supabase, ir para SQL Editor
2. Copiar e colar o conteúdo de `supabase_schema.sql` e executar
3. Copiar e colar o conteúdo de `supabase_seed.sql` e executar para popular os dados

### 3. Configurar credenciais no HTML
1. Abrir `cadastro-reserva-cspm.html` em um editor de texto
2. Encontrar as linhas com:
   - `PREENCHER_SUPABASE_URL_AQUI`
   - `PREENCHER_SUPABASE_ANON_KEY_AQUI`
3. Substituir pelos valores do seu projeto Supabase

### 4. Deploy no Vercel (recomendado)
1. Fazer push do repositório para GitHub (já feito)
2. Ir para https://vercel.com e conectar o repositório
3. Vercel vai detectar automaticamente como um projeto estático
4. O site estará disponível em uma URL pública

## Funcionalidades

### Visualização pública
- Lista de candidatos aprovados na fase objetiva mas não convocados
- Busca por nome parcial ou matrícula exata
- Filtro por modalidade (AC - Ampla Concorrência / PN - Pessoas Negras)
- Paginação configurável

### Painel admin (com login)
- Edição de dados inline (clicar nas células)
- Movimentação de candidatos entre posições (botões ▲▼)
- Alterações são salvas no banco de dados em tempo real

## Segurança

- **Row Level Security (RLS)**: Configurado no Supabase
  - Qualquer um pode ler os dados (site é público)
  - Apenas usuários autenticados (com login) podem modificar
  - Impossível burlar abrindo DevTools (validação no servidor)

- **Login**: Email e senha configurados no Supabase Authentication

## Dados sempre atualizados

O HTML faz fetch dos dados **diretamente do Supabase** sempre que a página abre. Isso significa:
- Não há dados estáticos embutidos
- Qualquer edição no admin aparece para todos os visitantes imediatamente
- O arquivo `supabase_seed.sql` é executado uma única vez no setup

## Contato

Baseado em dados da Classificação Final com fórmula de desempate do concurso CSPM 2025.
