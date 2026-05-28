# Revisão de Pull Request — Padrão Axys

Este Pull Request será avaliado conforme as **diretrizes arquiteturais e normativas do ecossistema Axys**.

Nenhuma alteração será incorporada sem atender integralmente aos critérios abaixo.

---

## 1. Identificação do PR

- **Título:**  
- **Autor:**  
- **Tipo de alteração:**  
  - ( ) Core Axys  
  - ( ) Módulo Funcional  
  - ( ) MicroApp  
  - ( ) Documentação  
  - ( ) Infraestrutura  
- **Relaciona-se a qual decisão/feature:**  

---

## 2. Descrição da Alteração

Descreva **o que foi alterado** e **por quê**, em nível conceitual.

> ❗ Não descreva código linha a linha.  
> Foque na intenção e no impacto arquitetural.

---

## 3. Classificação Arquitetural

Marque todas as opções aplicáveis:

- ( ) Alteração normativa (regra / contrato)
- ( ) Alteração de implementação
- ( ) Correção de bug
- ( ) Evolução arquitetural
- ( ) Refatoração sem mudança funcional

Se houver alteração normativa, **indique a documentação afetada**:

- Documento(s):  
- Seção(s):  

---

## 4. Checklist de Conformidade Axys

### 4.1 Documentação
- ( ) Não inclui DDL
- ( ) Não inclui código executável
- ( ) Mantém separação entre conceito e implementação
- ( ) Está alinhada ao checklist de documentação Axys

### 4.2 Arquitetura
- ( ) Não viola regras do AxysHub Core
- ( ) Não cria dependência circular entre módulos
- ( ) Não introduz acoplamento indevido
- ( ) Mantém isolamento entre tenants

### 4.3 Banco de Dados
- ( ) Não altera schema sem migration versionada
- ( ) Não depende de detalhes físicos documentados
- ( ) Alterações são compatíveis com versionamento

### 4.4 Licenciamento e Segurança
- ( ) Não contorna regras de licenciamento
- ( ) Não expõe segredos ou chaves
- ( ) Não cria bypass de validação

---

## 5. Impacto Avaliado

Indique os impactos conhecidos:

- **Core Axys:**  
- **Módulos existentes:**  
- **MicroApps:**  
- **Backward compatibility:**  
  - ( ) Mantida  
  - ( ) Quebra controlada  
  - ( ) Quebra não aceitável  

---

## 6. Testes e Validação

- ( ) Testado localmente
- ( ) Testes automatizados (se aplicável)
- ( ) Validação conceitual realizada
- ( ) Não afeta dados existentes

Descreva brevemente como foi validado:

---

## 7. Riscos Identificados

Liste riscos técnicos, arquiteturais ou operacionais:

-  
-  

Se **nenhum**, declarar explicitamente:
> ( ) Nenhum risco identificado

---

## 8. Decisão de Revisão

- ( ) Aprovado sem ressalvas
- ( ) Aprovado com ajustes
- ( ) Reprovado

### Observações do Revisor:
-  

---

## 9. Declaração Final

> Confirmo que este PR está em conformidade com as diretrizes do AxysHub Core e com o checklist de governança arquitetural.

- **Revisor:**  
- **Data:**  
