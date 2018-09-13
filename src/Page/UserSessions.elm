module Page.UserSessions exposing (Model, Msg, init, subscriptions, toContext, update, view)

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
import AppContext exposing (AppContext)
import Task
import List.Extra
import Time exposing (..)
import Css exposing (..)
import Html.Styled as Styled
import Html.Styled.Attributes as StyledAttrs
import Html.Styled.Events as StyledEvents
import Theme exposing (globalThemeStyles)

-- MODEL


type alias Model =
    { context : AppContext
    , status : Status
    }


type Status
    = Loading
    | LoadingSlowly
    | Loaded (List UserSession)
    | Failed Http.Error


init : AppContext -> ( Model, Cmd Msg )
init context =
    ( { context = context
      , status = Loading
      }
    , Cmd.batch
        [ retrieveSessionClients context.session.token
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

viewSessions : List UserSession -> Styled.Html Msg
viewSessions userSessions =
    let
        rows =
            List.map (\s -> Styled.tr []
                [ Styled.td [] [ Styled.text s.username ]
                , Styled.td [] [ Styled.text s.ipAddress ]
                , Styled.td [] [ Styled.text (formatTime s.start) ]
                , Styled.td [] [ Styled.text (formatTime s.lastAccess) ]
                , Styled.td []
                    [ Styled.button [ StyledAttrs.class "pure-button", StyledEvents.onClick (LogoutUser s.userId) ]
                        [ Styled.text "Logout" ]
                    ]
                ]) userSessions
    in
    Styled.table [ StyledAttrs.class "pure-table" ]
        [ Styled.thead [] 
            [ Styled.tr []
                [ Styled.th [] [ Styled.text "Username" ]
                , Styled.th [] [ Styled.text "IP Address" ]
                , Styled.th [] [ Styled.text "Start" ]
                , Styled.th [] [ Styled.text "Last Access" ]
                , Styled.th [] [ Styled.text "Actions" ]
                ]
            ]
        , Styled.tbody [] rows
        ]


view : Model -> { title : String, content : Html Msg }
view model =
    let
        toolbarStyle = 
            [ displayFlex
            , flexDirection row
            , margin2 (px 20) (px 0)
            ]
    in
    { title = "Active User Sessions"
    , content =
        Styled.toUnstyled (
            Styled.div [ StyledAttrs.class "user-sessions-page" ]
                [ globalThemeStyles(model.context.theme)
                , Styled.div
                    [ StyledAttrs.css toolbarStyle ]
                    [ Styled.div [ StyledAttrs.css [ flex (int 1) ] ] []
                    , Styled.div []
                        [ Styled.button
                            [ StyledAttrs.class "button-secondary pure-button"
                            , StyledAttrs.css [ marginRight (px 10) ]
                            , StyledEvents.onClick RefreshSessions
                            ]
                            [ Styled.i
                                [ StyledAttrs.class "icon-loop2", StyledAttrs.css [ marginRight (px 8) ] ]
                                []
                            , Styled.text "Refresh"
                            ]
                        , Styled.button
                            [ StyledAttrs.class "button-error pure-button"
                            , StyledEvents.onClick LogoutAllUsers
                            ]
                            [ Styled.text "Logout All" ]
                        ]
                    ]
                , Styled.div []
                    [ case model.status of
                        Loaded userSessions ->
                            viewSessions userSessions

                        Loading ->
                            Styled.text "Loading..."

                        LoadingSlowly ->
                            -- Loading.icon
                            Styled.text "Loading..."

                        Failed err ->
                            case err of
                                Http.BadStatus response ->
                                    Styled.text "bad status"

                                Http.BadPayload msg response ->
                                    Styled.text msg

                                _ ->
                                    Styled.text "error"
                    ]
                ]
        )
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
    | RefreshSessions


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
                    retrieveUserSessions (toContext model).session.token accountClient.id
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
            , logoutAllUsers (toContext model).session.token
                |> Http.send CompletedLogoutAllUsers
            )
        
        CompletedLogoutAllUsers (Ok _) ->
            ( model, Route.replaceUrl (toContext model).session.navKey Route.Home)
        
        CompletedLogoutAllUsers (Err err) ->
            init (toContext model)
        
        LogoutUser userId ->
            ( model
            , logoutUser (toContext model).session.token userId
                |> Http.send CompletedLogoutUser
            )
        
        CompletedLogoutUser (Ok _) ->
            init (toContext model)
        
        CompletedLogoutUser (Err err) ->
            init (toContext model)

        RefreshSessions ->
            init (toContext model)
            



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- EXPORT

toContext : Model -> AppContext
toContext model =
    model.context
