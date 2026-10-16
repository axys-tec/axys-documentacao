# Conversão H→MÊS na bancada — Contrato (orçamento real)

**Status:** Decidido, a implementar.
**Data:** 2026-10-16
**Escopo:** o que muda quando a conversão de mão de obra entra num orçamento que vai ser entregue. Registro da origem, reprodutibilidade e recálculo por dias úteis reais.
**Parte 1:** [`catalogo/conversao_mdo_divisor.md`](../catalogo/conversao_mdo_divisor.md) — o divisor e sua justificativa. Este documento **não** repete a derivação; ele trata do que a consulta não precisa e o orçamento precisa.

> **A diferença entre as duas partes é uma só:** na consulta nada congela — cada abertura recalcula e o divisor de hoje é o certo. No orçamento, o custo vira documento entregue, e documento tem de se reproduzir depois.

---

## 1. Por que a bancada precisa de mais

Os encargos sociais são revisados **anualmente** pela CAIXA, a partir das convenções coletivas homologadas. O divisor é função deles. Logo, um orçamento convertido em março e reaberto em dezembro, recalculado ao vivo, dá outro número — e o orçamentista entregou o primeiro.

Isso não é hipótese: é o comportamento normal do sistema de referência. Quem entrega um orçamento precisa poder reproduzi-lo exatamente, inclusive num questionamento que chegue meses depois.

---

## 2. O que se grava

Cada item de mão de obra convertido na bancada carrega a **origem da conversão**, junto do custo capturado:

| Atributo | O que é |
|---|---|
| `divisor` | o valor aplicado (ex. 175,1528), com as casas que o cálculo produziu |
| `es_horista` / `es_mensalista` | os dois percentuais da edição e UF que o geraram |
| `edi_id`, `uf`, `modalidade` | de onde vieram |
| `par_origem` | o par H↔MÊS usado (`88316 → 101452`), vindo do catálogo |
| `coef_fisico` | **o coeficiente horista original, em horas** |
| `criterio` | o rótulo do critério aplicado (§4) |

Isso **não é cache do divisor** — é registro do que foi aplicado naquele documento. A distinção importa: não guardamos a tabela, que continua sendo derivada ao vivo no catálogo; guardamos o valor que este orçamento usou.

**O `coef_fisico` é o item mais importante da lista.** É dele que saem histograma, cronograma e pré-planejamento. Sem ele gravado, a app volta a tentar recuperar horas multiplicando a fração em MES por um número — que é exatamente o defeito que este trabalho corrige.

---

## 3. Reabrir, recalcular, reconciliar

**Reabrir não recalcula.** O orçamento mostra o que gravou.

**Recalcular é ação explícita**, e ela diz o que mudou: divisor anterior e novo, os encargos que mudaram, o efeito em R$ no total. A mesma doutrina da recaptura de preços — o orçamento não anda sozinho.

**Orçamento de composição descontinuada não recaptura**, como já vale hoje: o preço gravado é o certo.

---

## 4. Os critérios de apropriação

A bancada é orçamento real, e aí há mais de uma pergunta legítima. Cada item converte por um critério **declarado**:

| Critério | Divisor | Quando |
|---|---|---|
| `EQUIVALENCIA_ES` | `220 × (1+ES_m)/(1+ES_h)` — ex. 175,16 | **padrão.** Neutro nos encargos sociais; a economia que sobra é de complementares, com causa publicada |
| `DIAS_UTEIS` | horas úteis do calendário da obra | quando a obra tem data e local definidos e o orçamentista quer apropriar pela disponibilidade real |

São **dois**, e não três. Um terceiro critério "remuneração-base ÷ 220" chegou a ser cogitado para a administração local e não existe, porque ali não há conversão a parametrizar — ver §4.2.

O critério viaja no registro (§2) e aparece no parecer. Trocar de critério é decisão do orçamentista, não default escondido.

### 4.1 O critério por dias úteis

Com data-alvo e município, dá para apropriar pelo calendário real em vez da equivalência. Os levantamentos de 2026 para São Paulo dão de 182,60 a 184,07 h/mês antes das ausências; descontando o que não se repõe (chuva, falta, doença — cerca de 5,5 h/mês) chega-se perto de 178.

**Isso aumenta a margem, e é justificável.** Um divisor maior reduz a fração de mês apropriada por unidade de serviço, e portanto o custo. Subir de 175 para 185 não é manobra: é afirmar que naquela obra, naquele ano e naquele município, o colaborador está disponível mais horas do que a equivalência financeira supõe — o que o calendário demonstra.

**Mas é afirmação que o orçamentista assume**, e por isso vem com três obrigações: o calendário usado (município, ano, feriados considerados) entra no parecer; as ausências não repostas são descontadas e nomeadas; e o critério fica marcado no item, para quem ler o orçamento saber que ali não se usou o padrão.

### 4.2 A administração local não converte

Na ALO o profissional é mensalista por natureza — é o uso que a SINAPI documenta para os insumos em MES: *"profissionais que comumente são considerados na equipe de administração local de uma obra, tais como almoxarife, topógrafo, engenheiro"*. O coeficiente nasce em MES, e **nada passa por divisor**: não há conversão, logo não há critério a escolher.

**Se a ALO for montada com insumo horista, vale o que já vale hoje.** A mão de obra sem par mensalista fica `ERR` — sem custo, forçando a correção. Essa função fica como está: não se inventa conversão para salvar o caso, porque o caso é de montagem, não de apropriação. Quem monta administração local com horista está usando a referência fora do que ela prevê, e a app diz isso em vez de calcular por cima.

### 4.3 De onde vêm os feriados

O critério `DIAS_UTEIS` depende de calendário local, e calendário local é **município**, não UF: são os 2 a 5 feriados por ano (aniversário da cidade, padroeira, datas locais) que fazem a diferença de 1,5 a 3,7 h/mês. Nacional e estadual se derivam sem fonte externa.

**Conferido antes de decidir:** o endpoint de feriados da BrasilAPI cobre **só o nacional** — pagar por ele não resolveria o que precisa ser resolvido. O serviço a contratar tem de entregar os três níveis **por código IBGE**, que é a chave que a app já tem (`catalogo.municipios.mun_id` é o código IBGE de 7 dígitos). A ordem de grandeza levantada foi de R$ 39/mês; a cobertura municipal é condição, o preço é consequência.

**A persistência é a dos índices**, e pelo mesmo motivo: feriado de um ano é dado estático, e uma obra orçada hoje não pode depender de uma API estar no ar. Duas formas, ambas aceitáveis: assinatura com atualização noturna, como o histórico de índices já faz, ou um mês de assinatura por ano — preenche o calendário do ano seguinte em janeiro e cancela. A segunda é mais barata e tem o mesmo resultado, com a ressalva de que lei municipal nova no meio do ano só entra na recarga seguinte; o parecer registra a data da coleta, e aí quem lê sabe de quando é o calendário.

---

## 5. A guarda legal

Converter regime **barateando** cabe no caput do art. 8º do Decreto 7.983/2013. **Encarecendo**, cai no parágrafo único e exige aprovação do órgão gestor.

Com o divisor padrão a conversão barateia pouco (cerca de 3% na parcela de mão de obra, vindos dos complementares), e fica no caput. Com `DIAS_UTEIS` barateia mais. Com `REMUNERACAO_BASE` barateia muito — e é por isso que esse critério fica restrito ao caso em que não há conversão nenhuma.

**A bancada sinaliza a direção.** Se alguma combinação de critério, UF e regime encarecer o item, o aviso é explícito e o parecer registra que o caso é do parágrafo único. A app não impede — a decisão é do orçamentista —, mas não deixa passar calado.

---

## 6. O que a conversão não pode tocar

**O histograma, o cronograma e o pré-planejamento leem `coef_fisico`.** Nunca a fração em MES, nunca o divisor. Trocar o critério de apropriação muda o custo do orçamento e **não muda uma hora** do planejamento — porque o trabalho que o serviço exige não depende de como a mão de obra foi contratada.

É a mesma regra da parte 1, §5, dita onde ela tem consequência: aqui as duas dimensões convivem no mesmo documento, e é aqui que se misturariam.

---

## 7. Critérios de aceite

| Código | O que exige |
|---|---|
| `ORIGEM_GRAVADA` | Item convertido carrega divisor, ES de origem, edição/UF/regime, par e critério |
| `COEF_FISICO_GRAVADO` | O coeficiente horista original fica no item depois da rotação |
| `REABRIR_NAO_RECALCULA` | Abrir orçamento convertido não muda valor |
| `RECALCULO_DECLARADO` | Recalcular mostra divisor antigo × novo e o efeito em R$ antes de aplicar |
| `CRITERIO_EXPLICITO` | O critério aparece no item e no parecer; não há troca silenciosa |
| `DIAS_UTEIS_JUSTIFICADO` | Critério por calendário exige município, ano e lista de feriados no parecer |
| `ENCARECEU_AVISA` | Conversão que aumenta o custo do item é sinalizada, com a referência ao parágrafo único |
| `PLANEJAMENTO_INTACTO` | Trocar critério não altera nenhuma hora do histograma nem do cronograma |

**Cenários:** orçamento convertido e reaberto após revisão de encargos; recálculo com divisor novo; item com `DIAS_UTEIS` e item com `EQUIVALENCIA_ES` no mesmo orçamento; conversão que encarece; composição descontinuada convertida (não recaptura); exportação do orçamento com itens convertidos por critérios diferentes.

---

## 8. Ordem de implementação

1. **Preservar `coef_fisico`** em todo caminho que rotaciona regime. Sem isso o resto é perigoso.
2. **Trocar o divisor** na consulta (parte 1) e na bancada, com o parecer.
3. **Corrigir o histograma** para ler horas físicas — ele hoje erra por 220 e passaria a errar por 175,16 em cima.
4. **Registro e recálculo** na bancada.
5. **Critério por dias úteis**, que depende de data-alvo e calendário e só faz sentido depois do pré-planejamento.

A ordem não é negociável nos três primeiros: trocar o divisor antes de preservar o coeficiente físico deixa a app sem de onde tirar as horas.
