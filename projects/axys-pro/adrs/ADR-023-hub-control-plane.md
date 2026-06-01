# ADR-009 — Hub como Control Plane (Licença/Política) e ERP como Data Plane (Execução)

**Status:** Aceito  
**Data:** 2026-02-02  

## Contexto
O AxysPro (ERP principal) pode rodar local (on‑prem) ou hospedado.  
O AxysHub é o sistema central de governança, licenciamento e distribuição de políticas.

Há preocupações com:
- cópia de código (backend/frontend);
- performance e latência se o Hub virar backend operacional;
- proteção da lógica de negócio e do valor econômico do produto.

---

## Decisão
Adotar a separação clara:

- **AxysHub = Control Plane**
  - identidade e autenticação
  - licenciamento
  - políticas e limites
  - auditoria mínima
  - emissão de tokens e pacotes assinados

- **AxysPro ERP = Data Plane**
  - execução
  - cálculos complexos
  - relatórios
  - banco de dados
  - UX e operações diárias

**Princípio-mãe:** o ERP não depende do Hub por clique.

---

## Consequências
- Alta performance local
- Operação offline controlada
- Proteção econômica contra cópia
- Hub escalável e simples

---

# Contrato Técnico — Lease Token

## Objetivo
Permitir operação local com validação periódica.

## Forma
JWT assinado pelo Hub.

## TTL
7 dias (padrão), até 30 dias para planos especiais.

## Claims mínimas
- tenant_id
- license_id
- plan_code
- modules
- limits
- policy_version
- fingerprint
- iat / exp

## Renovação
Background, sem impacto no usuário.

## Modo degradado
- leitura permitida
- export oficial bloqueado
- integrações premium bloqueadas

---

# Policy Bundle

## Conteúdo
- versão de política
- flags de feature
- limites
- catálogos
- regras parametrizáveis

## Distribuição
Download sob demanda, cache local, assinatura obrigatória.

---

# Assinatura de Artefatos Oficiais (Opcional)

Aplicável a:
- PDF oficial
- exportações externas
- integrações

Assinatura assíncrona, sem bloquear UX.

---

## Regra Final
Tudo que é copiável deve ser irrelevante.  
Tudo que é relevante não deve ser copiável.
