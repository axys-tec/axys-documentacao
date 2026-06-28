# Easy Orça™ — MVP

## Objetivo

Disponibilizar uma bancada profissional de elaboração, edição e finalização de orçamentos de engenharia.

Diferentemente do Easy CPU, que interpreta e referencia orçamentos existentes, o Easy Orça é um ambiente completo de produção orçamentária, permitindo liberdade total de edição e construção.

---

## Fluxo

### 1. Cadastro

Usuário:

* cria empreendimento;
* cria ativo;
* define UF;
* define BDI.

Leis sociais podem ser alteradas livremente.

O usuário pode:

* alterar regime horista/mensalista;
* alterar percentuais;
* criar cenários próprios.

---

### 2. Inicialização

Ao abrir a bancada de orçamento:

Sistema exibe aviso:

"Este processamento consumirá um uso do plano contratado."

Usuário confirma.

Sistema contabiliza o uso.

---

### 3. Criação do orçamento

O orçamento pode nascer de:

* orçamento vazio;
* importação de planilha Excel;
* importação CSV;
* clonagem de orçamento existente do mesmo tenant;
* orçamento oriundo do Easy CPU;
* orçamento oriundo do Easy Price.

---

### 4. Bancadas de trabalho

#### Planilha

Permite:

* inserir itens;
* remover itens;
* editar quantidades;
* editar preços;
* editar descrições;
* reorganizar estrutura.

#### Composições

Permite:

* criar composições próprias;
* editar composições próprias;
* editar preços;
* editar coeficientes;
* criar insumos próprios.

#### Leis Sociais

Permite:

* alterar percentuais;
* alterar regime;
* simular cenários.

#### BDI

Permite:

* editar componentes;
* criar múltiplos BDIs;
* simular cenários.

#### Memorial de Cálculo

Permite:

* documentação livre;
* registros técnicos;
* justificativas.

#### Cronograma

Permite:

* distribuição física;
* distribuição financeira;
* ajustes manuais.

---

### 5. Revisões

O sistema mantém snapshots do orçamento.

Exemplos:

* R00
* R01
* R02
* R03

Cada revisão preserva:

* planilha;
* composições;
* preços;
* cronograma;
* memorial de cálculo.

---

### 6. Finalização

Usuário acessa a aba Finalização.

Ferramentas:

* revisão geral;
* validação de consistência;
* curva ABC;
* relatórios;
* exportações.

---

### 7. Status

#### Rascunho

Enquanto não finalizado:

* PDF com tarja "RASCUNHO";
* planilhas exportadas sem fórmulas;
* documentos não oficiais.

#### Finalizado

Após finalização:

* PDF oficial;
* planilhas com fórmulas;
* documentos liberados para entrega.

---

### Recursos opcionais

#### Easy Branding

* capa personalizada;
* logomarca;
* fontes corporativas;
* relatórios personalizados.

#### Easy Docs

* memorial descritivo;
* documentação complementar.

---

### Consumo

A abertura da bancada e confirmação do processamento contabilizam um uso do plano contratado.
