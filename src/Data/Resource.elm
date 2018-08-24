module Data.Resource exposing (Resource, ResourceState(..), resourcesDecoder)

import Data.Guid exposing (Guid, decoder)
import Data.ResourceId exposing (ResourceId, decoder)
import Html exposing (..)
import Http
import Json.Decode exposing (Decoder, fail, float, int, list, nullable, string, succeed)
import Json.Decode.Pipeline exposing (hardcoded, optional, required)


type ResourceType
    = Package
    | Organization
    | WorkbookPage
    | FormativeAssessment
    | SummativeAssessment
    | LearningObjectives
    | Skills
    | WebContent
    | QuestionPool


type ResourceState
    = Active
    | Deleted


type alias Resource =
    { guid : Guid
    , id : ResourceId
    , resourceType : String
    , shortTitle : Maybe String
    , title : String
    , state : ResourceState
    , dateCreated : String
    , dateUpdated : String
    , file : FileNode
    , revision : Int
    }


type alias FileNode =
    { pathFrom : String
    , pathTo : String
    , fileSize : Int
    }


buildStateDecoder : Decoder ResourceState
buildStateDecoder =
    Json.Decode.string
        |> Json.Decode.andThen
            (\s ->
                case s of
                    "ACTIVE" ->
                        succeed Active

                    "DELETED" ->
                        succeed Deleted

                    _ ->
                        fail <| "I don't know how to decode " ++ s
            )


resourcesDecoder : Decoder (List Resource)
resourcesDecoder =
    list resourceDecoder


resourceDecoder : Decoder Resource
resourceDecoder =
    succeed Resource
        |> required "guid" Data.Guid.decoder
        |> required "id" Data.ResourceId.decoder
        |> required "type" string
        |> required "shortTitle" (nullable string)
        |> optional "title" string "<missing title>"
        |> required "resourceState" buildStateDecoder
        |> required "dateCreated" string
        |> required "dateUpdated" string
        |> required "fileNode" fileNodeDecoder
        |> required "rev" int


fileNodeDecoder : Decoder FileNode
fileNodeDecoder =
    succeed FileNode
        |> required "pathFrom" string
        |> required "pathTo" string
        |> required "fileSize" int
