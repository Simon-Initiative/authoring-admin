module AppContext exposing (AppContext)

import Session exposing (Session)
import Theme exposing (Theme)


-- TYPES


type alias AppContext =
    { session : Session
    , theme : Theme
    }
