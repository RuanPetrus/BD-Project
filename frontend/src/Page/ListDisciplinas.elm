module Page.ListDisciplinas exposing (Model, Msg, view, init, update)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import ErrorMsg exposing ( buildErrorMsg )

import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)

type Msg
    = WebData ( Result Http.Error ( List DisciplinaItem ) )


view : Model -> Html Msg
view model =
    div []
        [  viewDisciplinasOrError model
        ]

viewDisciplinasOrError : Model -> Html Msg
viewDisciplinasOrError model =
    case model.errorMsg of
        Just message ->
            viewError message

        Nothing ->
            viewDisciplinas model.disciplinas


viewDisciplinas : List DisciplinaItem -> Html Msg
viewDisciplinas disciplinas =
    div []
        [ h3 [] [ text "Disciplinas:" ]
        , ul [] (List.map viewDisciplina disciplinas)
        ]


disciplinaUrl : Int -> String
disciplinaUrl id =
    "/disciplina/" ++ ( String.fromInt id ) 

viewDisciplina : DisciplinaItem -> Html Msg
viewDisciplina disciplina =
    li [] [ a [ href ( disciplinaUrl disciplina.id ) ] [ text disciplina.nome ] ]

viewError : String -> Html Msg
viewError errorMessage =
    let
        errorHeading =
            "Couldn't fetch disciplinas at this time."
    in
    div []
        [ h3 [] [ text errorHeading ]
        , text ("Error: " ++ errorMessage)
        ]

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        WebData result ->
            case result of 
                Ok disciplinas ->
                    ( { model | disciplinas = disciplinas }, Cmd.none )
                    
                Err httpError ->
                    ( { model | errorMsg = Just (buildErrorMsg httpError) }, Cmd.none )
                    
type alias Model =
    {
        disciplinas : List DisciplinaItem
    ,   errorMsg : Maybe String
    }

init : ( Model, Cmd Msg )
init =
    ( { disciplinas = []
      , errorMsg = Nothing
      }
    , getDisciplinaList
    )

type alias DisciplinaItem =
    { id : Int
    , nome: String
    }
    
disciplinaListUrl : String
disciplinaListUrl =
    "http://127.0.0.1:5000/api/disciplinas"

getDisciplinaList : Cmd Msg
getDisciplinaList =
    Http.get
        { url = disciplinaListUrl
        , expect = Http.expectJson WebData disciplinaListDecoder
        }

disciplinaListDecoder : Decoder (List DisciplinaItem)
disciplinaListDecoder =
    Decode.list disciplinaItemDecoder

disciplinaItemDecoder : Decoder DisciplinaItem
disciplinaItemDecoder =
    Decode.map2 DisciplinaItem
        (Decode.field "id" Decode.int)
        (Decode.field "nome" Decode.string)
