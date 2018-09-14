module Page exposing (Page(..), view)

import Browser exposing (Document)
import Html exposing (Html, a, button, div, footer, h3, i, img, li, nav, p, span, text, ul)
import Html.Styled exposing (Html, toUnstyled, a, button, div, footer, h3, i, img, li, nav, p, span, text, ul)
import Html.Styled.Attributes exposing (class, classList, href, id, style)
import Html.Styled.Events exposing (onClick)
import Route exposing (Route, routeToString)
import Session exposing (Session)
import Theme exposing (getTheme, tcss)
import Css exposing (..)
import AppContext exposing (AppContext)

{-| Determines which navbar link (if any) will be rendered as active.

Note that we don't enumerate every page here, because the navbar doesn't
have links for every page. Anything that's not part of the navbar falls
under Other.

-}
type Page
    = Other
    | Home
    | Packages
    | PackageDetails
    | UserSessions


{-| Take a page's Html and frames it with a header and footer.

The caller provides the current user, so we can display in either
"signed in" (rendering username) or "signed out" mode.

isLoading is for determining whether we should show a loading spinner
in the header. (This comes up during slow page transitions.)

-}
view : Page -> { title : String, content : Html msg } -> AppContext -> Document msg
view page { title, content } context =
    let
        body =
            toUnstyled (
                div [ class "layout" ]
                    [ viewMenuToggle
                    , viewMenu page context
                    , div [ class "main" ]
                        [ div [ class "header" ] [ h3 [] [ text title ] ]
                        , div [ class "content" ] [ content ]
                        ]
                    ]
            )
    in
    { title = title ++ " - Admin"
    , body = [ body ]
    }


viewMenuToggle : Html msg
viewMenuToggle =
    a [ href "#menu", class "menuLink", class "menu-link" ] [ span [] [] ]

menuStyle : Theme.Theme -> Theme.Instance msg -> List Style
menuStyle themeType theme =
    case themeType of
        Theme.Light ->
            [ backgroundColor theme.colors.gray7
            , color theme.colors.gray3
            ]
    
        Theme.Dark ->
            [ backgroundColor theme.colors.gray3 ]

viewMenu : Page -> AppContext -> Html msg
viewMenu page context =
    let
        linkTo =
            navbarLink page
    in
    div [ class "menu ", tcss context.theme menuStyle]
        [ div [ class "pure-menu" ]
            [ a [ class "pure-menu-heading", href "#" ] [ text "Admin " ]
            , ul [ class "pure-menu-list " ]
                [ linkTo Route.Home [ text "Home" ]
                , linkTo Route.Packages [ text "Packages" ]
                , linkTo Route.UserSessions [ text "Sessions" ]
                ]
            ]
        ]


navbarLink : Page -> Route -> List (Html msg) -> Html msg
navbarLink page route linkContent =
    li [ classList [ ( "pure-menu-item", True ), ( "pure-menu-selected", isActive page route ) ] ]
        [ a [ class "pure-menu-link", Route.href route ] linkContent ]


isActive : Page -> Route -> Bool
isActive page route =
    case ( page, route ) of
        ( Home, Route.Home ) ->
            True

        ( Packages, Route.Packages ) ->
            True

        ( PackageDetails, Route.Packages ) ->
            True

        _ ->
            False
