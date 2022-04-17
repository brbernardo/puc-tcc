# SISTEMA DE LOGÍSTICA BASEADA EM MICROSSERVIÇOS


Trabalho de Conclusão de Curso de Especialização em Arquitetura de Software Distribuído como requisito parcial à obtenção do título de especialista.

PONTIFÍCIA UNIVERSIDADE CATÓLICA DE MINAS GERAIS
NÚCLEO DE EDUCAÇÃO A DISTÂNCIA
Pós-graduação Lato Sensu em Arquitetura de Software Distribuído

## RESUMO
O presente trabalho foi proposto considerando a importância da área de logística, particularmente no que se refere à entrega de produtos diversos aos consumidores, no atual contexto de pandemia. As pessoas, não podendo sair de casa para realizar suas compras do dia-a-dia, tem se servido de sites de ecommerce, tais como: supermercados, farmácias, lojas, entre outros. Como solução veremos nesse trabalho um modelo arquitetural proposto para o contexto baseado em micro serviços.
##### Palavras-chave: arquitetura de software, projeto de software, requisitos arquiteturais.

## 1. Objetivos do trabalho
O objetivo deste trabalho é apresentar a descrição do projeto arquitetural de uma aplicação para uma empresa fictícia de logística explorando o paradigma de micro serviços.
Os objetivos específicos são:
- Descrever os requisitos arquiteturais da aplicação;
- Propor um modelo de componentes;
- Propor um modelo de implementação baseada em cloud;

## 2. Descrição geral da solução
Esta seção se destina a descrever a solução arquitetural definida para a aplicação propos-ta. 
### 2.1. Apresentação do problema
O tema deste trabalho foi proposto considerando a importância da área de logística, particularmente no que se refere à entrega de produtos diversos aos consumidores, no atual contexto de pandemia.  As pessoas, não podendo sair de casa para realizar suas compras do dia a dia, tem se servido de sites de e-commerce, tais como: supermercados, farmácias, lojas, entre outros. Nesse contexto muitas empresas se especializaram em entregar essas mercadorias, tendo de disputar espaço nesse competitivo mercado. Em relação aos processos de logística envolvidos observa-se uma segmentação das etapas de entrega, passando pelos diversos trechos envolvidos. A primeira etapa do processo, que pode ser realizada uma ou mais de uma vez, envolve a movimentação das mercadorias desde um depósito ou centro de distribuição até outro, mais próximo do consumidor. A seguir é realizada a entrega, que é a etapa final do processo.

Visando contextualizar a empresa objeto desta análise, cujo nome fictício é Boa Entrega, considere tratar-se de uma transportadora de grande porte, com centenas de empresas clientes dos seus serviços de logística nos diversos municípios onde atua, em todo o território brasileiro. A Boa Entrega definiu milhares de rotas de entrega, fazendo uso de algoritmos de otimização para traçar esses caminhos. A escolha da melhor rota é realizada em tempo real utilizando recursos de geoprocessamento, a partir de bases de dados geográficas e mapas providos pela Google. Para que as rotas sejam definidas faz-se uso de serviços de acesso a dados e roteamento providos por empresas como a própria Google, Microsoft, Mapservice e outras. Diversos fatores influenciam no traçado de uma rota, sendo os três principais: a distância entre os endereços considerando as rotas possíveis, o custo da rota (em termos de gasto de combustível) e o tempo da rota (considerando o horário previsto para entrega). Toda entrega deve ser registrada no Sistema de Gestão de Entregas (SGE), até o final do dia do evento. Ao mesmo tempo que deve realizar entregas a transportadora deve cumprir metas. 

## 3. Definição conceitual da solução
Esta seção apresenta uma definição conceitual da solução a ser desenvolvida: requisitos funcionais e não funcionais, restrições e mecanismos arquiteturais considerados.
### 3.1. Requisitos Funcionais
1. Automatizar todos os processos de entrega realizados por ela, visando aprimorar os processos de apuração, conferência e faturamento e manter um nível de remuneração adequado;
2. Implementar integrações de seus sistemas com os de suas parceiras, de modo a propiciar que as entregas possam ser realizadas em parceria, em uma ou mais etapas do processo. Essas integrações requerem que os sistemas atuais sejam adaptados e novos componentes sejam incorporados visando a uma maior abertura, que será baseada na arquitetura orientada a serviços;
3. Utilizar geotecnologias em todos os processos que envolvam localização, de forma a facilitar a identificação e atualização de informações relativas às entregas agendadas e realizadas;
4. Tornar viável o uso de todas as tecnologias da informação e softwares necessários para atender às demandas dos clientes, fornecedores e parceiros, conforme definido neste documento.



