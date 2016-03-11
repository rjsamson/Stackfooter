module Models (..) where

type alias AppModel =
  { ticker : String }

initialModel : AppModel
initialModel =
  { ticker = "NYC" }
