<!-- README.pt-BR.md é a versão em português deste README. -->

# deriva

<!-- badges: start -->
[![R-CMD-check](https://github.com/bonijoao/deriva/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/bonijoao/deriva/actions/workflows/R-CMD-check.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
<!-- badges: end -->

**Read this in other languages:** [English](README.md)

O `deriva` detecta **deriva de conceito** (*concept drift*) e **deriva de dados**
(*data drift*) em fluxos produzidos por modelos de machine learning em produção,
através de uma interface tidy que compõe naturalmente com o ecossistema
`tidymodels`. Detectores são especificados, ajustados sobre um período de
referência (*baseline*) e avançados sobre novos lotes de observações, retornando
tibbles anotadas com sinalizações de aviso e deriva.

Um modelo de machine learning treinado com dados históricos assume implicitamente
que o processo gerador dos dados permanece estável ao longo do tempo. Quando essa
suposição deixa de valer — o comportamento do usuário muda, um sensor perde
calibração, o mercado se transforma — as previsões pioram silenciosamente, sem
nenhum erro óbvio ser levantado. O `deriva` observa um fluxo de sinais por
observação (tipicamente erros de previsão) e sinaliza o momento em que a
distribuição subjacente mudou.

O pacote traz um catálogo de **22 detectores de deriva sequenciais**, cobrindo
tanto métodos baseados em erro (DDM, EDDM, HDDM, EWMA, ...) quanto métodos
baseados em distribuição (ADWIN, KSWIN, Page-Hinkley, ...).

## Instalação

```r
# Do GitHub (versão de desenvolvimento)
# install.packages("pak")
pak::pak("bonijoao/deriva")
```

Assim que for aceito no CRAN:

```r
install.packages("deriva")
```

## Começo rápido

```r
library(deriva)

# Simula um fluxo: 500 observações estáveis, depois 500 com taxa de erro maior
stream <- sim_drift_stream(
  n_pre = 500, n_post = 500,
  p_pre = 0.05, p_post = 0.30,
  seed = 42
)

resultado <- detect_drift(stream, .col = error, method = "ddm")

# Onde a deriva foi sinalizada?
subset(resultado, .drift)
```

## A interface do deriva

O `deriva` segue o mesmo padrão de três verbos do tidymodels: **especificar → ajustar → avançar**.

```r
drift_detector("ddm") |>           # especificar: um spec inerte, sem computação ainda
  fit(baseline, signal = error) |> # ajustar: aprende o nível de referência (baseline)
  advance(novo_lote)               # avançar: atualiza o estado, sinaliza deriva, guarda histórico
```

O objeto ajustado é imutável — `advance()` retorna um objeto **novo** com o
estado interno do motor atualizado e o lote anotado anexado ao histórico; o
objeto original permanece intacto, o que permite repetir ou ramificar um fluxo
livremente.

Verbos complementares, seguindo a convenção do `broom`/tidymodels, facilitam
inspecionar os resultados a qualquer momento:

* `augment()` — o histórico completo anotado, como uma tibble
* `tidy()` — os pontos de deriva detectados
* `glance()` — um resumo de uma linha só
* `autoplot()` — um gráfico pronto do sinal com marcações de aviso/deriva

## Ponte com o tidymodels

`add_prediction_error()` converte a saída de um `augment()` do tidymodels
(que contém colunas de verdade e estimativa) em uma coluna `.error` que os
detectores de deriva conseguem consumir diretamente — o erro absoluto para
regressão, um indicador 0/1 de acerto/erro para classificação.

```r
modelo |>
  augment(new_data = dados_producao) |>
  add_prediction_error(truth = y) |>
  drift_detector("page_hinkley") |>
  fit(., signal = .error)
```

## Métodos disponíveis

| Tipo de sinal | Métodos |
|---|---|
| `"error"` (0/1 ou erro contínuo) | `ddm`, `eddm`, `hddm_a`, `hddm_w`, `ewma`, `rddm`, `stepd`, `fhddm`, `fhddms`, `mddm_a`, `mddm_e`, `mddm_g`, `wstd`, `ftdd`, `fpdd`, `fsdd`, `cusum` |
| `"distribution"` (fluxo numérico) | `kswin`, `adwin`, `page_hinkley`, `seed`, `seqdrift2` |

Use `drift_detector("<método>")` para inspecionar os hiperparâmetros padrão de
qualquer método.

Veja `vignette("deriva")` para um passo a passo completo (em inglês).

## Licença

MIT © deriva authors — veja [LICENSE](LICENSE).
