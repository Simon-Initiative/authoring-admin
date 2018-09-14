module Data.SessionClient exposing (SessionClient, retrieveSessionClients)

import Data.Guid exposing (Guid, decoder)
import Data.ResourceId exposing (ResourceId, decoder)
import Html exposing (..)
import Http
import Dict exposing (Dict)
import Json.Decode exposing (Decoder, fail, float, int, list, nullable, string, dict, succeed)
import Json.Decode.Pipeline exposing (hardcoded, optional, required)


type alias SessionClient =
    { id : String
    , active : String
    , clientId : String
    }


retrieveSessionClients token =
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
            "http://dev.local/auth/admin/realms/oli_security/client-session-stats"
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
