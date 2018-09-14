module AppContext exposing (AppContext)

import Session exposing (Session)
import Theme exposing (Theme)
import Data.User exposing (User)

-- TYPES


type alias AppContext =
    { session : Session
    , theme : Theme
    , userProfile : User
    , logoutUrl : String
    }
