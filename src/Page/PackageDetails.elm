module Page.PackageDetails exposing (Model, Msg, init, subscriptions, toContext, update, view)

import AppContext exposing (AppContext)
import Browser.Navigation as Nav
import Css exposing (..)
import Data.DeploymentStatus as DeploymentStatus exposing (DeploymentStatus, parseStatus)
import Data.Guid as Guid exposing (Guid)
import Data.Package as Package exposing (Package)
import Data.PackageDetails as PackageDetails exposing (PackageDetails, retrievePackageDetails, setDeploymentStatus, setPackageEditable, setPackageVisible)
import Data.Resource as Resource exposing (Resource, ResourceState)
import Data.ResourceId as ResourceId exposing (ResourceId)
import Data.Username as Username exposing (Username)
import Html.Styled exposing (Html, br, button, div, fieldset, h1, h3, h4, input, label, li, option, select, text, textarea, toUnstyled, ul)
import Html.Styled.Attributes exposing (attribute, checked, class, css, id, placeholder, selected, type_, value)
import Html.Styled.Events exposing (on, onClick, onInput, onSubmit, targetValue)
import Http
import Json.Decode as Decode exposing (Decoder, decodeString, field, list, string)
import Json.Decode.Pipeline exposing (hardcoded, required)
import Json.Encode as Encode
import Loading
import Log
import Page.Home exposing (customDecoder)
import Route
import Task
import Theme exposing (globalThemeStyles)



-- MODEL


type alias Model =
    { context : AppContext
    , status : Status
    }


type Status
    = Loading
    | LoadingSlowly
    | Loaded PackageDetails
    | Failed Http.Error


init : Guid -> AppContext -> ( Model, Cmd Msg )
init packageId context =
    ( { context = context
      , status = Loading
      }
    , Cmd.batch
        [ retrievePackageDetails packageId context.session.token context.baseUrl
            |> Http.send RetrievedDetails
        , Task.perform (\_ -> PassedSlowLoadThreshold) Loading.slowThreshold
        ]
    )


type Msg
    = RetrievedDetails (Result Http.Error PackageDetails)
    | PassedSlowLoadThreshold
    | ToggleVisible PackageDetails
    | ToggleEditable PackageDetails
    | ChangeDeploymentStatus PackageDetails (Maybe DeploymentStatus)
    | PkgEditableDetails (Result Http.Error PackageDetails.PkgEditable)
    | PkgVisibleDetails (Result Http.Error PackageDetails.PkgVisible)
    | PkgDeploymentStatus (Result Http.Error Bool)



-- VIEW


viewDetails : PackageDetails -> Html Msg
viewDetails details =
    let
        isSelected statusString =
            case details.deploymentStatus of
                Nothing ->
                    statusString == "Nothing"

                Just DeploymentStatus.Development ->
                    statusString == "Development"

                Just DeploymentStatus.RequestingQA ->
                    statusString == "Requesting QA"

                Just DeploymentStatus.QA ->
                    statusString == "QA"

                Just DeploymentStatus.RequestingProduction ->
                    statusString == "Requesting Production"

                Just DeploymentStatus.Production ->
                    statusString == "Production"
    in
    div []
        [ h3 [] [ text details.title ]
        , div []
            [ label []
                [ input
                    [ type_ "checkbox"
                    , Html.Styled.Attributes.checked <| details.visible
                    , onClick <| ToggleVisible details
                    ]
                    []
                , text <| " visible "
                ]
            , label []
                [ input
                    [ type_ "checkbox"
                    , Html.Styled.Attributes.checked <| details.editable
                    , onClick <| ToggleEditable details
                    ]
                    []
                , text <| " editable"
                ]
            ]
        , br [] []
        , div [ class "pure-u-1 pure-u-md-1-3" ]
            [ label [ css [ marginRight (px 10) ] ] [ text "Deployment Status" ]
            , select [ id "state", class "pure-input-1-2", on "change" (Decode.map (ChangeDeploymentStatus details) targetValueStatus) ]
                [ option [ value "Nothing", selected (isSelected "Nothing") ] [ text "" ]
                , option [ value "Development", selected (isSelected "Development") ] [ text "Development" ]
                , option [ value "Requesting QA", selected (isSelected "Requesting QA") ] [ text "Requesting QA" ]
                , option [ value "QA", selected (isSelected "QA") ] [ text "QA" ]
                , option [ value "Requesting Production", selected (isSelected "Requesting Production") ] [ text "Requesting Production" ]
                , option [ value "Production", selected (isSelected "Production") ] [ text "Production" ]
                ]
            ]
        , viewResources details.resources
        ]


targetValueStatus : Decode.Decoder (Maybe DeploymentStatus)
targetValueStatus =
    customDecoder targetValue
        (\s ->
            if s == "Nothing" then
                Ok Nothing

            else
                Ok <| Just (parseStatus s)
        )


viewResources : List Resource -> Html Msg
viewResources resources =
    div []
        [ h4 [] [ text "Resources" ]
        , ul [] (List.map (\p -> li [] [ text p.title ]) resources)
        ]


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Package Details"
    , content =
        div [ class "details-page" ]
            [ globalThemeStyles model.context.theme
            , case model.status of
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

        PkgEditableDetails (Ok locked) ->
            ( model
            , Cmd.none
            )

        PkgEditableDetails (Err err) ->
            ( model
            , Cmd.none
            )

        PkgVisibleDetails (Ok hidden) ->
            ( model
            , Cmd.none
            )

        PkgVisibleDetails (Err err) ->
            ( model
            , Cmd.none
            )

        PkgDeploymentStatus (Err err) ->
            ( model
            , Cmd.none
            )

        PkgDeploymentStatus (Ok status) ->
            ( model
            , Cmd.none
            )

        ToggleVisible details ->
            let
                viz =
                    toggle details.visible
            in
            ( { model | status = Loaded { details | visible = viz } }
            , Cmd.batch
                [ setPackageVisible details.guid viz (toContext model).session.token (toContext model).baseUrl
                    |> Http.send PkgVisibleDetails
                ]
            )

        ToggleEditable details ->
            let
                loc =
                    toggle details.editable
            in
            ( { model | status = Loaded { details | editable = loc } }
            , Cmd.batch
                [ setPackageEditable details.guid loc (toContext model).session.token (toContext model).baseUrl
                    |> Http.send PkgEditableDetails
                ]
            )

        ChangeDeploymentStatus details newStatus ->
            ( { model | status = Loaded { details | deploymentStatus = newStatus } }
            , Cmd.batch
                [ case newStatus of
                    Nothing ->
                        Cmd.none

                    Just status ->
                        setDeploymentStatus details.guid status (toContext model).session.token (toContext model).baseUrl
                            |> Http.send PkgDeploymentStatus
                ]
            )

        PassedSlowLoadThreshold ->
            case model.status of
                Loading ->
                    ( { model | status = LoadingSlowly }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )


toggle : Bool -> Bool
toggle bool =
    not bool



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- EXPORT


toContext : Model -> AppContext
toContext model =
    model.context
