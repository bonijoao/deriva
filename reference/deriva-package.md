# deriva: Tidy Drift Detection for Monitored Machine Learning Models

Detects concept drift and data drift in streams produced by deployed
machine learning models, using a tidy interface that composes with the
'tidymodels' ecosystem. Detectors are specified, fitted on a baseline
period, and advanced over new batches of observations, returning tibbles
annotated with warning and drift flags. A catalogue of 22 sequential
drift detectors is provided. Error-based methods include the Drift
Detection Method (DDM) of Gama et al. (2004)
[doi:10.1007/978-3-540-28645-5_29](https://doi.org/10.1007/978-3-540-28645-5_29)
, the Early Drift Detection Method (EDDM) of Baena-Garcia et al. (2006),
the Hoeffding's inequality based Drift Detection Methods (HDDM) of
Frias-Blanco et al. (2015)
[doi:10.1109/TKDE.2014.2345382](https://doi.org/10.1109/TKDE.2014.2345382)
, and the Exponentially Weighted Moving Average (EWMA) chart of Ross et
al. (2012)
[doi:10.1016/j.patrec.2011.08.019](https://doi.org/10.1016/j.patrec.2011.08.019)
. Distribution-based methods include Adaptive Windowing (ADWIN) of Bifet
and Gavalda (2007)
[doi:10.1137/1.9781611972771.42](https://doi.org/10.1137/1.9781611972771.42)
, Kolmogorov-Smirnov Windowing (KSWIN) of Raab et al. (2020)
[doi:10.1016/j.neucom.2019.11.111](https://doi.org/10.1016/j.neucom.2019.11.111)
, and the Page-Hinkley test of Page (1954)
[doi:10.1093/biomet/41.1-2.100](https://doi.org/10.1093/biomet/41.1-2.100)
.

## See also

Useful links:

- <https://github.com/bonijoao/deriva>

- <https://bonijoao.github.io/deriva/>

- Report bugs at <https://github.com/bonijoao/deriva/issues>

## Author

**Maintainer**: João Paulo Assis Bonifácio <jpab.27@hotmail.com>
([ORCID](https://orcid.org/0009-0009-2335-8391))

Authors:

- Geraldo Magela da Cruz Pereira <geraldo.pereira@ufla.br>
  ([ORCID](https://orcid.org/0000-0001-6280-4870))

- Pedro Mambelli Fernandes <pedromambelli@gmail.com>
  ([ORCID](https://orcid.org/0009-0001-1695-279X))
