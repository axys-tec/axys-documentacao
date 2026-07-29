# AxysGestor

**Status:** 🟡 Concepção
**Versão:** 0.1
**Ecossistema:** micro-apps de gestão de varejo

---

## O que é?

**AxysGestor** é um **ecossistema de micro-apps de gestão para varejo**, plugáveis
a ERPs, organizado por **verticais de cliente/integração** + **micro-apps horizontais**
que batem em qualquer ERP via token/API.

**Core central:** o **Hub** (identidade/SSO + fronteira central). Todo AxysGestor
autentica e coordena pelo Hub — [[axys-hub]].

---

## Verticais (por cliente / integração)

| Vertical | Foco |
|---|---|
| **SL** | Operação da marca **Santa Lolla** dentro do ecossistema Axys-Gestor. |
| **AxysGestorAscShop** | Integração com o **ERP da Ascont — com** esquema de **grade**. |
| **AxysGestorAscShop2** | Integração com o **ERP da Ascont — sem** grade. |
| **AxysGestorLoccitane** | Expansão para operações da **L'Occitane** + integração com **VO (VarejOnline)**. |
| **AxysGestorStores** | Guarda-chuva dos **micro-apps** plugáveis em **qualquer ERP** (batem aqui com **token / API**). |

---

## Micro-apps (dentro de AxysGestorStores)

Plugáveis em qualquer ERP. Exemplos:

| Micro-app | O que faz |
|---|---|
| **ClientBack** | Análogo ao **crm-bonus**: controle de **giftback / cashback**, plugável em ERPs. |
| **Notifier** | Notifica o gestor das **ocorrências do dia** via **API do WhatsApp** (vendas, trocas, compras, etc — pode fazer qualquer coisa). |
| **GiroInsights** | Analista de **giro** (estoque/produto). |
| **CardConciliator** | **Conciliador de cartão**. |

---

## Estrutura atual desta pasta

- `governanca/` reúne os contratos transversais do Axys-Gestor.
- `SL/` concentra o material específico da vertical Santa Lolla.

_Registro inicial (2026-07-29). A detalhar conforme o ecossistema amadurece._
