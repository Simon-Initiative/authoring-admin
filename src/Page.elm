module Page exposing (Page(..), view)

import AppContext exposing (AppContext)
import Browser exposing (Document)
import Css exposing (..)
import Html exposing (Html, a, button, div, footer, h3, i, img, li, nav, p, span, text, ul)
import Html.Attributes
import Html.Styled exposing (Html, a, button, div, footer, h3, i, img, li, nav, p, span, text, toUnstyled, ul)
import Html.Styled.Attributes exposing (class, classList, href, id, style)
import Html.Styled.Events exposing (onClick)
import Route exposing (Route, routeToString)
import Session exposing (Session)
import Theme exposing (getTheme, tcss)


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
    | Users
    | UserDetails


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
            toUnstyled
                (div [ class "layout" ]
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


menuStyle themeType theme =
    [ displayFlex
    , flexDirection column
    , case themeType of
        Theme.Light ->
            Css.batch
                [ backgroundColor theme.colors.gray7
                , displayFlex
                , flexDirection column
                ]

        Theme.Dark ->
            Css.batch
                [ backgroundColor theme.colors.gray2
                , displayFlex
                , flexDirection column
                ]
    ]


pureMenuStyle themeType theme =
    [ flex (int 1) ]


logoutButtonStyle themeType theme =
    [ height (px 30)
    , margin (px 10)
    ]


viewMenu : Page -> AppContext -> Html msg
viewMenu page context =
    let
        linkTo =
            navbarLink page context.theme
    in
    div [ class "menu ", tcss context.theme menuStyle ]
        [ div [ class "pure-menu", tcss context.theme pureMenuStyle ]
            [ a [ class "pure-menu-heading", href "#" ] [ text "Admin " ]
            , ul [ class "pure-menu-list " ]
                [ linkTo Route.Home [ text "Home" ]
                , linkTo Route.Packages [ text "Packages" ]
                , linkTo Route.UserSessions [ text "Sessions" ]
                , linkTo Route.Users [ text "Users " ]
                ]
            ]

        -- , button [ class "button-secondary", tcss context.theme logoutButtonStyle, redirectTo context.logoutUrl ]
        --     [ text "Logout" ]
        ]


navbarLink : Page -> Theme.Theme -> Route -> List (Html msg) -> Html msg
navbarLink page theme route linkContent =
    li [ classList [ ( "pure-menu-item", True ), ( "pure-menu-selected", isActive page route ) ] ]
        [ a [ class "pure-menu-link", Route.href route ] linkContent ]



-- redirectTo : String -> Html.Styled.Attribute msg
-- redirectTo destinationUrl =
--   Html.Styled.Attributes.attribute
--     "onclick"
--     ("window.location.href = '" ++ destinationUrl ++ "'")


isActive : Page -> Route -> Bool
isActive page route =
    case ( page, route ) of
        ( Home, Route.Home ) ->
            True

        ( Packages, Route.Packages ) ->
            True

        ( PackageDetails, Route.Packages ) ->
            True

        ( UserSessions, Route.UserSessions ) ->
            True

        ( Users, Route.Users ) ->
            True

        ( UserDetails, Route.Users ) ->
            True

        _ ->
            False
