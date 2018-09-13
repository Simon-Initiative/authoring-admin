module Theme.Dark exposing (..)

import Css exposing (..)
import Css.Global exposing (..)
import Dict exposing (Dict)


load =
    { name = name
    , globalThemeStyles = globalThemeStyles
    , colors = colors
    , breakpoints = breakpoints
    , typography = typography
    , variables = variables
    }


name =
    "Dark"


colors = 
    { primary = hex "2C3E50"
    , secondary = hex "95a5a6"
    , tertiary = hex "95a5a6"

    , success = hex "18BC9C"
    , info = hex "3498DB"
    , warning = hex "F39C12"
    , danger = hex "E74C3C"

    , light = hex "ecf0f1"
    , dark = hex "7b8a8b"
    , gray1 = hex "222"
    , gray2 = hex "444"
    , gray3 = hex "666"
    , gray4 = hex "888"
    , gray5 = hex "aaa"
    , gray6 = hex "ccc"
    , gray7 = hex "eee"
    , gray8 = hex "fefefe"

    -- swatch colors based on https://color.adobe.com/b703a77bdd81eab476f23b001df9f94d-color-theme-11200366/
    , swatch1 = hex "105187"
    , swatch2 = hex "2C8693"
    , swatch3 = hex "F0F1D5"
    , swatch4 = hex "F19722"
    , swatch5 = hex "C33325"
    }


breakpoints =
    { xs = 480
    , sm = 576
    , md = 768
    , lg = 992
    , xl = 1200
    , mobileSm = 480
    , mobile = 667
    , tabletSm = 736
    , tablet = 1024
    , desktopSm = 1224
    , desktop = 1824
    }


typography =
    { serif = fontFamilies [ "Roboto Slab" ]
    , sans = fontFamilies [ "Helvetica Neue" ]
    , mono = fontFamilies [ "Monaco" ]
    }


variables =
    Dict.fromList
        [ ("copyright", "Copyright (C) 2018 Carnegie Mellon University. All Rights Reserved")
        , ("logoUrl", "assets/images/logo-light.png")
        ]

        
globalThemeStyles =
    Css.Global.global
        [ html
            [ backgroundColor colors.gray1 ]
        , selector "body"
            [ height (vh 100)
            , color colors.gray7
            ]
        , class "layout"
            [ height (pct 100)
            , overflow hidden
            ]
        , class "main"
            [ height (pct 100)
            , overflow auto
            ]
        -- buttons
        , each
            [ class "button-success"
            , class "button-error"
            , class "button-warning"
            , class "button-secondary"
            ]
            [ color (hex "fff")
            , borderRadius (px 4)
            , textShadow4 (px 0) (px 1) (px 1) (rgba 0 0 0 0.2)
            ]
        , class "button-success"
            [
                backgroundColor (rgb 28 184 65)
            ]
        , class "button-error"
            [
                backgroundColor (rgb 202 60 60)
            ]
        , class "button-warning"
            [
                backgroundColor (rgb 223 117 20)
            ]
        , class "button-secondary"
            [
                backgroundColor (rgb 66 184 221)
            ]
        
        -- table
        , class "pure-table"
            [ descendants
                [ selector "tr:nth-child(even)"
                    [ backgroundColor (hex "F5F9FE")
                    ]
                ]
            ]
        ]

