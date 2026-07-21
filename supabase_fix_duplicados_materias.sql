-- Execute este script ANTES de rodar supabase_schema.sql de novo.
-- Remove notas de materia duplicadas (mesmo candidato + mesma materia),
-- mantendo apenas a linha de menor id (a primeira que foi inserida).
-- Isso corrige o caso em que um arquivo de seed (ex.: supabase_seed_materias_01.sql)
-- foi colado e executado mais de uma vez por engano.

delete from public.notas_materias a
using public.notas_materias b
where a.id > b.id
  and a.candidato_id = b.candidato_id
  and a.materia = b.materia;
