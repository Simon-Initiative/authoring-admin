module Data.UserDetails exposing (retrieveUserDetails, resetPassword)

import Data.User exposing (User, userDecoder)
import Data.Guid exposing (Guid, decoder)
import Data.Resource exposing (Resource, resourcesDecoder)
import Data.ResourceId exposing (ResourceId, decoder, toString)
import Html exposing (..)
import Http
import Json.Decode exposing (Decoder, fail, float, int, list, nullable, string, succeed)
import Json.Decode.Pipeline exposing (hardcoded, optional, required)

resetPassword userId token =
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
            "http://dev.local/auth/admin/realms/oli_security/users/" ++ Data.Guid.toString userId ++ "/reset-password"
    in
    Http.request
        { method = "PUT"
        , headers = headers
        , url = url
        , body = Http.stringBody "pass" "temp-password"
        , expect = Http.expectJson userDecoder
        , timeout = Nothing
        , withCredentials = False
        }


retrieveUserDetails userId token =
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
            "http://dev.local/auth/admin/realms/oli_security/users/" ++ Data.Guid.toString userId
    in
    Http.request
        { method = "GET"
        , headers = headers
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectJson userDecoder
        , timeout = Nothing
        , withCredentials = False
        }