-- =====================================================================
-- 04 - Popula a dim_tempo (2015-01-01 a 2035-12-31). Idempotente.
-- =====================================================================
INSERT INTO dw.dim_tempo (sk_tempo, data, ano, semestre, trimestre, mes, nome_mes, ano_mes,
                          dia, dia_semana, nome_dia_semana, fim_de_semana)
SELECT
    to_char(d, 'YYYYMMDD')::int,
    d::date,
    EXTRACT(YEAR FROM d)::smallint,
    CASE WHEN EXTRACT(MONTH FROM d) <= 6 THEN 1 ELSE 2 END,
    EXTRACT(QUARTER FROM d)::smallint,
    EXTRACT(MONTH FROM d)::smallint,
    (ARRAY['Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto',
           'Setembro','Outubro','Novembro','Dezembro'])[EXTRACT(MONTH FROM d)::int],
    to_char(d, 'YYYY-MM'),
    EXTRACT(DAY FROM d)::smallint,
    EXTRACT(ISODOW FROM d)::smallint,
    (ARRAY['Segunda','Terça','Quarta','Quinta','Sexta','Sábado','Domingo'])[EXTRACT(ISODOW FROM d)::int],
    EXTRACT(ISODOW FROM d) IN (6, 7)
FROM generate_series('2015-01-01'::date, '2035-12-31'::date, interval '1 day') AS d
ON CONFLICT (sk_tempo) DO NOTHING;
