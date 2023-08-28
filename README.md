# Railway Layer Model

## About

This repository is the supplement data for the dissertation *"Charting the Railway Infrastructure Design Process - with a layer model from topology to transport"*. The main result is the `schema/layer_model.json` file with the dissertation result in the [JSON schema](https://json-schema.org) format. The result was achieved by following the [Design Science Research](https://doi.org/10.2307/25148625) method, which consists of cycles. The cycles are documented in the `DSR_cycles` folder and the git commits of this repository. At the same time, the final result of the DSR cycles is an artefact in the `/` respectively folders `data/layers`, `schema`, `src`, and `test`. Julia and YAML were used for data transformation and data input.

## Content

* `data/raw`: Input data for the DSR cycles - a fictitious network used by teaching at the Institute of Railway Systems Engineering and Traffic Safety at Technical University Braunschweig.

* `data/layers`: Converted raw input data into YAML files according to `schema/layer_model.json`.

* `data/snippets`: Selected YAML snippets to test the modelling of the object referred to in the snippet name.

* `DSR_cycles`: Documented progress in each of the eight DSR cycles. Please also refer to the commits of the git repository.

* `schema`: The final JSON schema file to validate the YAML files in the data/layers and the data/snippets folder. This can be done, for example, with [Ajv JSON schema validator](https://ajv.js.org) with the following command for the _base layer_: 

```bash
ajv --spec=draft2020 -c ajv-formats -s schema/layer_model.json -d data/layers/base.yaml
```

* `src`,`test`: Julia code for data transformation, plausibility, and validation tests while constructing the DSR artefact.

* `TODO.md`: A collection of thoughts where the Railway Layer Model still needs improvement.

* `insights.md`: A collection of thoughts during each DSR cycle for each layer.

## copyright

The Julia code and the YAML/JSON files are under the ISC license. In contrast, parts of the raw data are under *_all rights reserved_* from different authors. Please refer to the LICENSE.md file for further information.