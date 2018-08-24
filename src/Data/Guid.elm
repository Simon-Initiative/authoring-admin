module Data.Guid exposing (Guid, decoder, encode, toHtml, toString, urlParser)

import Html exposing (Html)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Url.Parser



-- TYPES


type Guid
    = Guid String



-- CREATE


decoder : Decoder Guid
decoder =
    Decode.map Guid Decode.string



-- TRANSFORM


encode : Guid -> Value
encode (Guid id) =
    Encode.string id


toString : Guid -> String
toString (Guid id) =
    id


urlParser : Url.Parser.Parser (Guid -> a) a
urlParser =
    Url.Parser.custom "GUID" (\str -> Just (Guid str))


toHtml : Guid -> Html msg
toHtml (Guid id) =
    Html.text id
