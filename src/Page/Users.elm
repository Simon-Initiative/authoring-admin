module Page.Users exposing (Model, Msg, init, subscriptions, toSession, update, view)

import Browser.Navigation as Nav
import Data.User as User exposing (User, retrieveUsers)
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
    | Loaded (List User)
    | Failed Http.Error


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , status = Loading
      }
    , Cmd.batch
        [ retrieveUsers session.token
            |> Http.send RetrievedUsers
        , Task.perform (\_ -> PassedSlowLoadThreshold) Loading.slowThreshold
        ]
    )



-- VIEW


viewUsers : List User -> Html Msg
viewUsers users =
    let
        listItems =
            List.map (\p -> li [] [ linkTo p.id p.email ]) users

        linkTo guid title =
            a [ Route.href (Route.UserDetails guid) ] [ text title ]
    in
    ul [] listItems


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "All Course Users"
    , content =
        div [ class "courses-page" ]
            [ case model.status of
                Loaded users ->
                    viewUsers users

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
    = RetrievedUsers (Result Http.Error (List User))
    | PassedSlowLoadThreshold


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RetrievedUsers (Ok users) ->
            ( { model | status = Loaded users }
            , Cmd.none
            )

        RetrievedUsers (Err err) ->
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
