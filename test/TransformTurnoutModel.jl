#!/usr/bin/env julia
# -*- coding: UTF-8 -*-
# __julia-version__ = 1.7.0
# __author__        = "Martin Scheidt"
# __copyright__     = "2018-2024"
# __license__       = "ISC"

include("../src/ChangeTurnoutModel.jl")
import .ChangeTurnoutModel

module TransformTurnoutModel
#
# convert from old to new turnout model
ChangeTurnoutModel.replaceModel!("data/snippets/junction1.yaml")
ChangeTurnoutModel.replaceModel!("data/snippets/junction2.yaml")
ChangeTurnoutModel.replaceModel!("data/snippets/2_physical_buelten.yaml")
ChangeTurnoutModel.replaceModel!("data/snippets/2_physical_pockelsdorf.yaml")
ChangeTurnoutModel.replaceModel!("data/snippets/2_physical_rebenau.yaml")
ChangeTurnoutModel.replaceModel!("data/snippets/2_physical_schleinitz.yaml")
ChangeTurnoutModel.replaceModel!("data/layers/physical.yaml")

end # module TransformTurnoutModel
