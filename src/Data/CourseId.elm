module Data.CourseId exposing (CourseId, decoder, encode, toHtml, toString, urlParser)

import Html exposing (Html)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Url.Parser



-- TYPES


type CourseId
    = CourseId String



-- CREATE


decoder : Decoder CourseId
decoder =
    Decode.map CourseId Decode.string



-- TRANSFORM


encode : CourseId -> Value
encode (CourseId id) =
    Encode.string id


toString : CourseId -> String
toString (CourseId id) =
    id


urlParser : Url.Parser.Parser (CourseId -> a) a
urlParser =
    Url.Parser.custom "COURSEID" (\str -> Just (CourseId str))


toHtml : CourseId -> Html msg
toHtml (CourseId id) =
    Html.text id
