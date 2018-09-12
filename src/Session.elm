module Session exposing (Session)

import Browser.Navigation as Nav
import Data.Profile exposing (Profile)



-- TYPES


type alias Session =
    { navKey : Nav.Key
    , token : String
    , baseUrl : String
    , profile : Profile
    }
