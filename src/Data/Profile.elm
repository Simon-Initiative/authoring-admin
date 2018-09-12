module Data.Profile exposing (Profile)


type alias Profile =
    { id : String
    , username : String
    , emailVerified : Bool
    , firstName : String
    , lastName : String
    , email : String
    }
