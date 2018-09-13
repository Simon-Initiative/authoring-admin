module Data.PackageDetails exposing (PackageDetails, retrievePackageDetails, setPackageVisible, setPackageEditable, PkgEditable, PkgVisible)

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

setPackageVisible: Guid -> Bool -> String -> Http.Request PkgVisible
setPackageVisible courseId visible token =
    let
        headers =
            [Http.header
                "Accept"
                "application/json"
            , Http.header
                "Authorization"
                ("Bearer "
                    ++ token
                )
            ]


        url = Url.crossOrigin "http://dev.local" ["content-service", "api", "v1", "packages", "set","visible"]
            [Url.string "visible" ((\n -> if n then "true" else "false") visible)]

        body = Encode.list Encode.string [Data.Guid.toString courseId]
                |> Http.jsonBody
    in
    Http.request
        { method = "POST"
        , headers = headers
        , url = url
        , body = body
        , expect = Http.expectJson pkgVisibleDecoder
        , timeout = Nothing
        , withCredentials = False
        }

setPackageEditable: Guid -> Bool -> String -> Http.Request PkgEditable
setPackageEditable courseId editable token =
    let
        headers =
            [ Http.header
                "Accept"
                "application/json"
            , Http.header
                "Authorization"
                ("Bearer "
                    ++ token
                )
            ]

        url = Url.crossOrigin "http://dev.local" ["content-service", "api", "v1", "packages", "set", "editable"]
            [Url.string "editable" ((\n -> if n then "true" else "false") editable)]

        body = Encode.list Encode.string [Data.Guid.toString courseId]
                |> Http.jsonBody
    in
    Http.request
        { method = "POST"
        , headers = headers
        , url = url
        , body = body
        , expect = Http.expectJson pkgEditableDecoder
        , timeout = Nothing
        , withCredentials = False
        }

type alias PkgEditable =
    { locked : String
    , packages : List String
    }

pkgEditableDecoder : Decoder PkgEditable
pkgEditableDecoder =
  succeed PkgEditable
          |> required "editable" string
          |> required "packages" (list string)

type alias PkgVisible =
    { hidden : String
    , packages : List String
    }
pkgVisibleDecoder : Decoder PkgVisible
pkgVisibleDecoder =
  succeed PkgVisible
          |> required "visible" string
          |> required "packages" (list string)