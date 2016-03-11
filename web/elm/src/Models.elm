module Models (..) where

type alias AppModel =
  { ticker : String
  , venue : String
  , bid : Int
  , ask : Int
  , price : Int
  , bidSize : Int
  , askSize : Int
  , bidDepth : Int
  , askDepth : Int
  }

initialModel : AppModel
initialModel =
  { ticker = "NYC"
  , venue = "OBEX"
  , bid = 4000
  , ask = 4100
  , price = 4050
  , bidSize = 10
  , askSize = 10
  , bidDepth = 100
  , askDepth = 100
  }
