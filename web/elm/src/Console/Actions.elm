module Console.Actions (..) where

import Console.Models exposing (..)

type Action
  = NoOp
  | UpdateTicker Model
