module Page.Packages exposing (Model, Msg, init, subscriptions, toSession, update, view)

import Browser.Navigation as Nav
import Data.Package as Package exposing (Package, retrievePackages)
import Data.Username as Username exposing (Username)
import Html exposing (Html, a, button, div, fieldset, h1, input, li, text, textarea, ul)
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
    | Loaded (List Package)
    | Failed Http.Error


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , status = Loading
      }
    , Cmd.batch
        [ retrievePackages session.token session.baseUrl
            |> Http.send RetrievedPackages
        , Task.perform (\_ -> PassedSlowLoadThreshold) Loading.slowThreshold
        ]
    )



-- VIEW


viewPackages : List Package -> Html Msg
viewPackages packages =
    let
        listItems =
            List.map (\p -> li [] [ linkTo p.guid p.title ]) packages

        linkTo guid title =
            a [ Route.href (Route.PackageDetails guid) ] [ text title ]
    in
    ul [] listItems


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "All Course Packages"
    , content =
        div [ class "courses-page" ]
            [ case model.status of
                Loaded packages ->
                    viewPackages packages

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
    = RetrievedPackages (Result Http.Error (List Package))
    | PassedSlowLoadThreshold


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RetrievedPackages (Ok packages) ->
            ( { model | status = Loaded packages }
            , Cmd.none
            )

        RetrievedPackages (Err err) ->
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
