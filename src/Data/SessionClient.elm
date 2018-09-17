module Data.SessionClient exposing (SessionClient, retrieveSessionClients)

import Data.Guid exposing (Guid, decoder)
import Data.ResourceId exposing (ResourceId, decoder)
import Dict exposing (Dict)
import Html exposing (..)
import Http
import Json.Decode exposing (Decoder, dict, fail, float, int, list, nullable, string, succeed)
import Json.Decode.Pipeline exposing (hardcoded, optional, required)


type alias SessionClient =
    { id : String
    , active : String
    , clientId : String
    }


retrieveSessionClients token baseUrl =
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
            baseUrl ++ "/auth/admin/realms/oli_security/client-session-stats"
    in
    Http.request
        { method = "GET"
        , headers = headers
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectJson sessionClientsDecoder
        , timeout = Nothing
        , withCredentials = False
        }


sessionClientsDecoder : Decoder (List SessionClient)
sessionClientsDecoder =
    list clientDecoder


clientDecoder : Decoder SessionClient
clientDecoder =
    succeed SessionClient
        |> required "id" string
        |> required "active" string
        |> required "clientId" string
