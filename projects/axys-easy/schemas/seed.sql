-- ============================================================
-- AxysEasy — Seed inicial
-- Dados fixos de catálogo que o sistema pressupõe existirem.
-- Idempotente: ON CONFLICT DO UPDATE / DO NOTHING
-- ============================================================

-- ─── catalogo.tipos_insumo ────────────────────────────────────────
INSERT INTO catalogo.tipos_insumo (ti_codigo, ti_nome) VALUES
    ('MO',       'Mão de Obra'),
    ('EQUIP_AQ', 'Equipamento — Aquisição'),
    ('EQUIP_LOC','Equipamento — Locação'),
    ('MAT',      'Material'),
    ('SERV',     'Serviço'),
    ('ESP',      'Especiais')
ON CONFLICT (ti_codigo) DO NOTHING;

-- ─── catalogo.fontes ──────────────────────────────────────────────
-- fte_ordem_edicao:
--   'DATA'   — edição mais recente = maior edi_mes_ref
--   'VERSAO' — edição mais recente = maior edi_codigo_versao
INSERT INTO catalogo.fontes (fte_codigo, fte_nome, fte_ordem_edicao) VALUES
    ('SINAPI', 'SINAPI — Caixa Econômica Federal',                          'DATA'),
    ('CDHU',   'CDHU — Companhia de Desenvolvimento Habitacional e Urbano', 'VERSAO'),
    ('FDE',    'FDE — Fundação para o Desenvolvimento da Educação',         'DATA'),
    ('ORSE',   'ORSE — Orçamento de Obras de Sergipe',                      'DATA'),
    ('EMOP',   'EMOP — Empresa de Obras Públicas do Rio de Janeiro',        'DATA'),
    ('AXYS',   'AXYS — Composições Próprias',                               'DATA')
ON CONFLICT (fte_codigo) DO UPDATE
    SET fte_nome           = EXCLUDED.fte_nome,
        fte_ordem_edicao   = EXCLUDED.fte_ordem_edicao,
        fte_atualizado_em  = CURRENT_TIMESTAMP;

-- ─── catalogo.edicoes ─────────────────────────────────────────
-- Edições iniciais de referência (seed)
INSERT INTO catalogo.edicoes (edi_fte_id, edi_mes_ref, edi_codigo_versao, edi_uf_padrao, edi_criado_por)
SELECT fte_id, '2026-04-01'::DATE, NULL, 'SP', 'Axys — seed inicial' FROM catalogo.fontes WHERE fte_codigo = 'SINAPI'
UNION ALL
SELECT fte_id, '2026-02-01'::DATE, '201', 'SP', 'Axys — seed inicial' FROM catalogo.fontes WHERE fte_codigo = 'CDHU'
ON CONFLICT (edi_fte_id, edi_mes_ref) DO NOTHING;

-- ─── audit.logs_retencao ─────────────────────────────────────
INSERT INTO audit.logs_retencao (ret_descricao, ret_permanente, ret_dias) VALUES
    ('Permanente', true,  NULL),
    ('90 dias',    false,   90),
    ('180 dias',   false,  180),
    ('1 ano',      false,  365),
    ('2 anos',     false,  730),
    ('5 anos',     false, 1825)
ON CONFLICT DO NOTHING;

-- ─── audit.criterio_retencao ─────────────────────────────────
-- Schema catalogo: catálogo histórico — tudo permanente
INSERT INTO audit.criterio_retencao (crit_schema, crit_tabela, crit_ret_id)
SELECT v.sch, v.tab, lr.ret_id
FROM (VALUES
    ('catalogo', 'fontes'),
    ('catalogo', 'tipos_insumo'),
    ('catalogo', 'edicoes'),
    ('catalogo', 'grupos'),
    ('catalogo', 'subgrupos'),
    ('catalogo', 'insumos'),
    ('catalogo', 'precos_insumo'),
    ('catalogo', 'composicoes'),
    ('catalogo', 'composicao_itens'),
    ('catalogo', 'custos_composicao'),
    ('catalogo', 'sinapi_manutencoes')
) AS v(sch, tab)
CROSS JOIN audit.logs_retencao lr
WHERE lr.ret_descricao = 'Permanente'
ON CONFLICT (crit_schema, crit_tabela) DO NOTHING;
