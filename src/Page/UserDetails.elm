module Page.UserDetails exposing (Model, Msg, init, subscriptions, toSession, update, view)

import Browser.Navigation as Nav
import Data.Guid as Guid exposing (Guid)
import Data.Resource as Resource exposing (Resource, ResourceState)
import Data.ResourceId as ResourceId exposing (ResourceId)
import Data.User as User exposing (PackageMembership, User, retrieveUsers)
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
    | Loaded User
    | Failed Http.Error


init : Guid -> Session -> ( Model, Cmd Msg )
init packageId session =
    ( { session = session, status = Loading }, Cmd.none )



-- ( { session = session
--   , status = Loading
--   }
-- , Cmd.batch
--     [ retrieveUsers session.token
--         |> Http.send RetrievedDetails
--     , Task.perform (\_ -> PassedSlowLoadThreshold) Loading.slowThreshold
--     ]
-- )
-- VIEW


viewDetails : User -> Html Msg
viewDetails user =
    div []
        [ h3 [] [ text user.firstName ]
        , viewPackages user.packages
        ]


viewPackages : List PackageMembership -> Html Msg
viewPackages packages =
    ul [] (List.map (\p -> li [] [ text p.title ]) packages)


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "User Details"
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
    = RetrievedDetails (Result Http.Error User)
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
