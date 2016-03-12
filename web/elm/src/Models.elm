module Models (..) where

type alias AppModel =
  { symbol : String
  , venue : String
  , bid : Int
  , ask : Int
  , last : Int
  , bidSize : Int
  , askSize : Int
  , bidDepth : Int
  , askDepth : Int
  , lastSize : Int
  , lastTrade : String
  , quoteTime : String
  }

initialModel : AppModel
initialModel =
  { symbol = "NYC"
  , venue = "OBEX"
  , bid = 4000
  , ask = 4100
  , last = 4050
  , bidSize = 10
  , askSize = 10
  , bidDepth = 100
  , askDepth = 100
  , lastSize = 10
  , lastTrade = ""
  , quoteTime = ""
  }
