# Cadastro Reserva CSPM 2025

Sistema web para gerenciar candidatos aprovados na prova objetiva do concurso para Capitão da Brigada Militar (CSPM 2025) que não foram convocados para a prova dissertativa.

## Arquivos

- **index.html** - Interface web com:
  - Visual "premium" com paleta verde/dourado/bordô extraída do brasão da Brigada Militar (era azul/roxo genérico)
  - Tela inicial com o brasão em destaque (moldura dourada), número de "Aprovados" em destaque, cartões AC/PN lado a lado e um bloco com as datas oficiais do concurso (edital de abertura, homologação, validade e possível renovação), além do botão para entrar na lista de aprovados
  - Busca por nome ou matrícula
  - Filtro por modalidade (AC/PN)
  - Paginação
  - Modo admin com edição inline (requer login)
  - Movimentação de candidatos entre posições
  - Nota clicável, abre modal com o detalhamento por matéria (editável pelo admin)
  - 3 botões de destaque logo abaixo do título da lista (com dica ao passar o mouse):
    - **Meus dados**: o candidato busca o próprio nome, confirma visualmente (nome + matrícula exibidos) que é ele e informa telefone/cidade
    - **Lista**: o candidato aponta uma divergência na classificação de algum candidato, com campo de motivo
    - **Administrador**: login/logout do administrador
  - Aba "Ver cadastros atualizados" (só admin): lista os telefones/cidades e as solicitações de alteração recebidas, cada uma com botão de exportar em CSV

- **supabase_schema.sql** - Schema do banco de dados Supabase com:
  - Tabela de candidatos
  - Tabela de notas por matéria (`notas_materias`), ligada a cada candidato
  - Tabela de autocadastro de contato (`atualizacoes_contato`): telefone/cidade enviados pelo próprio candidato
  - Tabela de solicitações de alteração na lista (`solicitacoes_alteracao`): motivo enviado pelo candidato sobre algum registro da lista
  - Row Level Security (RLS) para segurança em todas as tabelas
  - Política de leitura pública (qualquer pessoa vê) nas tabelas de candidatos/notas
  - Política de escrita apenas para usuários autenticados nas tabelas de candidatos/notas
  - Em `atualizacoes_contato` e `solicitacoes_alteracao` a regra é invertida: qualquer um pode enviar (inserir), mas só o admin autenticado pode ler/exportar esses dados

- **supabase_seed.sql** - Dados iniciais com 1780 candidatos
- **supabase_seed_materias_01.sql** a **supabase_seed_materias_06.sql** - Notas por matéria (10 matérias x 1780 candidatos), extraídas da planilha de classificação final. Divididos em 6 arquivos menores porque o editor SQL do Supabase tem limite de tamanho de consulta.
- **supabase_fix_duplicados_materias.sql** - Script de correção pontual: remove notas de matéria duplicadas caso algum dos arquivos de seed acima tenha sido executado mais de uma vez por engano

## Setup

### 1. Criar projeto Supabase
1. Ir para https://supabase.com e criar uma conta
2. Criar um novo projeto
3. Copiar as credenciais (URL e Anon Key)

### 2. Configurar banco de dados
1. No Supabase, ir para SQL Editor
2. Copiar e colar o conteúdo de `supabase_schema.sql` e executar
3. Copiar e colar o conteúdo de `supabase_seed.sql` e executar para popular os dados
4. Copiar e colar o conteúdo de cada um dos arquivos `supabase_seed_materias_01.sql` até `supabase_seed_materias_06.sql`, em ordem, e executar um de cada vez (depende do passo anterior já ter rodado). **Execute cada arquivo uma única vez** — rodar o mesmo arquivo de novo duplica as notas daquele lote.

Se por engano algum arquivo de matérias foi executado mais de uma vez (notas aparecendo dobradas/triplicadas no modal), rode `supabase_fix_duplicados_materias.sql` para remover as duplicatas e depois rode `supabase_schema.sql` de novo — ele agora adiciona uma trava (`unique constraint`) que impede duplicidade futura.

### 3. Configurar credenciais no HTML
1. Abrir `index.html` em um editor de texto
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
- Clicar na nota abre um modal com a nota final e o detalhamento por matéria, com campos editáveis
- Alterações são salvas no banco de dados em tempo real
- Dois botões, visíveis só quando logado, cada um abrindo uma página própria:
  - "Cadastros de contato": telefone/cidade enviados pelo autocadastro público
  - "Solicitações de alteração": divergências reportadas na lista, separadas em Pendentes/Resolvidas, com botão para marcar como resolvida ou reabrir
  - Cada página tem seu próprio botão de exportar em CSV
- **Ambas as listas (telefone/cidade e solicitações de alteração) só ficam visíveis para o administrador logado** — o público nunca consegue ler esses dados, nem pelo F12

### Meus dados (público, sem login)
- Botão "Meus dados" logo abaixo do título da lista
- O candidato digita o nome, escolhe o seu na lista sugerida, confirma visualmente (vê nome + matrícula exibidos e clica em "Sim, sou eu") e informa telefone e cidade
- Se o candidato já tiver enviado esses dados antes, o sistema mostra: "Candidato já possui cadastro, entre em contato com o administrador da página." (checagem feita pelo próprio banco de dados, via trava de unicidade)

### Lista (público, sem login)
- Botão "Lista" logo abaixo do título da lista
- O candidato busca e seleciona um candidato da classificação e escreve o motivo/observação sobre uma possível divergência
- Mensagem enviada direto para a área do administrador (não fica visível publicamente)

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
