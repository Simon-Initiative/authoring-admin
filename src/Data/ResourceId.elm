module Data.ResourceId exposing (ResourceId, decoder, encode, toHtml, toString, urlParser)

import Html exposing (Html)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Url.Parser



-- TYPES


type ResourceId
    = ResourceId String



-- CREATE


decoder : Decoder ResourceId
decoder =
    Decode.map ResourceId Decode.string



-- TRANSFORM


encode : ResourceId -> Value
encode (ResourceId id) =
    Encode.string id


toString : ResourceId -> String
toString (ResourceId id) =
    id


urlParser : Url.Parser.Parser (ResourceId -> a) a
urlParser =
    Url.Parser.custom "RESOURCEID" (\str -> Just (ResourceId str))


toHtml : ResourceId -> Html msg
toHtml (ResourceId id) =
    Html.text id
