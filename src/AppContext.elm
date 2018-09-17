module AppContext exposing (AppContext)

import Data.User exposing (User)
import Session exposing (Session)
import Theme exposing (Theme)



-- TYPES


type alias AppContext =
    { session : Session
    , theme : Theme
    , userProfile : User
    , logoutUrl : String
    , baseUrl : String
    }
