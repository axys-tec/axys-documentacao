# AxysEasy — Deployment

**Status:** 🟢 Render (produção)  
**Padrão:** AXYS-ADR-019 (foundation)

---

## Visão Geral

AxysEasy roda como **FastAPI + PostgreSQL** no Render:

```
┌──────────────────────────┐
│   axys-easy (FastAPI)    │  ← https://axys-easy.onrender.com
│   - Backend              │
│   - Frontend (Jinja2)    │
└──────────────────────────┘
         ↓
┌──────────────────────────┐
│  PostgreSQL (Render)     │  ← axys_easy_prod
│  - catalogo.*            │
│  - ativo.*               │
│  - audit.logs            │
└──────────────────────────┘
```

---

## Ambiente

### Render.com Setup

**Serviço:**
- Nome: `axys-easy`
- Region: São Paulo (fuso correto)
- Tipo: Web Service (Node/Python)

**Environment:**
```
ENVIRONMENT=production
DEBUG=false
DATABASE_URL=postgresql://user:pass@render.onrender.com:5432/axys_easy_prod
SQLALCHEMY_POOL_SIZE=15
SQLALCHEMY_POOL_RECYCLE=3600
SQLALCHEMY_ECHO=false

HUB_AUTH_URL=https://axys-hub.onrender.com
HUB_PUBLIC_KEY=-----BEGIN PUBLIC KEY-----\n...
JWT_ALGORITHM=RS256

LOG_LEVEL=INFO
SENTRY_DSN=https://xyz@sentry.io/project

# Para proteção
CORS_ORIGINS=["https://axys-easy.onrender.com"]
SECURE_COOKIE_DOMAIN=axys-easy.onrender.com
```

---

## Build & Deploy

### 1. Build via Render

**Render espera:**
- `requirements.txt` com dependências
- `Procfile` com comando start
- Arquivo de migrations (opcional)

**build.sh** (executado pelo Render):
```bash
#!/bin/bash
set -e

echo "Installing dependencies..."
pip install -r requirements.txt

echo "Running migrations..."
python scripts/run_migration.py --env prod

echo "Build complete!"
```

**Procfile:**
```
web: python -m uvicorn backend.app:app --host 0.0.0.0 --port $PORT
```

### 2. Migrations em Produção

Arquivo: `scripts/run_migration.py`

```python
#!/usr/bin/env python3
"""
Aplica todas as migrations pendentes ao banco de dados.

Uso:
  python scripts/run_migration.py --env dev
  python scripts/run_migration.py --env prod
"""
import argparse
import sys
from pathlib import Path
import psycopg2

def run_migration(env: str):
    db_url = os.getenv(f"DATABASE_URL_{env.upper()}")
    migrations_dir = Path(__file__).parent.parent / "docs/projects/axys-easy/schemas/migrations"
    
    conn = psycopg2.connect(db_url)
    cursor = conn.cursor()
    
    # Criar tabela de controle
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS schema_migrations (
            id SERIAL PRIMARY KEY,
            version VARCHAR(50) UNIQUE NOT NULL,
            applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    conn.commit()
    
    # Aplicar migrations
    for sql_file in sorted(migrations_dir.glob("*.sql")):
        version = sql_file.stem
        cursor.execute("SELECT 1 FROM schema_migrations WHERE version = %s", (version,))
        if cursor.fetchone():
            print(f"✓ {version} (já aplicada)")
            continue
        
        print(f"→ Aplicando {version}...")
        with open(sql_file) as f:
            cursor.execute(f.read())
        cursor.execute("INSERT INTO schema_migrations (version) VALUES (%s)", (version,))
        conn.commit()
        print(f"✓ {version}")
    
    cursor.close()
    conn.close()
    print("\n✓ Todas as migrations aplicadas!")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--env", required=True, choices=["dev", "prod"])
    args = parser.parse_args()
    run_migration(args.env)
```

### 3. Deploy Flow

```bash
# 1. Push para main
git push origin feature/xyz main

# 2. Render detecta push
#    → build.sh executa
#    → migrations rodam
#    → app restarts

# 3. Healthcheck
curl https://axys-easy.onrender.com/health
# {"status": "ok", "database": "connected"}
```

---

## Monitoramento

### Health Checks

**Rota:** `GET /health`

```json
{
  "status": "ok",
  "database": "connected",
  "timestamp": "2026-05-31T14:30:00Z",
  "uptime_seconds": 3600
}
```

### Logs

**Render logs:**
```
https://dashboard.render.com/web/srv-xxxx/logs
```

**Estrutura:**
```
[2026-05-31 14:30:00] INFO: Request GET /api/catalogo/insumos from user@axys.com (tenant: 550e8400...)
[2026-05-31 14:30:01] INFO: Query returned 150 rows in 42ms
```

### Alertas via Sentry

Exceções não tratadas → Sentry dashboard

**Configuração:**
```python
# backend/core/runtime_config.py
import sentry_sdk

if ENVIRONMENT == "production":
    sentry_sdk.init(SENTRY_DSN, traces_sample_rate=0.1)
```

---

## Troubleshooting

### Erro: "DATABASE_URL invalid"

```
ERROR: Could not parse database URL
```

**Solução:**
1. Verificar variável no Render dashboard
2. Confirmar URL format: `postgresql://user:pass@host:port/dbname`
3. Testar localmente:
```bash
psql "postgresql://user:pass@host:port/dbname" -c "SELECT version();"
```

### Erro: "Connection timeout"

```
psycopg2.OperationalError: FATAL: remaining connection slots reserved for non-replication superuser connections
```

**Solução:**
- Aumentar `SQLALCHEMY_POOL_SIZE` (atualmente 15)
- Limpar conexões antigas: `pg_terminate_backend()`
- Considerar read-only replicas

### App crashes após migration

**1. Verificar logs:**
```bash
# Render dashboard → Logs
# Procurar por: "ERROR", "FAILED", "Migration"
```

**2. Reverter migration:**
```bash
# Remover entrada de schema_migrations
DELETE FROM schema_migrations WHERE version = '004-xyz';

# Ou reverter manualmente
psql $DATABASE_URL < migrations/rollback-004-xyz.sql
```

**3. Redeployer:**
```bash
git push origin main  # Trigger novo deploy
```

---

## Performance

### Connection Pool

```python
# backend/core/easy_db.py
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=15,           # Conexões sempre abertas
    max_overflow=10,        # Extra durante picos
    pool_recycle=3600,      # Reciclar a cada hora
    pool_pre_ping=True,     # Check antes de usar
    echo=False
)
```

### Query Performance

Usar `EXPLAIN ANALYZE` antes de liberar:

```sql
EXPLAIN ANALYZE
SELECT * FROM ativo.materiais
WHERE ativo_id = 123 AND criado_em > NOW() - INTERVAL '30 days';

-- Índices úteis:
CREATE INDEX idx_ativo_materiais_ativo_id ON ativo.materiais(ativo_id);
CREATE INDEX idx_ativo_materiais_criado_em ON ativo.materiais(criado_em DESC);
```

---

## Backup & Disaster Recovery

### Backup Automático (Render)

Render faz backup diário automático. Acessar via:
```
Render Dashboard → axys_easy_prod → Backups
```

### Restore Manual

```bash
# 1. Download backup
# Render Dashboard → Backups → Download

# 2. Restore localmente
pg_restore -d axys_easy_dev backup.dump

# 3. Testar aplicação
python -m pytest tests/
```

---

## TODO

- [ ] CI/CD pipeline automático (GitHub Actions)
- [ ] Blue-green deployment para zero-downtime
- [ ] Database read replicas para escala de leitura
- [ ] Cache com Redis para queries frequentes

