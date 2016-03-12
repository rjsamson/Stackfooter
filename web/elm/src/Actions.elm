module Actions (..) where

import Models exposing (..)

type Action
  = NoOp
  | UpdateTicker AppModel
