module Data.PackageDetails exposing (PackageDetails, retrievePackageDetails)

import Data.Guid exposing (Guid, decoder)
import Data.Resource exposing (Resource, resourcesDecoder)
import Data.ResourceId exposing (ResourceId, decoder, toString)
import Html exposing (..)
import Http
import Json.Decode exposing (Decoder, fail, float, int, list, nullable, string, succeed)
import Json.Decode.Pipeline exposing (hardcoded, optional, required)


type alias PackageDetails =
    { guid : Guid
    , id : ResourceId
    , title : String
    , resources : List Resource
    }


retrievePackageDetails courseId token baseUrl =
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
            baseUrl ++ "/content-service/api/v1/packages/" ++ Data.Guid.toString courseId ++ "/details"
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
        |> required "resources" resourcesDecoder
