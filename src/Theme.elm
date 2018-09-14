module Theme exposing (..)

import Html
import Html.Styled exposing (Html)
import Html.Styled.Attributes
import Css.Global exposing (..)
import Css exposing (Style, Color)
import Dict exposing (Dict)

import Theme.Light
import Theme.Dark

type Theme
    = Light
    | Dark

parseTheme themeName =
    case themeName of
        "light" ->
            Light
        "dark" ->
            Dark
        _ ->
            -- default to light theme
            Light
            

type alias ThemeColors =
    { primary: Color
    , secondary: Color
    , tertiary: Color
    , success: Color
    , info: Color
    , warning: Color
    , danger: Color
    , light: Color
    , dark: Color
    , gray1: Color
    , gray2: Color
    , gray3: Color
    , gray4: Color
    , gray5: Color
    , gray6: Color
    , gray7: Color
    , gray8: Color
    , swatch1: Color
    , swatch2: Color
    , swatch3: Color
    , swatch4: Color
    , swatch5: Color
    }

type alias ThemeBreakpoints =
    { xs : Int
    , sm : Int
    , md : Int
    , lg : Int
    , xl : Int
    , mobileSm : Int
    , mobile : Int
    , tabletSm : Int
    , tablet : Int
    , desktopSm : Int
    , desktop : Int
    }

type alias ThemeFonts =
    { serif: Style
    , sans: Style
    , mono: Style
    }

type alias Instance msg =
    { name: String
    , globalThemeStyles: Html msg
    , colors: ThemeColors
    , breakpoints: ThemeBreakpoints
    , typography: ThemeFonts
    , variables: Dict String String
    }

getTheme : Theme -> Instance msg
getTheme theme =
    case theme of
        Light ->
            Theme.Light.load
        Dark ->
            Theme.Dark.load

globalThemeStyles theme =
    (getTheme theme).globalThemeStyles

tcss : Theme -> (Theme -> Instance msg -> List Style) -> Html.Styled.Attribute msg
tcss currentTheme themeStyles =
    Html.Styled.Attributes.css (themeStyles currentTheme (getTheme currentTheme))

-- lighten
-- darken
-- shade
