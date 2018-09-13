module Data.Package exposing (BuildStatus(..), Package, buildStatusDecoder, packageDecoder, packagesDecoder, retrievePackages)

import Data.Guid exposing (Guid, decoder)
import Data.ResourceId exposing (ResourceId, decoder)
import Html exposing (..)
import Http
import Json.Decode exposing (Decoder, fail, float, int, list, nullable, string, succeed, bool)
import Json.Decode.Pipeline exposing (hardcoded, optional, required)


type BuildStatus
    = Ready
    | Building
    | Processing


type alias Package =
    { guid : Guid
    , id : ResourceId
    , version : String
    , title : String
    , description : String
    , visible : Bool
    , editable : Bool
    , buildStatus : BuildStatus
    }


retrievePackages token =
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
            "http://dev.local/content-service/api/v1/packages/editable"
    in
    Http.request
        { method = "GET"
        , headers = headers
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectJson packagesDecoder
        , timeout = Nothing
        , withCredentials = False
        }


buildStatusDecoder : Decoder BuildStatus
buildStatusDecoder =
    Json.Decode.string
        |> Json.Decode.andThen
            (\s ->
                case s of
                    "READY" ->
                        succeed Ready

                    "BUILDING" ->
                        succeed Building

                    "PROCESSING" ->
                        succeed Processing

                    _ ->
                        fail <| "I don't know how to decode " ++ s
            )


packagesDecoder : Decoder (List Package)
packagesDecoder =
    list packageDecoder


packageDecoder : Decoder Package
packageDecoder =
    succeed Package
        |> required "guid" Data.Guid.decoder
        |> required "id" Data.ResourceId.decoder
        |> required "version" string
        |> required "title" string
        |> required "description" string
        |> required "visible" bool
        |> required "editable" bool
        |> required "buildStatus" buildStatusDecoder
