module Data.User exposing (PackageMembership, PackageRole, Title, User, retrieveUsers)

import Data.Guid exposing (Guid, decoder, toGuid)
import Data.ResourceId exposing (ResourceId, decoder)
import Data.Username exposing (Username, decoder)
import Dict exposing (Dict)
import Html exposing (..)
import Http
import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (hardcoded, optional, required)


type alias User =
    { id : Guid
    , username : Username
    , enabled : Bool
    , firstName : String
    , lastName : String
    , email : String
    , packages : List PackageMembership
    }


type alias PackageMembership =
    { guid : Guid
    , title : Title
    , role : PackageRole
    }


type alias Title =
    String


type PackageRole
    = Reviewer
    | Contributor


retrieveUsers token =
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
            "http://dev.local/auth/admin/realms/oli_security/users"
    in
    Http.request
        { method = "GET"
        , headers = headers
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectJson usersDecoder
        , timeout = Nothing
        , withCredentials = False
        }


extractTitle : List String -> String
extractTitle list =
    List.foldl getTitle "missing title" list


getTitle : String -> String -> String
getTitle str accum =
    case str of
        "urn:content-service:scopes:view_material" ->
            accum

        "urn:content-service:scopes:edit_material" ->
            accum

        "ContentPackage" ->
            accum

        _ ->
            str


convertToPackages : List ( String, List String ) -> List PackageMembership
convertToPackages list =
    List.map (\( guid, items ) -> PackageMembership (toGuid guid) (extractTitle items) Contributor) list


packagesDecoder : Decoder (List ( String, List String ))
packagesDecoder =
    keyValuePairs (list string)


goodDecoder : Decoder (List PackageMembership)
goodDecoder =
    Json.Decode.map convertToPackages (keyValuePairs (list string))


usersDecoder : Decoder (List User)
usersDecoder =
    list userDecoder


userDecoder : Decoder User
userDecoder =
    succeed User
        |> required "id" Data.Guid.decoder
        |> required "username" Data.Username.decoder
        |> required "enabled" bool
        |> required "firstName" string
        |> required "lastName" string
        |> required "email" string
        |> optional "attributes" goodDecoder []
