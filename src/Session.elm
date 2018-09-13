module Session exposing (Session)

import Browser.Navigation as Nav
import Theme exposing (Theme)


-- TYPES


type alias Session =
    { navKey : Nav.Key
    , token : String
    }
