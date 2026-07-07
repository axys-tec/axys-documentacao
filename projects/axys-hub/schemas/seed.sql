-- ============================================================
-- AxysHub — Seed Inicial
-- Referência canônica: ADR-011
-- Banco: PostgreSQL 14+ — schema public
--
-- Idempotente: ON CONFLICT em todos os INSERTs.
-- Seguro para rodar em produção sem risco de sobrescrever
-- dados sensíveis (senhas, tokens).
--
-- ATENÇÃO — CPFs placeholder:
--   Os campos cpf dos usuários estão preenchidos com valores
--   fictícios (00000000XXX). Atualizar com CPFs reais via:
--     UPDATE hub_user SET cpf = '<cpf>' WHERE email = '<email>';
--
-- ATENÇÃO — Senha padrão de seed:
--   password_hash gerado de 'axys@seed2026' com bcrypt (bf/10).
--   ON CONFLICT (email) DO NOTHING garante que senhas existentes
--   em produção nunca são sobrescritas.
-- ============================================================


-- ─── hub_sistema ─────────────────────────────────────────────
-- Catálogo de sistemas do ecossistema Axys.
-- sha256_key: não alterar — chave de validação criptográfica.
INSERT INTO hub_sistema (sistema_id, sistema_code, nome, tipo, sha256_key, status)
VALUES
    (gen_random_uuid(), 'AXYSPRO',            'AxysPro',            'suite',    '716f845961260056ec1918d9dc19816cedbb91328aaf796217b9e1a41a6e27e7', 'active'),
    (gen_random_uuid(), 'AXYSGESTOR',         'AxysGestor',         'microapp', 'ff07ba8dc2c1df2dc5274987330e725bd7e55aa3227926affb2fa6eff531e498', 'active'),
    (gen_random_uuid(), 'EASYCPU',            'EasyCPU',            'microapp', 'aa0e6a2c5ab55942079a1f04e77e799f72a985c2dc5c1d1593b639c0d6fb255b', 'active'),
    (gen_random_uuid(), 'EASYORCA',           'EasyOrça',           'microapp', '92ea1795d5cd591833de60267d0fb8a3211ee73f09c576174aca6d8a7e290017', 'active'),
    (gen_random_uuid(), 'EASYPRICE',          'EasyPrice',          'microapp', 'a9b60a18d72d64302d89e2439ca6e39088691ebb196edc85c62db3d34ac10f1b', 'active'),
    (gen_random_uuid(), 'EASYPRICE2',         'EasyPrice 2',        'microapp', 'ede2cad7b3182c50aafbc14f3d2436b8503849510451d4e7d35538028c6acad7', 'active'),
    (gen_random_uuid(), 'EASYPROJECTMANAGER', 'EasyProjectManager', 'microapp', 'c38467348d496d98d8b940c4f3673290d1578f55bf7031e49203b80f476d5933', 'active'),
    (gen_random_uuid(), 'EASYBUILDDIARY',     'EasyBuildDiary',     'microapp', 'a548b6d9eeb2768bee8dfa52d30694dd371dee8d9050ac7560b35f9b59835108', 'active'),
    (gen_random_uuid(), 'EASYLICITPLAN',      'EasyLicitPlan',      'microapp', 'd7859b2ba5d72c319edbc1e4e375dc90c9dcf842c7e34250ce1c9c802dbc0940', 'active'),
    (gen_random_uuid(), 'EASYFINCONTROL',     'EasyFinControl',     'microapp', 'ed0d71917d5f859bbe2edde5b86fcaf7dc4a3547fddcab47091f05814cbd64d2', 'active'),
    (gen_random_uuid(), 'EASYDOCS',           'EasyDocs',           'microapp', '01039ad782510d90cde942e71d38a2d95e8c0b39e2596c8e626e74c941ebb006', 'active')
ON CONFLICT (sistema_code) DO UPDATE SET
    nome       = EXCLUDED.nome,
    tipo       = EXCLUDED.tipo,
    status     = EXCLUDED.status;


-- ─── hub_tenant ──────────────────────────────────────────────
-- Tenants canônicos do ecossistema.
-- document: CNPJ (14 dígitos) ou CPF (11 dígitos), sem máscara.
INSERT INTO hub_tenant (tenant_id, tenant_code, tenant_name, document, status)
VALUES
    ('7847231a-4ba3-5138-b2d6-6943beb8e3f9', 'AXYS',   'Axys Engenharia e Tecnologia Ltda', '38060729810',    'active'),
    ('9b1c7c20-2a4c-5b76-9f72-0e9a4f2d4c8f', 'LUNALO', 'Lunalô Calçados e Perfumaria Ltda', '45580611000194', 'active'),
    ('d47aef9a-299d-5b8a-9fa2-b58a6050a4b0', 'DCENG',  'Dias & Cardozo Engenharia Ltda',    '17695703000184', 'active')
ON CONFLICT (tenant_code) DO UPDATE SET
    tenant_name = EXCLUDED.tenant_name,
    document    = EXCLUDED.document;


-- ─── hub_user ────────────────────────────────────────────────
-- Usuários canônicos.
-- password_hash: bcrypt de 'axys@seed2026' — trocar em produção.
-- cpf: placeholder (00000000XXX) — substituir com CPFs reais.
-- ON CONFLICT DO NOTHING: nunca sobrescreve senha em produção.
INSERT INTO hub_user (
    user_id,
    name,
    email,
    password_hash,
    cpf,
    address_json,
    sys_role,
    locale,
    status,
    is_active
)
VALUES
    (
        'a40bdb6c-c47b-5ad0-bb36-8c89641005e7',
        'Renan Dias',
        'rdias07@live.com',
        crypt('axys@seed2026', gen_salt('bf', 10)),
        '00000000001',  -- placeholder — substituir
        '{}',
        'hub_admin',
        'pt-BR',
        'active',
        TRUE
    ),
    (
        '279ae6ae-52e1-52e0-ad90-df80cbf5cd1b',
        'Thaís',
        'thays_hernandes@hotmail.com',
        crypt('Rt-16071506', gen_salt('bf', 10)),
        '00000000003',  -- placeholder — substituir
        '{}',
        'user',
        'pt-BR',
        'active',
        TRUE
    ),
    (
        '733fa25d-157e-596f-9f86-4ad8db423881',
        'Dias e Cardozo',
        'diasecardozo@diasecardozo.com.br',
        crypt('Rt-16071506', gen_salt('bf', 10)),
        '00000000002',  -- placeholder — substituir
        '{}',
        'user',
        'pt-BR',
        'active',
        TRUE
    ),
    (
        '83557f7e-e3f4-4002-a543-f09cc681f9ae',
        'Lunalô Calcados',
        'lunalocalcados@hotmail.com',
        crypt('Rt-16071506', gen_salt('bf', 10)),
        '00000000004',  -- placeholder — substituir
        '{}',
        'user',
        'pt-BR',
        'active',
        TRUE
    )
ON CONFLICT (email) DO NOTHING;


-- ─── hub_user_tenant ─────────────────────────────────────────
-- Vínculos usuário ↔ tenant com roles locais.
INSERT INTO hub_user_tenant (tenant_id, user_id, role, is_active)
SELECT t.tenant_id, u.user_id, v.role, TRUE
FROM (VALUES
    ('AXYS',   'rdias07@live.com',                 'internal_owner'),
    ('AXYS',   'thays_hernandes@hotmail.com',      'internal_user'),
    ('LUNALO', 'thays_hernandes@hotmail.com',       'admin'),
    ('LUNALO', 'lunalocalcados@hotmail.com',        'admin'),
    ('DCENG',  'rdias07@live.com',                  'owner'),
    ('DCENG',  'thays_hernandes@hotmail.com',       'admin'),
    ('DCENG',  'diasecardozo@diasecardozo.com.br',  'user')
) AS v(tenant_code, email, role)
JOIN hub_tenant t ON t.tenant_code = v.tenant_code
JOIN hub_user   u ON u.email       = v.email
ON CONFLICT (tenant_id, user_id) DO UPDATE SET
    role = EXCLUDED.role,
    is_active = TRUE;


-- ─── hub_store ───────────────────────────────────────────────
-- Filiais / unidades de negócio por tenant.
INSERT INTO hub_store (store_id, tenant_id, store_code, store_name, status)
SELECT
    v.store_id::uuid,
    t.tenant_id,
    v.store_code,
    v.store_name,
    'active'
FROM (VALUES
    ('4f64d633-a304-5fb2-ab3a-0fb92291f18d', 'AXYS',   'AXYSSYSTEM', 'AxysSystem'),
    ('50d4970e-b91e-56a7-988f-d5ecf615f55a', 'LUNALO', 'OUROESTE',   'Lunalô Ouroeste'),
    ('d6e937a1-47bd-5d3e-a4d3-11c210e3b22a', 'LUNALO', 'JALES',      'Lunalô Jales'),
    ('b09ab7ef-3f97-4bad-8b28-1aee900c5d7a', 'LUNALO', 'LOC-JALES',  'L''Occitane Jales'),
    ('74b34022-49ce-5366-8d7c-5d90526e9c85', 'DCENG',  'DCENG',      'Dias & Cardozo - Eng. e Arq.')
) AS v(store_id, tenant_code, store_code, store_name)
JOIN hub_tenant t ON t.tenant_code = v.tenant_code
ON CONFLICT (tenant_id, store_code) DO NOTHING;


-- ─── hub_user_store ──────────────────────────────────────────
-- Acesso de usuários a stores específicas.
INSERT INTO hub_user_store (tenant_id, user_id, store_id)
SELECT t.tenant_id, u.user_id, s.store_id
FROM (VALUES
    ('AXYS',   'rdias07@live.com',                 'AXYSSYSTEM'),
    ('AXYS',   'thays_hernandes@hotmail.com',      'AXYSSYSTEM'),
    ('LUNALO', 'thays_hernandes@hotmail.com',      'OUROESTE'),
    ('LUNALO', 'thays_hernandes@hotmail.com',      'JALES'),
    ('LUNALO', 'thays_hernandes@hotmail.com',      'LOC-JALES'),
    ('LUNALO', 'lunalocalcados@hotmail.com',       'OUROESTE'),
    ('LUNALO', 'lunalocalcados@hotmail.com',       'JALES'),
    ('DCENG',  'rdias07@live.com',                 'DCENG'),
    ('DCENG',  'thays_hernandes@hotmail.com',      'DCENG'),
    ('DCENG',  'diasecardozo@diasecardozo.com.br', 'DCENG')
) AS v(tenant_code, email, store_code)
JOIN hub_tenant t ON t.tenant_code = v.tenant_code
JOIN hub_user   u ON u.email       = v.email
JOIN hub_store  s ON s.tenant_id   = t.tenant_id
                 AND s.store_code  = v.store_code
ON CONFLICT (tenant_id, user_id, store_id) DO NOTHING;


-- ─── hub_plano ───────────────────────────────────────────────
-- Planos bootstrap para liberar o ecossistema em ambiente novo.
INSERT INTO hub_plano (plano_id, sistema_id, nome, descricao, billing_model, limites_json, versao, status, created_at)
SELECT
    gen_random_uuid(),
    s.sistema_id,
    'UNLIMITED_BOOTSTRAP',
    'Plano bootstrap seedado para liberar o acesso inicial no ecossistema Axys.',
    'mensal',
    CASE
        WHEN s.sistema_code IN ('EASYBUILDDIARY', 'EASYFINCONTROL')
            THEN '{"grant_model":"slot","slots":"unlimited","swaps_cota":1,"period_unit":"month"}'::jsonb
        ELSE '{"grant_model":"counter","quota":"unlimited","period_unit":"month"}'::jsonb
    END,
    1,
    'active',
    now()
FROM hub_sistema s
WHERE s.sistema_code IN (
    'AXYSGESTOR',
    'AXYSPRO',
    'EASYCPU',
    'EASYDOCS',
    'EASYFINCONTROL',
    'EASYLICITPLAN',
    'EASYORCA',
    'EASYPRICE',
    'EASYPRICE2',
    'EASYPROJECTMANAGER',
    'EASYBUILDDIARY'
)
ON CONFLICT (sistema_id, versao, nome) DO UPDATE SET
    descricao = EXCLUDED.descricao,
    billing_model = EXCLUDED.billing_model,
    limites_json = EXCLUDED.limites_json,
    status = EXCLUDED.status;


-- ─── hub_assinatura ──────────────────────────────────────────
-- AXYS: tudo liberado. LUNALO: apenas Gestor. DCENG: Easy liberado.
INSERT INTO hub_assinatura (assinatura_id, tenant_id, sistema_id, plano_id, status, started_at)
SELECT
    gen_random_uuid(),
    t.tenant_id,
    s.sistema_id,
    p.plano_id,
    'active',
    now()
FROM hub_tenant t
JOIN hub_sistema s ON TRUE
JOIN hub_plano p
  ON p.sistema_id = s.sistema_id
 AND p.nome = 'UNLIMITED_BOOTSTRAP'
 AND p.status = 'active'
WHERE
    (t.tenant_code = 'AXYS')
    OR (
        t.tenant_code = 'LUNALO'
        AND s.sistema_code IN ('AXYSGESTOR')
    )
    OR (
        t.tenant_code = 'DCENG'
        AND s.sistema_code IN (
            'EASYCPU',
            'EASYDOCS',
            'EASYFINCONTROL',
            'EASYLICITPLAN',
            'EASYORCA',
            'EASYPRICE',
            'EASYPRICE2',
            'EASYPROJECTMANAGER',
            'EASYBUILDDIARY'
        )
    )
ON CONFLICT DO NOTHING;


-- ─── hub_licenca ─────────────────────────────────────────────
INSERT INTO hub_licenca (assinatura_id, tenant_id, sistema_id, status, valid_from, valid_until, created_at)
SELECT
    a.assinatura_id,
    a.tenant_id,
    a.sistema_id,
    'active',
    a.started_at,
    NULL,
    now()
FROM hub_assinatura a
WHERE a.status = 'active'
ON CONFLICT (tenant_id, sistema_id) DO UPDATE SET
    assinatura_id = EXCLUDED.assinatura_id,
    status = 'active',
    valid_from = COALESCE(hub_licenca.valid_from, EXCLUDED.valid_from),
    valid_until = NULL;


-- ─── hub_user_app ────────────────────────────────────────────
-- Vínculo efetivo usuário ↔ app (fonte do acesso no Easy).
INSERT INTO hub_user_app (tenant_id, user_id, sistema_id, status, granted_at)
SELECT
    t.tenant_id,
    u.user_id,
    s.sistema_id,
    'active',
    now()
FROM (VALUES
    ('AXYS',   'rdias07@live.com'),
    ('AXYS',   'thays_hernandes@hotmail.com'),
    ('DCENG',  'rdias07@live.com'),
    ('DCENG',  'thays_hernandes@hotmail.com'),
    ('DCENG',  'diasecardozo@diasecardozo.com.br')
) AS v(tenant_code, email)
JOIN hub_tenant t ON t.tenant_code = v.tenant_code
JOIN hub_user   u ON u.email = v.email
JOIN hub_sistema s
  ON s.sistema_code IN (
      'EASYCPU',
      'EASYDOCS',
      'EASYFINCONTROL',
      'EASYLICITPLAN',
      'EASYORCA',
      'EASYPRICE',
      'EASYPRICE2',
      'EASYPROJECTMANAGER',
      'EASYBUILDDIARY'
  )
ON CONFLICT (tenant_id, user_id, sistema_id) DO UPDATE SET
    status = 'active';
