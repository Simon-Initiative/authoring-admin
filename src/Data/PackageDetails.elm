module Data.PackageDetails exposing (PackageDetails, retrievePackageDetails, hidePackage, lockPackage, Locked, Hidden)

import Data.Guid exposing (Guid, decoder)
import Data.Resource exposing (Resource, resourcesDecoder)
import Data.ResourceId exposing (ResourceId, decoder, toString)
import Html exposing (..)
import Http
import Json.Decode exposing (Decoder, fail, float, int, list, nullable, string, succeed, bool)
import Json.Decode.Pipeline exposing (hardcoded, optional, required)
import Json.Encode as Encode
import Url.Builder as Url

type alias PackageDetails =
    { guid : Guid
    , id : ResourceId
    , title : String
    , visible: Bool
    , editable: Bool
    , resources : List Resource
    }


retrievePackageDetails courseId token =
    let
        headers =
            [ Http.header
                "Content-Type"
                "application/json"
            , Http.header
                "Accept"
                "application/json"
            , Http.header
                "Authorization"
                ("Bearer "
                    ++ token
                )
            ]

        url =
            "http://dev.local/content-service/api/v1/packages/" ++ Data.Guid.toString courseId ++ "/details"
    in
    Http.request
        { method = "GET"
        , headers = headers
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectJson detailsDecoder
        , timeout = Nothing
        , withCredentials = False
        }


detailsDecoder : Decoder PackageDetails
detailsDecoder =
    succeed PackageDetails
        |> required "guid" Data.Guid.decoder
        |> required "id" Data.ResourceId.decoder
        |> required "title" string
        |> required "visible" bool
        |> required "editable" bool
        |> required "resources" resourcesDecoder

hidePackage: Guid -> Bool -> String -> Http.Request Hidden
hidePackage courseId hide token =
    let
        headers =
            [ Http.header
                "Content-Type"
                "application/json"
            , Http.header
                "Accept"
                "application/json"
            , Http.header
                "Authorization"
                ("Bearer "
                    ++ token
                )
            ]


        url = Url.crossOrigin "http://dev.local" ["api", "v1", "packages", Data.Guid.toString courseId, "hide"]
            [Url.string "hide" ((\n -> if n then "true" else "false") hide)]

        body = Encode.list Encode.string [Data.Guid.toString courseId]
                |> Http.jsonBody
    in
    Http.request
        { method = "GET"
        , headers = headers
        , url = url
        , body = body
        , expect = Http.expectJson hiddenDecoder
        , timeout = Nothing
        , withCredentials = False
        }

lockPackage: Guid -> Bool -> String -> Http.Request Locked
lockPackage courseId lock token =
    let
        headers =
            [ Http.header
                "Content-Type"
                "application/json"
            , Http.header
                "Accept"
                "application/json"
            , Http.header
                "Authorization"
                ("Bearer "
                    ++ token
                )
            ]

        url = Url.crossOrigin "http://dev.local" ["api", "v1", "packages", Data.Guid.toString courseId, "lock"]
            [Url.string "lock" ((\n -> if n then "true" else "false") lock)]

        body = Encode.list Encode.string [Data.Guid.toString courseId]
                |> Http.jsonBody
    in
    Http.request
        { method = "POST"
        , headers = headers
        , url = url
        , body = body
        , expect = Http.expectJson lockDecoder
        , timeout = Nothing
        , withCredentials = False
        }

type alias Locked =
    { locked : String
    , packages : List String
    }

lockDecoder : Decoder Locked
lockDecoder =
  succeed Locked
          |> required "locked" string
          |> required "packages" (list string)

type alias Hidden =
    { hidden : String
    , packages : List String
    }
hiddenDecoder : Decoder Hidden
hiddenDecoder =
  succeed Hidden
          |> required "hidden" string
          |> required "packages" (list string)