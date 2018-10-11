module Data.DeploymentStatus exposing (..)

import Html exposing (Html)
import Json.Decode as Decode exposing (Decoder, succeed, fail)
import Json.Encode as Encode exposing (Value)
import Url.Parser


-- TYPES


type DeploymentStatus
    = Development
    | QA
    | RequestingProduction
    | Production


-- CREATE

parseStatus statusText =
    case statusText of
        "Development" ->
            Development

        "QA" ->
            QA

        "Requesting Production" ->
            RequestingProduction

        "Production" ->
            Production
            
        _ ->
            Development


decoder : Decoder DeploymentStatus
decoder =
    Decode.string
        |> Decode.andThen
            (\s ->
                case s of
                    "DEVELOPMENT" ->
                        succeed Development

                    "QA" ->
                        succeed QA

                    "REQUESTING_PRODUCTION" ->
                        succeed RequestingProduction

                    "PRODUCTION" ->
                        succeed Production

                    _ ->
                        fail <| "I don't know how to decode " ++ s
            )


-- TRANSFORM


-- encode : DeploymentStatus -> Value
-- encode DeploymentStatus =
--     Encode.string


toString : DeploymentStatus -> String
toString status =
    case status of
        Development ->
            "Development"

        QA ->
            "QA"

        RequestingProduction ->
            "Requesting Production"

        Production ->
            "Production"