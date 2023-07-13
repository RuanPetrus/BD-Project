module Page.Home exposing (Model,  Msg, view, init, update)

import Browser
import Html exposing (Html, a, div, text, h3, p, button)
import Html.Attributes exposing (href)
import Html.Events exposing (onClick)
import Http

type Msg
    = HomeMsg

type alias Model =
    { isAdmin: Bool
    }


disciplinasPath : String
disciplinasPath
    = "/disciplinas/"

professoresPath : String
professoresPath
    = "/professores/"

perfilPath : String
perfilPath
    = "/perfil/"

denunciasPath : String
denunciasPath
    = "/denuncias/"

view : Model -> Html Msg
view model =
    div []
        [ h3 [] [text "Página Home"]

        , div []
              [ p [] [ a [ href disciplinasPath ] [ text "Disciplinas" ] ]
              , p [] [ a [ href professoresPath ] [ text "Professores" ] ]
              , p [] [ a [ href perfilPath ] [ text "User" ] ]
              , viewDenuncias model
              ]
                
        ]

viewDenuncias : Model -> Html Msg
viewDenuncias model =
    if model.isAdmin then
            p [] [ a [ href denunciasPath ] [ text "Denuncias" ] ]
    else
        div [] []
    


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        HomeMsg ->
            ( model, Cmd.none )
                    

init : Bool -> ( Model, Cmd Msg )
init isAdmin =
    ( { isAdmin = isAdmin
      }
    , Cmd.none
    )
