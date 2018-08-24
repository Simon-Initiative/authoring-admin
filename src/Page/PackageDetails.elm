module Page.PackageDetails exposing (Model, Msg, init, subscriptions, toSession, update, view)

import Browser.Navigation as Nav
import Data.Guid as Guid exposing (Guid)
import Data.Package as Package exposing (Package)
import Data.PackageDetails as PackageDetails exposing (PackageDetails, retrievePackageDetails)
import Data.Resource as Resource exposing (Resource, ResourceState)
import Data.ResourceId as ResourceId exposing (ResourceId)
import Data.Username as Username exposing (Username)
import Html exposing (Html, button, div, fieldset, h1, h3, input, li, text, textarea, ul)
import Html.Attributes exposing (attribute, class, placeholder, type_, value)
import Html.Events exposing (onInput, onSubmit)
import Http
import Json.Decode as Decode exposing (Decoder, decodeString, field, list, string)
import Json.Decode.Pipeline exposing (hardcoded, required)
import Json.Encode as Encode
import Loading
import Log
import Route
import Session exposing (Session)
import Task



-- MODEL


type alias Model =
    { session : Session
    , status : Status
    }


type Status
    = Loading
    | LoadingSlowly
    | Loaded PackageDetails
    | Failed Http.Error


init : Guid -> Session -> ( Model, Cmd Msg )
init packageId session =
    ( { session = session
      , status = Loading
      }
    , Cmd.batch
        [ retrievePackageDetails packageId session.token
            |> Http.send RetrievedDetails
        , Task.perform (\_ -> PassedSlowLoadThreshold) Loading.slowThreshold
        ]
    )



-- VIEW


viewDetails : PackageDetails -> Html Msg
viewDetails details =
    div []
        [ h3 [] [ text details.title ]
        , viewResources details.resources
        ]


viewResources : List Resource -> Html Msg
viewResources resources =
    ul [] (List.map (\p -> li [] [ text p.title ]) resources)


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Package Details"
    , content =
        div [ class "details-page" ]
            [ case model.status of
                Loaded details ->
                    viewDetails details

                Loading ->
                    text ""

                LoadingSlowly ->
                    Loading.icon

                Failed err ->
                    case err of
                        Http.BadStatus response ->
                            text "bad status"

                        Http.BadPayload msg response ->
                            text msg

                        _ ->
                            text "error"
            ]
    }



-- UPDATE


type Msg
    = RetrievedDetails (Result Http.Error PackageDetails)
    | PassedSlowLoadThreshold


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RetrievedDetails (Ok details) ->
            ( { model | status = Loaded details }
            , Cmd.none
            )

        RetrievedDetails (Err err) ->
            ( { model | status = Failed err }
            , Cmd.none
            )

        PassedSlowLoadThreshold ->
            case model.status of
                Loading ->
                    ( { model | status = LoadingSlowly }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- EXPORT


toSession : Model -> Session
toSession model =
    model.session
