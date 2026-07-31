# AxysGestor — desenho de produto para o Hub

**Status:** decisão inicial de fronteira  
**Escopo:** como o Hub deve enxergar o AxysGestor

---

## Decisão

Para o Hub, o AxysGestor é um único produto/app macro:

```text
app = gestor
ecossistema = GESTOR
```

`AXYSGESTOR` permanece como produto legado/compatibilidade. O contrato novo usa
produtos licenciáveis específicos dentro do ecossistema `GESTOR`, no mesmo nível
conceitual em que o Easy usa `CPU`, `PRI`, `DOC`, etc.

---

## Produtos internos do AxysGestor

O serviço AxysGestor contém produtos internos distintos. Para a primeira onda,
o Hub espelha o padrão do Easy usando `product.product`, sem `product.module`:

| Produto | Código canônico | Slug no JWT | Responsabilidade |
|---|---|---|---|
| SL Company | `SL-COMPANY` | `gestor-sl-company` | Operações ligadas à Santa Lolla |
| L'Occitane | `LOCCITANE` | `gestor-loccitane` | Operações ligadas à L'Occitane |
| Analista Vendas | `ANALISTA-VENDAS` | `gestor-analista-vendas` | Fluxos comerciais e pedidos |
| Analista Compras | `ANALISTA-COMPRAS` | `gestor-analista-compras` | Fluxos de compras |
| Notificador | `NOTIFICADOR` | `gestor-notificador` | Notificações operacionais |
| Conciliador | `CONCILIADOR` | `gestor-conciliador` | Conciliações operacionais |

Esses slugs são emitidos pelo Hub para espelhar o formato do Easy, mas a
autorização interna de cada produto pertence ao AxysGestor.

---

## Responsabilidade do Hub

O Hub deve:

- autenticar o usuário;
- identificar `user`, `tenant` e papel macro do vínculo;
- confirmar licença ativa de ao menos um produto do ecossistema `GESTOR` ou,
  por compatibilidade, `AXYSGESTOR`;
- emitir JWT para `app=gestor`;
- informar `login_scope`, store opcional e `actor_type`;
- emitir `apps_licenciadas`, `app_labels` e `licencas` no mesmo formato do Easy;
- publicar JWKS para validação RS256.

`actor_type` é resolvido em `identity.hub_tenant_profile` por `tenant_id + app_code`.

Valores aceitos para `app_code = 'gestor'`:

- `internal`
- `client`
- `partner`
- `brand_representative`

`login_scope` informa como o documento de login foi resolvido:

- `tenant`: documento bateu em `identity.hub_tenant.document`;
- `store`: documento bateu em `identity.hub_store.document`.

---

## Responsabilidade do AxysGestor

O AxysGestor deve:

- decidir quais produtos internos o usuário pode acessar;
- resolver stores disponíveis;
- resolver permissões por produto interno;
- controlar o contexto ativo `tenant/store/product`;
- aplicar regras de negócio dos produtos internos do Gestor;
- manter seeds e permissões operacionais próprias.

---

## Regra prática

O Hub abre a porta.

O AxysGestor decide em qual sala o usuário entra.
