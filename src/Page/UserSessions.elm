module Page.UserSessions exposing (Model, Msg, init, subscriptions, toSession, update, view)

import Browser.Navigation as Nav
import Data.SessionClient exposing (SessionClient, retrieveSessionClients)
import Data.UserSession exposing (UserSession, retrieveUserSessions, logoutAllUsers, logoutUser)
import Html exposing (Html, a, button, div, fieldset, h1, input, li, text, textarea, ul, table, thead, tbody, tr, th, td)
import Html.Attributes exposing (attribute, class, placeholder, type_, value)
import Html.Events exposing (onInput, onSubmit, onClick)
import Css exposing (..)
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
import Theme exposing (..)
import Time exposing (..)

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

toUSMonth : Month -> String
toUSMonth month =
    case month of
        Jan -> "January"
        Feb -> "February"
        Mar -> "March"
        Apr -> "April"
        May -> "May"
        Jun -> "June"
        Jul -> "July"
        Aug -> "August"
        Sep -> "September"
        Oct -> "October"
        Nov -> "November"
        Dec -> "December"

toStandardHours : Int -> String
toStandardHours hours =
    if hours > 0 && hours <= 12 then
        String.fromInt hours
    else if hours > 12 then
        String.fromInt (hours - 12)
    else
        String.fromInt hours

toStandardMinutes : Int -> String
toStandardMinutes minutes =
    if minutes < 10 then
        "0" ++ String.fromInt minutes
    else
        String.fromInt minutes

formatTime time =
    let
        date = Time.millisToPosix time
        hour = toStandardHours (Time.toHour Time.utc date)
        minutes = toStandardMinutes (Time.toMinute Time.utc date)
        ampm = case ((Time.toHour Time.utc date) < 12) of
            True -> "AM"
            False -> "PM"
                
    in
    (toUSMonth(Time.toMonth Time.utc date)) ++ " " ++ String.fromInt (Time.toDay Time.utc date) ++ ", "
        ++ String.fromInt (Time.toYear Time.utc date) ++ " at " ++ hour
        ++ ":" ++ minutes ++ " " ++ ampm

viewSessions : List UserSession -> Html Msg
viewSessions userSessions =
    let
        rows =
            List.map (\s -> tr []
                [ td [] [ text s.username ]
                , td [] [ text s.ipAddress ]
                , td [] [ text (formatTime s.start) ]
                , td [] [ text (formatTime s.lastAccess) ]
                , td []
                    [ button [ class (className "pure-button"), onClick (LogoutUser s.userId) ]
                        [ text "Logout" ]
                    ]
                ]) userSessions
    in
    Html.table [ class "pure-table" ]
        [ thead [] 
            [ tr []
                [ th [] [ text "Username" ]
                , th [] [ text "IP Address" ]
                , th [] [ text "Start" ]
                , th [] [ text "Last Access" ]
                , th [] [ text "Actions" ]
                ]
            ]
        , tbody [] rows
        ]


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Active User Sessions"
    , content =
        div [ class (className "user-sessions-page") ]
            [ div []
                [ div [] []
                , div []
                    [ button [ class (className "pure-button"), onClick LogoutAllUsers]
                        [ text "Logout All" ]
                    ]
                ]
            , div []
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
            ]
    }



-- UPDATE


type Msg
    = RetrievedClientSessions (Result Http.Error (List SessionClient))
    | RetrievedUserSessions (Result Http.Error (List UserSession))
    | PassedSlowLoadThreshold
    | LogoutAllUsers
    | CompletedLogoutAllUsers (Result Http.Error ())
    | LogoutUser (String)
    | CompletedLogoutUser (Result Http.Error ())


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
        
        LogoutAllUsers ->
            ( model
            , logoutAllUsers (toSession model).token
                |> Http.send CompletedLogoutAllUsers
            )
        
        CompletedLogoutAllUsers (Ok _) ->
            ( model, Route.replaceUrl (toSession model).navKey Route.Home)
        
        CompletedLogoutAllUsers (Err err) ->
            init (toSession model)
        
        LogoutUser userId ->
            ( model
            , logoutUser (toSession model).token userId
                |> Http.send CompletedLogoutUser
            )
        
        CompletedLogoutUser (Ok _) ->
            init (toSession model)
        
        CompletedLogoutUser (Err err) ->
            init (toSession model)


            



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- EXPORT


toSession : Model -> Session
toSession model =
    model.session
