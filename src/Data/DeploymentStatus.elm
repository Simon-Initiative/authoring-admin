module Data.DeploymentStatus exposing (DeploymentStatus(..), decoder, encode, parseStatus, toString)

import Html exposing (Html)
import Json.Decode as Decode exposing (Decoder, fail, map, null, oneOf, succeed)
import Json.Encode as Encode exposing (Value)
import Url.Parser



-- TYPES


type DeploymentStatus
    = Development
    | RequestingQA
    | QA
    | RequestingProduction
    | Production



-- CREATE


parseStatus statusText =
    case statusText of
        "Development" ->
            Development

        "Requesting QA" ->
            RequestingQA

        "QA" ->
            QA

        "Requesting Production" ->
            RequestingProduction

        "Production" ->
            Production

        _ ->
            Development


decoder : Decoder (Maybe DeploymentStatus)
decoder =
    oneOf
        [ null Nothing
        , Decode.string
            |> Decode.andThen
                (\s ->
                    case s of
                        "DEVELOPMENT" ->
                            map Just <| succeed Development

                        "REQUESTING_QA" ->
                            map Just <| succeed RequestingQA

                        "QA" ->
                            map Just <| succeed QA

                        "REQUESTING_PRODUCTION" ->
                            map Just <| succeed RequestingProduction

                        "PRODUCTION" ->
                            map Just <| succeed Production

                        _ ->
                            succeed Nothing
                )
        ]



-- TRANSFORM
-- encode to the string parameter value the content service is looking for


encode : DeploymentStatus -> String
encode status =
    case status of
        Development ->
            "DEVELOPMENT"

        RequestingQA ->
            "REQUESTING_QA"

        QA ->
            "QA"

        RequestingProduction ->
            "REQUESTING_PRODUCTION"

        Production ->
            "PRODUCTION"


toString : DeploymentStatus -> String
toString status =
    case status of
        Development ->
            "Development"

        RequestingQA ->
            "Requesting QA"

        QA ->
            "QA"

        RequestingProduction ->
            "Requesting Production"

        Production ->
            "Production"
