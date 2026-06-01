# AxysHub — Operações & Deployment

**Status:** ⚠️ Por documententer completamente  
**Prioridade:** Alta (produção ativa)

---

## Deployment

### Render Deployment

Hub roda no Render:
- **Service:** Web Service
- **Repo:** axys-hub
- **Branch:** main
- **Runtime:** Python 3.11

### Environment Variables

```
DATABASE_URL=postgresql://...
JWT_SECRET_KEY=...
JWT_ALGORITHM=RS256 (prod) / HS256 (dev)
```

### Database Migrations

```bash
# Aplicar migrations
python -m alembic upgrade head

# Criar nova migration
python -m alembic revision --autogenerate -m "description"
```

---

## Monitoramento

### Logs

Acessar via Render dashboard:
- Web Service logs
- Database activity

### Métricas Críticas

- [ ] Response time (login endpoint)
- [ ] Database connection pool
- [ ] JWT token issuance rate
- [ ] Failed login attempts

---

## Troubleshooting

### Connection Pool Exhausted

```
Error: connection pool is exhausted
```

**Solução:** Aumentar `max_connections` no PostgreSQL

### Database Lock

```
Error: database is locked
```

**Solução:** Verificar migrations em execução

---

## ⚠️ TODO

- [ ] Criar runbook de incident response
- [ ] Documentar backup/restore procedure
- [ ] Adicionar health check endpoint
- [ ] Monitoramento de disk space
- [ ] Rate limiting strategy

