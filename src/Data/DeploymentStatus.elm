module Data.DeploymentStatus exposing (..)

import Html exposing (Html)
import Json.Decode as Decode exposing (Decoder, succeed, fail, oneOf, null, map)
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
      Development -> "DEVELOPMENT"
      QA -> "QA"
      RequestingProduction -> "REQUESTING_PRODUCTION"
      Production -> "PRODUCTION"


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