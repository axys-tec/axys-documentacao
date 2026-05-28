# Regra-Mãe do Ecossistema Axys

Este documento constitui a **regra-mãe do ecossistema Axys**, qual estabelece as **regras fundamentais e imutáveis** que regem a concepção, documentação, implementação e evolução de todo o ecossistema Axys.

Em caso de conflito conceitual, interpretativo ou normativo entre Arquivos prevalece a Regra-Mãe sobre ADRs, artefatos modulares, guias técnicos, exemplos de implementação e demais artefatos documentais. Nenhuma decisão técnica, funcional ou contratual pode contrariar estas regras.

---

## 1. Separação de Naturezas

O ecossistema Axys é composto por **sistemas distintos**, cada qual com responsabilidade, ciclo de vida e governança próprios.

Nenhum sistema deve assumir responsabilidades que não lhe competem.

---

## 2. Contrato ≠ Implementação

- Contratos descrevem **obrigações, direitos e limites funcionais**.
- Implementações técnicas não fazem parte do contrato.
- Decisões técnicas são documentadas em ADRs e documentação técnica.

O contrato **não congela arquitetura**.

---

## 3. Documentação como Fonte de Verdade

A documentação oficial do Axys é hierarquizada da seguinte forma:

1. Regra-Mãe
2. Contratos e Governança
3. ADRs (decisões técnicas)
4. Documentação Core
5. Documentação de Módulos
6. Implementação e Código

Em caso de conflito, prevalece o nível mais alto da hierarquia.

---

## 4. Evolução Controlada

O Axys é um sistema vivo e evolutivo.

- Evoluções técnicas são permitidas e esperadas.
- Mudanças estruturais exigem documentação.
- Compatibilidade é priorizada sempre que possível.

---

## 5. Código como Implementação, não como Verdade

- O código-fonte implementa decisões documentadas.
- Ele **não substitui** documentação normativa.
- Nenhuma regra crítica pode existir apenas no código.

---

## 6. Propriedade Intelectual

O código, arquitetura e documentação do Axys pertencem à Axys Engenharia e Tecnologia Ltda, sendo licenciados aos clientes conforme contrato específico.

---

## 7. Autonomia do Cliente

Sempre que possível:
- dados pertencem ao cliente
- infraestrutura é escolha do cliente
- operação não depende de conectividade contínua

Licenciamento e governança permanecem sob responsabilidade da Axys.
