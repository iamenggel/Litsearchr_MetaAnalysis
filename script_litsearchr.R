---
  title: "Package litsearchr to found Keywords"
author: "Enggel Carmo"
date: "04/07/2022"
output: html_document

---
  

# Para o Markdown ----->    knitr::opts_chunk$set(echo = TRUE, warning=FALSE, message=FALSE)
library(knitr)
library(readr)

## Lembrar de File > Encoding > UTF8 = Arquivo RMarkdown em pt

## Síntese de termos com o uso do pacote litsearchr   

# [Grames et al. 2019:](https://elizagrames.github.io/litsearchr/)  


### Termos iniciais (Pesquisa ingênua)


# "insect*" OR "herbivore*" OR "phytophag*" AND "induced plant defen*e" OR "plant defen*e" AND "natural enem*" AND  "predator* response" OR "parasitoid* response" OR "tritrophic interaction"`

### Separação dos termos em categorias para pesquisa no *Web of Science* e *Scopus*

## -   Herbivoria multipla;
##-   Defesas das plantas;
##-   Inimigos naturais


##xSeguindo o tutorial de desta página: 
  
##  [Tutorial Litsearchr:](https://luketudge.github.io/litsearchr-tutorial/litsearchr_tutorial.html)

##E os videos das aulas do Professor Eduardo Santos 
##[USP:](https://www.youtube.com/watch?v=La14D0Hpjb0) explica o funcionamento da ferramenta, mas o script dele est? desatualizado.


### Pacotes que precisam ser immportados


install.packages("remotes")
library(remotes)
install_github("elizagrames/litsearchr", ref="main")
install.packages("https://cran.r-project.org/src/contrib/Archive/rlang/rlang_0.4.10.tar.gz", repos = NULL, type="source")

library(litsearchr)
library(devtools)
library(revtools)
library(stringi)
library(stringr)
library(bibtex)
library(dplyr)


### Importar tabela inicial dos artigos encontrados com os termos da busca ingênua 

#Local onde esta a base de artigos exportada e onde ficara salva a tabela final dos termos
setwd("C:/Users/Downloads/litserchr") #quanto mais simples a localizacao, menor a chance de erro de busca pelo R
#dir()


web<- read_bibliography("savedrecs.bib", return_df = TRUE)
scopus<- read_bibliography("scopus.bib", return_df = TRUE)

lista_artigos <- bind_rows(web,scopus)
View(lista_artigos)

#Remover duplicatas, criando outro banco de dados, se for o caso de haver muitos artigos 

artigos <- litsearchr::remove_duplicates(lista_artigos, "title", "string_osa")

## Extrair os termos que aparecem no banco de dados


#install.packages("stopwords")
library(stopwords)
rakedkeywords =
  litsearchr::extract_terms(
    text=paste(artigos$title,artigos$abstract, artigos$keywords, artigos$keywords_plus), #colunas de onde serao extraidos os termos para elencar a maior ocorrencia
    method="fakerake",
    min_freq= 2, #numero minimo de ocorrencia
    ngrams= TRUE,
    min_n = 2,#numero minimo de vezes que a palavra deve aparecer nas frases dos textos
    language= "English"
  )

#Criar matriz de ocorrencia dos termos em cada um dos textos "document feature matrix", com **palavras-chave potenciais**
#criar a rede de co-ocorrencia dos termos e relevancia(frequencia)
#creatnetwork
naivedfm <-
  litsearchr::create_dfm(
    elements = paste(artigos$title, artigos$abstract, artigos$keywords, artigos$keywords_plus),
    features = rakedkeywords)

naivegraph <-
  litsearchr::create_network(
    search_dfm = naivedfm,
    min_studies = 2,
    min_occ = 2)

#termos de busca em potencial que mais representam um termo de busca em potencial
#maneiras de dar importancia a cada nÃ³ (local e magnetude de cada nÃ³)
#restringir os termos
cutoff <-
  litsearchr::find_cutoff(
    naivegraph,
    method = "cumulative",
    percent = .70,
    imp_method = "strength"
  )
#o resultado Ã© um histograma que dÃ¡ o limiar de importÃ¢ncia pelo algoritmo

#aplicar o ponto de de cutoff para a matriz de co-ocorrÃªncia
reducedgraph <-
  litsearchr::reduce_graph(naivegraph, cutoff_strength = cutoff[1])

searchterms <- litsearchr::get_keywords(reducedgraph)

head(searchterms, 20)


## Criar um objeto com termos de busca que a gente pode exportar

write.csv(searchterms, "search_terms.csv")
#cria planilha de artigos .csv
#termos relevantes com co-ocorrencias e sÃ£o considerados relevantes pelo litsearch,
#co-ocorrem nos documentos pesquisados
#deve ser revisados e assim reconstruir as palavras-chave
#a partir dai refazer a busca de artigos

## Última etapa para a criaÃ§Ã£o da tabela final com os artigos que serÃ£o utilizados na Meta-anÃ¡lise

## Depois da análise com o Litsearchr


setwd("C:/Users/Downloads/litserchr")

# importar dados inocentes
# exporta as referencias das bases para o Endnote e junta elas lÃ¡
# baixa em .bib (vai aparecer txt aqui)
# 
#table <- read.table("savedrecs.txt", head = T)

#t <- read.csv( "savedrecs-_1_.csv", sep = ",")
#head(t)

a<- read_bibliography("savedrecs_n.bib", return_df = TRUE)
b<- read_bibliography("scopus_n.bib", return_df = TRUE)

lista_unica <- bind_rows(a,b)
head(lista_unica)

lista <- litsearchr::remove_duplicates(lista_unica, "title", "string_osa")

#install.packages("writexl")
library(writexl)

write_xlsx(lista,"lista_artigos.xlsx")
