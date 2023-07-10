module Page.Home exposing (Model, Msg, view, init, update)

import Browser
import Html exposing (Html, a, div, text, h3, p)
import Html.Attributes exposing (href)
import Http

type Msg
    = HomeMsg

type alias Model =
    {
       userId: Int
    }


disciplinasPath : String
disciplinasPath
    = "/disciplinas/"

perfilPath : String
perfilPath
    = "/perfil/"

view : Model -> Html Msg
view model =
    div []
        [ h3 [] [text "Página Home"]

        , div []
              [ p [] [ a [ href disciplinasPath ] [ text "Disciplinas" ] ]
              , p [] [ a [ href perfilPath ] [ text "User" ] ]
              ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        HomeMsg ->
            ( model, Cmd.none )
                    

init : ( Model, Cmd Msg )
init =
    ( { userId = 0
      }
    , Cmd.none
    )
