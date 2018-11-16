module Page.Packages exposing (Model, Msg, init, subscriptions, toContext, update, view)

import AppContext exposing (AppContext)
import Browser.Navigation as Nav
import Data.Package as Package exposing (Package, retrievePackages)
import Data.ResourceId exposing (ResourceId)
import Data.Username as Username exposing (Username)
import Html.Styled exposing (Html, a, button, div, span, form, fieldset, h1, input, li, text, b, textarea, toUnstyled, ul)
import Html.Styled.Attributes exposing (attribute, class, placeholder, type_, value, css)
import Css exposing (..)
import Html.Styled.Events exposing (onInput, onSubmit)
import Http
import Json.Decode as Decode exposing (Decoder, decodeString, field, list, string)
import Json.Decode.Pipeline exposing (hardcoded, required)
import Json.Encode as Encode
import Loading
import Log
import Route
import Task
import Theme exposing (globalThemeStyles)



-- MODEL


type alias Model =
    { context : AppContext
    , status : Status
    , filter : String
    }


type Status
    = Loading
    | LoadingSlowly
    | Loaded (List Package)
    | Failed Http.Error


init : AppContext -> ( Model, Cmd Msg )
init context =
    ( { context = context
      , status = Loading
      , filter = ""
      }
    , Cmd.batch
        [ retrievePackages context.session.token context.baseUrl
            |> Http.send RetrievedPackages
        , Task.perform (\_ -> PassedSlowLoadThreshold) Loading.slowThreshold
        ]
    )


ellipsize : String -> Int -> String
ellipsize str maxLength =
    if (String.length str) > maxLength then
        (String.slice 0 (maxLength - 3) str) ++ "..."
    else
        str

filterPackages : List Package -> String -> List Package
filterPackages packages filter =
    let
        normalFilter = String.toLower filter
    in
    List.filter (\p ->
        let
            title = String.toLower p.title
            version = String.toLower p.version
            description = String.toLower p.description
        in
        
        String.contains normalFilter title
        || String.contains normalFilter version
        || String.contains normalFilter description) packages

-- VIEW


viewPackages : Model -> List Package -> Html Msg
viewPackages model packages =
    let
        filteredPackages = if model.filter == "" then packages else filterPackages packages model.filter
        listItems =
            List.map (\p -> li [] [ linkTo p.guid p.title p.version p.id p.description ]) filteredPackages

        linkTo guid title version id description =
            div []
                [ div [ css [ fontWeight bold ] ]
                    [ a [ Route.href (Route.PackageDetails guid) ] [ text title ] ]
                , div [ css [ color ( rgb 99 110 114 ) ] ]
                    [ span [ css [ marginRight (px 20 ) ] ]
                        [ b [] [ text "Version: " ], text version ]
                    , span []
                        [ b [] [ text "Package: " ], text ( Data.ResourceId.toString id) ]
                    ]
                , span [ css [ color ( rgb 99 110 114 ) ] ]
                    [ text (ellipsize description 200) ]
                ]
    in
        div []
        [ div [ css [ marginTop (px 20) ] ]
            [ form [ class "uk-grid-small", attribute "uk-grid" "true" ]
                [ div [ class "uk-width-2-3@s" ] []
                , div [ class "uk-width-1-3@s" ]
                    [ div [ class "uk-margin" ]
                        [ div [ class "uk-inline" ]
                            [ span [ class "uk-form-icon", attribute "uk-icon" "icon: search"] []
                            , input [ class "uk-input", placeholder "Search...", onInput ChangeFilter ] []
                            ]
                        ]
                    ]
                ]
            ]
        , if List.length filteredPackages > 0 then
            ul [ class "uk-list uk-list-divider" ] listItems
            else
                div [ css [ color ( rgb 99 110 114 ), textAlign center, marginTop (px 50) ] ]
                    [ text "No packages match your search criteria" ]
        ]


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "All Course Packages"
    , content =
        div [ class "courses-page" ]
            [ globalThemeStyles model.context.theme
            , case model.status of
                Loaded packages ->
                    viewPackages model packages

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
    | ChangeFilter (String)


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

        ChangeFilter filter ->
            ( { model | filter = filter }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- EXPORT


toContext : Model -> AppContext
toContext model =
    model.context
