module Data.Package exposing (BuildStatus(..), Package, sortPackages, buildStatusDecoder, packageDecoder, packagesDecoder, retrievePackages)

import Data.Guid exposing (Guid, decoder)
import Data.ResourceId exposing (ResourceId, decoder)
import Html exposing (..)
import Http
import Json.Decode exposing (Decoder, fail, float, int, list, nullable, string, succeed, bool)
import Json.Decode.Pipeline exposing (hardcoded, optional, required)
import NaturalOrdering
import Array 

type BuildStatus
    = Ready
    | Building
    | Failed
    | Processing


type alias Package =
    { guid : Guid
    , id : ResourceId
    , version : String
    , title : String
    , description : String
    , visible : Bool
    , editable : Bool
    , buildStatus : BuildStatus
    }

type alias Version =
    { a: Int
    , b: Int
    , c: Int
    }


safeGet index arr =
  case Array.get index arr of 
    Just v 
      -> Maybe.withDefault 0 (String.toInt v) 
    Nothing 
      -> 0

parseVersion : String -> Version  
parseVersion v = 
  let
    parts = String.split v "." |> Array.fromList
  in
    Version (safeGet 0 parts) (safeGet 1 parts) (safeGet 2 parts) 

compareVersion : Version -> Version -> Order
compareVersion a b =
  case compare a.a b.a of 
    EQ -> 
      case compare a.b b.b of 
        EQ ->
          compare a.c b.c 
        LT -> 
          LT   
        GT ->  
          GT 
    LT ->   
      LT    
    GT -> 
      GT

packageCompare : Package -> Package -> Order 
packageCompare a b =
  case NaturalOrdering.compare a.title b.title of
    EQ -> 
      let
        v1 = parseVersion a.version 
        v2 = parseVersion b.version 
      in
        compareVersion v1 v2 

    LT -> LT 
    GT -> GT

sortPackages : (List Package) -> (List Package)
sortPackages packages =
  List.sortWith packageCompare packages

retrievePackages token baseUrl =
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
            baseUrl ++ "/content-service/api/v1/packages"
    in
    Http.request
        { method = "GET"
        , headers = headers
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectJson packagesDecoder
        , timeout = Nothing
        , withCredentials = False
        }


buildStatusDecoder : Decoder BuildStatus
buildStatusDecoder =
    Json.Decode.string
        |> Json.Decode.andThen
            (\s ->
                case s of
                    "READY" ->
                        succeed Ready

                    "FAILED" ->
                        succeed Failed

                    "BUILDING" ->
                        succeed Building

                    "PROCESSING" ->
                        succeed Processing

                    _ ->
                        fail <| "I don't know how to decode " ++ s
            )


packagesDecoder : Decoder (List Package)
packagesDecoder =
    list packageDecoder


packageDecoder : Decoder Package
packageDecoder =
    succeed Package
        |> required "guid" Data.Guid.decoder
        |> required "id" Data.ResourceId.decoder
        |> required "version" string
        |> required "title" string
        |> required "description" string
        |> required "visible" bool
        |> required "editable" bool
        |> required "buildStatus" buildStatusDecoder
