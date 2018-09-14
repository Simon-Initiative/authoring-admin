module Data.UserSession exposing (UserSession, retrieveUserSessions, logoutUser, logoutAllUsers)

import Data.Guid exposing (Guid, decoder)
import Data.ResourceId exposing (ResourceId, decoder)
import Html exposing (..)
import Http
import Dict exposing (Dict)
import Json.Decode exposing (Decoder, fail, float, int, list, nullable, string, dict, succeed)
import Json.Decode.Pipeline exposing (hardcoded, optional, required)

type alias UserSession =
    { id : String
    , username : String
    , userId : String
    , ipAddress : String
    , start : Int
    , lastAccess : Int
    , clients : Dict String String
    }

retrieveUserSessions token clientId =
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
            "http://dev.local/auth/admin/realms/oli_security/clients/" ++ clientId ++ "/user-sessions"
    in
    Http.request
        { method = "GET"
        , headers = headers
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectJson sessionsDecoder
        , timeout = Nothing
        , withCredentials = False
        }

logoutUser token userId =
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
            "http://dev.local/auth/admin/realms/oli_security/users/" ++ userId ++ "/logout"
    in
    Http.request
        { method = "POST"
        , headers = headers
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectJson (succeed ())
        , timeout = Nothing
        , withCredentials = False
        }

logoutAllUsers token =
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

        url = "http://dev.local/auth/admin/realms/oli_security/logout-all"
    in
    Http.request
        { method = "POST"
        , headers = headers
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectJson (succeed ())
        , timeout = Nothing
        , withCredentials = False
        }

sessionsDecoder : Decoder (List UserSession)
sessionsDecoder =
    list sessionDecoder


sessionDecoder : Decoder UserSession
sessionDecoder =
    succeed UserSession
        |> required "id" string
        |> required "username" string
        |> required "userId" string
        |> required "ipAddress" string
        |> required "start" int
        |> required "lastAccess" int
        |> required "clients" (dict string)
