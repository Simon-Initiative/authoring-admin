module Page.UserSessions exposing (Model, Msg, init, subscriptions, toSession, update, view)

import Browser.Navigation as Nav
import Data.SessionClient exposing (SessionClient, retrieveSessionClients)
import Data.UserSession exposing (UserSession, retrieveUserSessions)
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
import List.Extra


-- MODEL


type alias Model =
    { session : Session
    , status : Status
    }


type Status
    = Loading
    | LoadingSlowly
    | Loaded (List UserSession)
    | Failed Http.Error


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , status = Loading
      }
    , Cmd.batch
        [ retrieveSessionClients session.token
            |> Http.send RetrievedClientSessions
        , Task.perform (\_ -> PassedSlowLoadThreshold) Loading.slowThreshold
        ]
    )



-- VIEW


viewSessions : List UserSession -> Html Msg
viewSessions userSessions =
    let
        listItems =
            List.map (\s -> li [] [ linkTo s.id s.username ]) userSessions

        linkTo id title =
            a [ ] [ text title ]
    in
    ul [] listItems


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Active User Sessions"
    , content =
        div [ class "user-sessions-page" ]
            [ case model.status of
                Loaded userSessions ->
                    viewSessions userSessions

                Loading ->
                    text "Loading..."

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
    = RetrievedClientSessions (Result Http.Error (List SessionClient))
    | RetrievedUserSessions (Result Http.Error (List UserSession))
    | PassedSlowLoadThreshold


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RetrievedClientSessions (Ok sessionClients) ->
            let
                maybeAccountClient = List.Extra.find (\c -> c.clientId == "account") sessionClients
            in
            ( model
            , case maybeAccountClient of
                Just (accountClient) ->
                    retrieveUserSessions (toSession model).token accountClient.id
                        |> Http.send RetrievedUserSessions
            
                Nothing ->
                    Cmd.none
            )

        RetrievedClientSessions (Err err) ->
            ( { model | status = Failed err }
            , Cmd.none
            )

        RetrievedUserSessions (Ok userSessions) ->
            ( { model | status = Loaded userSessions }
            , Cmd.none
            )

        RetrievedUserSessions (Err err) ->
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
