#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.7.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2021"
# __license__       = "ISC"

include("../src/ChangeTurnoutModel.jl")
import .ChangeTurnoutModel

module TransformTurnoutModel
#
# convert from old to new turnout model
ChangeTurnoutModel.replaceModel!("example_data/snippets/junction1.yaml")
ChangeTurnoutModel.replaceModel!("example_data/snippets/junction2.yaml")
ChangeTurnoutModel.replaceModel!("example_data/snippets/2_physical_buelten.yaml")
ChangeTurnoutModel.replaceModel!("example_data/snippets/2_physical_pockelsdorf.yaml")
ChangeTurnoutModel.replaceModel!("example_data/snippets/2_physical_rebenau.yaml")
ChangeTurnoutModel.replaceModel!("example_data/snippets/2_physical_schleinitz.yaml")
ChangeTurnoutModel.replaceModel!("example_data/layer/2_physical.yaml")

end # module TransformTurnoutModel
