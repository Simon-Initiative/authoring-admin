module Data.UserSession exposing (UserSession, logoutAllUsers, logoutUser, retrieveUserSessions)

import Data.Guid exposing (Guid, decoder)
import Data.ResourceId exposing (ResourceId, decoder)
import Dict exposing (Dict)
import Html exposing (..)
import Http
import Json.Decode exposing (Decoder, dict, fail, float, int, list, nullable, string, succeed)
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


retrieveUserSessions token clientId baseUrl =
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
            baseUrl ++ "/auth/admin/realms/oli_security/clients/" ++ clientId ++ "/user-sessions"
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


logoutUser token userId baseUrl =
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
            baseUrl ++ "/auth/admin/realms/oli_security/users/" ++ userId ++ "/logout"
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


logoutAllUsers token baseUrl =
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
            baseUrl ++ "/auth/admin/realms/oli_security/logout-all"
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
