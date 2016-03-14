module Ticker.Actions (..) where

import Ticker.Models exposing (..)

type Action
  = NoOp
  | UpdateTicker Model
