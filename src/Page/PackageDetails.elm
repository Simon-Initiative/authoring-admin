module Page.PackageDetails exposing (Model, Msg, init, subscriptions, toContext, update, view)

import AppContext exposing (AppContext)
import Browser.Navigation as Nav
import Css exposing (..)
import Data.DeploymentStatus as DeploymentStatus exposing (DeploymentStatus, parseStatus)
import Data.Guid as Guid exposing (Guid)
import Data.Package as Package exposing (Package)
import Data.PackageDetails as PackageDetails exposing (PackageDetails, clonePackage, retrievePackageDetails, setDeploymentStatus, setPackageEditable, setPackageVisible)
import Data.Resource as Resource exposing (Resource, ResourceState)
import Data.ResourceId as ResourceId exposing (ResourceId)
import Data.Username as Username exposing (Username)
import Html.Styled exposing (Html, br, button, div, span, fieldset, form, h1, h3, h4, i, input, label, legend, li, option, select, text, textarea, toUnstyled, ul)
import Html.Styled.Attributes exposing (attribute, checked, class, css, disabled, id, placeholder, selected, type_, value)
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
    , clonePackageId : String
    , cloneStatus : CloneStatus
    }


type Status
    = Loading
    | LoadingSlowly
    | Loaded PackageDetails
    | Failed Http.Error


type CloneStatus
    = CloneInactive
    | ClonePending
    | CloneSuccessful String
    | CloneFailed Http.Error


init : Guid -> AppContext -> ( Model, Cmd Msg )
init packageId context =
    ( { context = context
      , status = Loading
      , clonePackageId = ""
      , cloneStatus = CloneInactive
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
    | ChangeClonePackageId String
    | ClonePackage PackageDetails String
    | ClonePackageStatus (Result Http.Error PackageDetails.PkgClone)



-- VIEW


viewDetails : PackageDetails -> Model -> Html Msg
viewDetails details model =
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
        , div [ css [ marginBottom (px 20) ] ]
            [ div []
                [ span [ css [ fontWeight bold ] ] [ text "Version: " ]
                , span [] [ text details.version ]
                ]
            , div []
                [ span [ css [ fontWeight bold ] ] [ text "Package ID: " ]
                , span [] [ text (ResourceId.toString details.id) ]
                ]
            , div []
                [ span [ css [ fontWeight bold ] ] [ text "Package Family: " ]
                , span [] [ text details.packageFamily ]
                ]
            , div []
                [ span [ css [ fontWeight bold ] ] [ text "Date Created: " ]
                , span [] [ text details.dateCreated ]
                ]
            , div []
                [ span [ css [ fontWeight bold ] ] [ text "Build Status: " ]
                , span [] [ text details.buildStatus ]
                ]
            , div []
                [ span [ css [ fontWeight bold ] ] [ text "SVN Location: " ]
                , span [] [ text details.svnLocation ]
                ]
            ]
        , div []
            [ span [ css [ fontWeight bold, marginRight (px 10) ] ] [ text "Visibility" ]
            , label []
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
            [ label [ css [ fontWeight bold, marginRight (px 10) ] ] [ text "Deployment Status" ]
            , select [ id "state", class "pure-input-1-2", on "change" (Decode.map (ChangeDeploymentStatus details) targetValueStatus) ]
                [ option [ value "Nothing", selected (isSelected "Nothing") ] [ text "" ]
                , option [ value "Development", selected (isSelected "Development") ] [ text "Development" ]
                , option [ value "Requesting QA", selected (isSelected "Requesting QA") ] [ text "Requesting QA" ]
                , option [ value "QA", selected (isSelected "QA") ] [ text "QA" ]
                , option [ value "Requesting Production", selected (isSelected "Requesting Production") ] [ text "Requesting Production" ]
                , option [ value "Production", selected (isSelected "Production") ] [ text "Production" ]
                ]
            ]
        , br [] []
        , div [ class "pure-u-1 pure-u-md-1-3", css [ marginTop (px 10) ] ]
            [ form [ class "pure-form", onSubmit (ClonePackage details model.clonePackageId) ]
                [ fieldset []
                    [ legend [ css [ fontWeight bold ] ] [ text "Clone Package" ]
                    , input
                        [ css [ marginRight (px 10), width (px 300) ], placeholder "Enter new package id for clone", onInput ChangeClonePackageId ]
                        [ text model.clonePackageId ]
                    , button
                        [ class "pure-button pure-button-primary"
                        , css [ marginRight (px 10) ]
                        , disabled (model.clonePackageId == "" && model.cloneStatus /= ClonePending)
                        ]
                        [ text "Clone" ]
                    ]
                ]
            , case model.cloneStatus of
                CloneInactive ->
                    div [] [ text "" ]

                ClonePending ->
                    div [ css [ color (rgb 41 128 185) ] ]
                        [ i
                            [ class "spinner spinner-steps2 icon-spinner3", css [ marginRight (px 8) ] ]
                            []
                        , text "Cloning package. Please wait..."
                        ]

                CloneSuccessful message ->
                    div [ css [ color (rgb 39 174 96) ] ] [ text ("Clone successful: " ++ message) ]

                CloneFailed err ->
                    div [ css [ color (rgb 192 57 43) ] ] [ text ("Clone failed: " ++ httpErrorMessage err) ]
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


httpErrorMessage : Http.Error -> String
httpErrorMessage err =
    case err of
        Http.BadStatus response ->
            case response.status.code of
                404 ->
                    "Package Not Found"
                _ ->
                    response.status.message

        Http.BadPayload msg response ->
            msg

        _ ->
            "Unknown Error"


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Package Details"
    , content =
        div [ class "details-page" ]
            [ globalThemeStyles model.context.theme
            , case model.status of
                Loaded details ->
                    viewDetails details model

                Loading ->
                    text ""

                LoadingSlowly ->
                    Loading.icon

                Failed err ->
                    case err of
                        Http.BadStatus response ->
                            text (httpErrorMessage err)

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

        ClonePackageStatus (Err err) ->
            ( { model | cloneStatus = CloneFailed err }
            , Cmd.none
            )

        ClonePackageStatus (Ok res) ->
            ( { model | cloneStatus = CloneSuccessful res.message }
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

        ChangeClonePackageId clonePackageId ->
            ( { model | clonePackageId = clonePackageId }
            , Cmd.none
            )

        ClonePackage details clonePackageId ->
            ( { model | cloneStatus = ClonePending }
            , Cmd.batch
                [ clonePackage details.guid clonePackageId (toContext model).session.token (toContext model).baseUrl
                    |> Http.send ClonePackageStatus
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
