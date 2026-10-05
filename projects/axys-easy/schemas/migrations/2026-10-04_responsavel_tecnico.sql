-- AxysEasy — Responsável Técnico: cadastro do tenant e quem assina cada empreendimento/ativo.
--
-- O QUE CRIA
--   catalogo.conselhos_classe               CREA / CAU / CRT (domínio da Axys, semeado)
--   catalogo.doc_resp_tecnica               ART / RRT / TRT (idem)
--   catalogo.profissoes                     recorte construção/infra por conselho (idem)
--   tenant_catalogo.responsaveis_tecnicos   cadastro, reusado pelo tenant inteiro (como unidade e fonte)
--   ativo.empreendimento_responsaveis       quem assina o empreendimento (N:N, com ordem)
--   ativo.ativo_responsaveis                quem assina o ativo (N:N, com ordem)
--   ativo.ativos.atv_rt_herda               TRUE = o ativo usa a equipe do empreendimento
--
-- SEGURO DE APLICAR, e vale dizer por quê:
--   · tudo é criação nova — nenhuma tabela existente muda de forma;
--   · a única coluna acrescentada tem DEFAULT TRUE e NOT NULL, então as linhas existentes já
--     nascem corretas (herdar é o comportamento desejado para quem nunca escolheu nada);
--   · NADA é obrigatório: sem RT, o documento sai sem bloco de assinatura. Aplicar esta migração
--     não altera nenhum documento já emitido.
--   · não exige deploy coordenado: sem o código novo, as tabelas ficam vazias e ninguém as lê.
--
-- POR QUE `ordem` EXISTE. Bloco de assinatura é sequência. Sem a coluna, o Postgres não promete
-- ordem alguma e o mesmo documento sairia com os nomes trocados entre dois renders.
--
-- POR QUE NÃO HÁ user_uuid. O Hub é dono dos usuários e não expõe "listar usuários do tenant".
-- Coluna apontando para o que não se consulta é FK fantasma — entra por ALTER no dia em que o
-- Hub expuser.
--
-- IDEMPOTENTE E SEGURA DE REEXECUTAR. A primeira versão deste arquivo (04/10, manhã) guardava o
-- documento profissional como texto solto; esta guarda em três partes (conselho, UF, número).
-- Os ALTERs cobrem os dois casos: banco virgem e banco que já rodou a versão anterior.
--
-- Fonte da verdade: docs/projects/axys-easy/schemas/schema.sql (blocos "CONSELHO DE CLASSE",
-- "RESPONSÁVEL TÉCNICO" e "QUEM ASSINA"). Aplicado em dev em 2026-10-04.

BEGIN;

CREATE TABLE IF NOT EXISTS catalogo.conselhos_classe (
    ccl_codigo TEXT PRIMARY KEY,
    ccl_nome   TEXT    NOT NULL,
    ccl_ordem  INTEGER NOT NULL DEFAULT 0
);
INSERT INTO catalogo.conselhos_classe (ccl_codigo, ccl_nome, ccl_ordem) VALUES
    ('CREA', 'CONSELHO REGIONAL DE ENGENHARIA E AGRONOMIA', 1),
    ('CAU',  'CONSELHO DE ARQUITETURA E URBANISMO',         2),
    ('CRT',  'CONSELHO REGIONAL DOS TÉCNICOS INDUSTRIAIS',  3)
ON CONFLICT (ccl_codigo) DO NOTHING;

CREATE TABLE IF NOT EXISTS catalogo.profissoes (
    prf_codigo   TEXT PRIMARY KEY,                -- ENG_CIVIL, ARQ_URB, TEC_EDIF…
    prf_nome     TEXT NOT NULL,                   -- como vai no bloco de assinatura
    prf_conselho TEXT NOT NULL REFERENCES catalogo.conselhos_classe (ccl_codigo),
    -- SUPERIOR × MEDIO explícito: "Tecnólogo em Edificações" (superior, CREA) e "Técnico em
    -- Edificações" (médio, CRT) são profissões distintas e o prefixo sozinho não deixa isso
    -- consultável. A tela agrupa a listbox por nível.
    prf_nivel    TEXT NOT NULL DEFAULT 'SUPERIOR',
    prf_ordem    INTEGER NOT NULL DEFAULT 0,
    prf_ativa    BOOLEAN NOT NULL DEFAULT TRUE,   -- some da listbox sem sumir de quem já a usa

    CONSTRAINT uq_prf_conselho_nome UNIQUE (prf_conselho, prf_nome),
    CONSTRAINT ck_prf_nivel CHECK (prf_nivel IN ('SUPERIOR', 'MEDIO'))
);

-- Recorte: construção civil e infraestrutura. NÃO é a lista completa dos conselhos — é a fatia
-- que aparece em projeto e obra. Quem define atribuição é o conselho (Res. CONFEA 218/1973 e
-- sucessoras, Lei 12.378/2010 para o CAU, Lei 13.639/2018 para o CFT); esta tabela é só o
-- vocabulário da app, para o usuário escolher em vez de digitar.
-- a coluna precisa existir ANTES do seed que a preenche (a tabela pode já existir)
ALTER TABLE catalogo.profissoes
    ADD COLUMN IF NOT EXISTS prf_nivel TEXT NOT NULL DEFAULT 'SUPERIOR';
UPDATE catalogo.profissoes SET prf_nivel = 'MEDIO' WHERE prf_conselho = 'CRT' AND prf_nivel <> 'MEDIO';

INSERT INTO catalogo.profissoes (prf_codigo, prf_nome, prf_conselho, prf_nivel, prf_ordem) VALUES
    ('ENG_CIVIL',      'Engenheiro Civil',                      'CREA', 'SUPERIOR',  1),
    ('ENG_ELET',       'Engenheiro Eletricista',                'CREA', 'SUPERIOR',  2),
    ('ENG_MEC',        'Engenheiro Mecânico',                   'CREA', 'SUPERIOR',  3),
    ('ENG_AMB',        'Engenheiro Ambiental',                  'CREA', 'SUPERIOR',  4),
    ('ENG_SANIT',      'Engenheiro Sanitarista',                'CREA', 'SUPERIOR',  5),
    ('ENG_SEG_TRAB',   'Engenheiro de Segurança do Trabalho',   'CREA', 'SUPERIOR',  6),
    ('ENG_AGRIM',      'Engenheiro Agrimensor',                 'CREA', 'SUPERIOR',  7),
    ('ENG_CARTOG',     'Engenheiro Cartógrafo',                 'CREA', 'SUPERIOR',  8),
    ('ENG_GEOL',       'Engenheiro Geólogo',                    'CREA', 'SUPERIOR',  9),
    ('GEOLOGO',        'Geólogo',                               'CREA', 'SUPERIOR', 10),
    ('ENG_MINAS',      'Engenheiro de Minas',                   'CREA', 'SUPERIOR', 11),
    ('ENG_HIDRICO',    'Engenheiro Hídrico',                    'CREA', 'SUPERIOR', 12),
    ('ENG_FLOREST',    'Engenheiro Florestal',                  'CREA', 'SUPERIOR', 13),
    ('ENG_AGRON',      'Engenheiro Agrônomo',                   'CREA', 'SUPERIOR', 14),
    ('ENG_PROD',       'Engenheiro de Produção',                'CREA', 'SUPERIOR', 15),
    ('ENG_MATER',      'Engenheiro de Materiais',               'CREA', 'SUPERIOR', 16),
    ('ENG_QUIM',       'Engenheiro Químico',                    'CREA', 'SUPERIOR', 17),
    ('ENG_ELETRON',    'Engenheiro Eletrônico',                 'CREA', 'SUPERIOR', 18),
    ('ENG_TELECOM',    'Engenheiro de Telecomunicações',        'CREA', 'SUPERIOR', 19),
    ('TGO_CONST',      'Tecnólogo em Construção Civil',         'CREA', 'SUPERIOR', 20),
    ('TGO_EDIF',       'Tecnólogo em Edificações',              'CREA', 'SUPERIOR', 21),
    ('TGO_ESTRADAS',   'Tecnólogo em Estradas',                 'CREA', 'SUPERIOR', 22),
    ('TGO_SANEAM',     'Tecnólogo em Saneamento Ambiental',     'CREA', 'SUPERIOR', 23),
    ('TGO_ELETROT',    'Tecnólogo em Eletrotécnica',            'CREA', 'SUPERIOR', 24),
    ('TGO_MEC',        'Tecnólogo em Mecânica',                 'CREA', 'SUPERIOR', 25),
    ('ARQ_URB',        'Arquiteto e Urbanista',                 'CAU', 'SUPERIOR',   1),
    ('TEC_EDIF',       'Técnico em Edificações',                'CRT', 'MEDIO',   1),
    ('TEC_ELETROT',    'Técnico em Eletrotécnica',              'CRT', 'MEDIO',   2),
    ('TEC_ESTRADAS',   'Técnico em Estradas',                   'CRT', 'MEDIO',   3),
    ('TEC_SANEAM',     'Técnico em Saneamento',                 'CRT', 'MEDIO',   4),
    ('TEC_SEG_TRAB',   'Técnico em Segurança do Trabalho',      'CRT', 'MEDIO',   5),
    ('TEC_MEC',        'Técnico em Mecânica',                   'CRT', 'MEDIO',   6),
    ('TEC_AGRIM',      'Técnico em Agrimensura',                'CRT', 'MEDIO',   7),
    ('TEC_GEOL',       'Técnico em Geologia',                   'CRT', 'MEDIO',   8),
    ('TEC_MINER',      'Técnico em Mineração',                  'CRT', 'MEDIO',   9),
    ('TEC_REFRIG',     'Técnico em Refrigeração e Climatização', 'CRT', 'MEDIO', 10),
    ('TEC_AUTOM',      'Técnico em Automação Industrial',       'CRT', 'MEDIO',  11),
    ('TEC_ELETRON',    'Técnico em Eletrônica',                 'CRT', 'MEDIO',  12),
    ('TEC_MEIO_AMB',   'Técnico em Meio Ambiente',              'CRT', 'MEDIO',  13)
ON CONFLICT (prf_codigo) DO NOTHING;

CREATE INDEX IF NOT EXISTS ix_prf_conselho ON catalogo.profissoes (prf_conselho, prf_ordem)
    WHERE prf_ativa;

CREATE TABLE IF NOT EXISTS catalogo.doc_resp_tecnica (
    drt_codigo TEXT PRIMARY KEY,
    drt_nome   TEXT    NOT NULL,
    drt_ordem  INTEGER NOT NULL DEFAULT 0
);
INSERT INTO catalogo.doc_resp_tecnica (drt_codigo, drt_nome, drt_ordem) VALUES
    ('ART', 'ANOTAÇÃO DE RESPONSABILIDADE TÉCNICA', 1),
    ('RRT', 'REGISTRO DE RESPONSABILIDADE TÉCNICA', 2),
    ('TRT', 'TERMO DE RESPONSABILIDADE TÉCNICA',    3)
ON CONFLICT (drt_codigo) DO NOTHING;

CREATE TABLE IF NOT EXISTS tenant_catalogo.responsaveis_tecnicos (
    rt_id                     INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    rt_tenant_uuid            UUID    NOT NULL,
    rt_nome                   TEXT    NOT NULL,
    rt_profissao              TEXT REFERENCES catalogo.profissoes (prf_codigo),
    rt_conselho               TEXT NOT NULL REFERENCES catalogo.conselhos_classe (ccl_codigo),
    rt_conselho_uf            CHAR(2),
    rt_documento              TEXT,
    rt_ativo                  BOOLEAN NOT NULL DEFAULT TRUE,
    rt_criado_em              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rt_atualizado_em          TIMESTAMPTZ,
    rt_criado_por             TEXT,
    rt_atualizado_por         TEXT,

    CONSTRAINT ck_tcrt_nome CHECK (btrim(rt_nome) <> '')
);

-- Para quem já rodou a versão anterior deste arquivo:
ALTER TABLE tenant_catalogo.responsaveis_tecnicos
    ADD COLUMN IF NOT EXISTS rt_profissao   TEXT REFERENCES catalogo.profissoes (prf_codigo),
    ADD COLUMN IF NOT EXISTS rt_conselho    TEXT REFERENCES catalogo.conselhos_classe (ccl_codigo),
    ADD COLUMN IF NOT EXISTS rt_conselho_uf CHAR(2),
    ADD COLUMN IF NOT EXISTS rt_documento   TEXT,
    DROP COLUMN IF EXISTS rt_documento_profissional,
    DROP COLUMN IF EXISTS rt_formacao;

-- Conselho é OBRIGATÓRIO. O NOT NULL entra depois do ADD porque a coluna pode ter nascido nula
-- na versão anterior deste arquivo; se houver linha sem conselho, isto falha e é o certo —
-- preencher é decisão de quem tem o dado, não minha.
-- NOT NULL e CHECKs: o formulário exige, e o banco também — para o dia em que alguém mexer na
-- tela e esquecer a validação. Se houver linha incompleta, isto FALHA, e falhar é o certo:
-- completar é decisão de quem tem o dado.
ALTER TABLE tenant_catalogo.responsaveis_tecnicos
    ALTER COLUMN rt_conselho    SET NOT NULL,
    ALTER COLUMN rt_profissao   SET NOT NULL,
    ALTER COLUMN rt_conselho_uf SET NOT NULL,
    ALTER COLUMN rt_documento   SET NOT NULL;

ALTER TABLE tenant_catalogo.responsaveis_tecnicos
    DROP CONSTRAINT IF EXISTS ck_tcrt_documento,
    DROP CONSTRAINT IF EXISTS ck_tcrt_uf;
ALTER TABLE tenant_catalogo.responsaveis_tecnicos
    ADD CONSTRAINT ck_tcrt_documento CHECK (btrim(rt_documento) <> ''),
    ADD CONSTRAINT ck_tcrt_uf CHECK (rt_conselho_uf = 'BR' OR rt_conselho_uf ~ '^[A-Z]{2}$');

CREATE INDEX IF NOT EXISTS ix_tcrt_tenant
    ON tenant_catalogo.responsaveis_tecnicos (rt_tenant_uuid) WHERE rt_ativo;

ALTER TABLE ativo.ativos
    ADD COLUMN IF NOT EXISTS atv_rt_herda BOOLEAN NOT NULL DEFAULT TRUE;

CREATE TABLE IF NOT EXISTS ativo.empreendimento_responsaveis (
    empr_emp_id  INTEGER NOT NULL,
    empr_rt_id   INTEGER NOT NULL,
    empr_ordem   INTEGER NOT NULL DEFAULT 1,
    empr_tipo_doc TEXT REFERENCES catalogo.doc_resp_tecnica (drt_codigo),
    empr_num_doc  TEXT,

    PRIMARY KEY (empr_emp_id, empr_rt_id),
    CONSTRAINT fk_empr_emp FOREIGN KEY (empr_emp_id)
        REFERENCES ativo.empreendimentos (emp_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_empr_rt  FOREIGN KEY (empr_rt_id)
        REFERENCES tenant_catalogo.responsaveis_tecnicos (rt_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS ativo.ativo_responsaveis (
    atvr_atv_id  INTEGER NOT NULL,
    atvr_rt_id   INTEGER NOT NULL,
    atvr_ordem   INTEGER NOT NULL DEFAULT 1,
    atvr_tipo_doc TEXT REFERENCES catalogo.doc_resp_tecnica (drt_codigo),
    atvr_num_doc  TEXT,

    PRIMARY KEY (atvr_atv_id, atvr_rt_id),
    CONSTRAINT fk_atvr_atv FOREIGN KEY (atvr_atv_id)
        REFERENCES ativo.ativos (atv_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_atvr_rt  FOREIGN KEY (atvr_rt_id)
        REFERENCES tenant_catalogo.responsaveis_tecnicos (rt_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

ALTER TABLE ativo.empreendimento_responsaveis
    ADD COLUMN IF NOT EXISTS empr_tipo_doc TEXT REFERENCES catalogo.doc_resp_tecnica (drt_codigo),
    ADD COLUMN IF NOT EXISTS empr_num_doc  TEXT;
ALTER TABLE ativo.ativo_responsaveis
    ADD COLUMN IF NOT EXISTS atvr_tipo_doc TEXT REFERENCES catalogo.doc_resp_tecnica (drt_codigo),
    ADD COLUMN IF NOT EXISTS atvr_num_doc  TEXT;

COMMIT;

-- Conferência: deve devolver 3 tabelas e a coluna.
-- SELECT table_schema||'.'||table_name FROM information_schema.tables
--  WHERE (table_schema,table_name) IN (('tenant_catalogo','responsaveis_tecnicos'),
--        ('ativo','empreendimento_responsaveis'),('ativo','ativo_responsaveis'));
-- SELECT column_name FROM information_schema.columns
--  WHERE table_schema='ativo' AND table_name='ativos' AND column_name='atv_rt_herda';
