module Page.Turma exposing (Model, Msg, view, init, update)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import ErrorMsg exposing ( buildErrorMsg )

import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)

type Msg
    = WebTurmaData ( Result Http.Error ( Turma ) )
    | WebNewAvaliacaoData ( Result Http.Error ( Avaliacao ) )
    | WebDenunciaData ( Result Http.Error ( String ) )
    | Denuncia Int
    | SetComentario String
    | SetPontuacao String
    | ClickNewComentario

type State
    = Showing
    | Loading
    
type alias Model =
    { turma : Turma
    , turmaId : Int
    , errorMsg : Maybe String
    , state : State
    , newAvaliacao : NewAvaliacao
    }

type alias Turma =
    { numero : String
    , professorId : Int
    , professorNome : String
    , disciplinaId : Int
    , disciplinaNome : String
    , qtdAvaliacoes : Int
    , sumAvaliacoes : Int
    , avaliacoes : List Avaliacao
    }

type alias Avaliacao =
    { id : Int
    , userId : Int
    , userNome: String
    , comentario: String
    , pontuacao: Int
    }

type alias NewAvaliacao =
    { userId : Int
    , comentario: String
    , pontuacao: Int
    }

emptyTurma : Turma
emptyTurma =
    { numero = ""
    , professorId = 0
    , professorNome = ""
    , disciplinaId = 0
    , disciplinaNome = ""
    , qtdAvaliacoes = 0
    , sumAvaliacoes = 0
    , avaliacoes =  []
    }

view : Model -> Html Msg
view model =
    div []
        [  viewError model
        ,  viewTurma model
        ]

professorUrl : Int -> String
professorUrl id =
    "/professor/" ++ (String.fromInt  id)

viewTurma : Model -> Html Msg
viewTurma model =
    div []
        [ h3 [] [ text ("Disciplina: " ++ model.turma.disciplinaNome) ]
        , h3 [] [ text ("Professor: " ++ model.turma.professorNome) ]
        , h3 [] [ text ("Turma: " ++ model.turma.numero) ]
        , h3 [] [ text ("Nota: " ++ String.fromInt(model.turma.sumAvaliacoes // model.turma.qtdAvaliacoes)) ]
        , p [] [ text "Comentarios:" ]
        , ul [] (List.map viewAvaliacao model.turma.avaliacoes)
        , viewAddAvaliacao model.newAvaliacao
        ]

viewAddAvaliacao : NewAvaliacao -> Html Msg
viewAddAvaliacao avaliacao =
    div []
        [ h3 [] [ text "Adicione uma nova avaliação" ]
        , p [] [ text "Sua pontuacao será computada modulo 6" ]
        , div []
            [ label [ for  "comentario" ] [text "Comentario:" ]
            , input [ id "comentario"
                    , type_ "text"
                    , size 100
                    , Html.Attributes.value avaliacao.comentario, onInput SetComentario ]
                    []
            ]
        , div []
            [ label [ for  "pontuacao" ] [text "Pontuacao:" ]
            , input [ id "pontuacao"
                    , type_ "number"
                    , Html.Attributes.value (String.fromInt(avaliacao.pontuacao))
                    , onInput SetPontuacao ]
                    []
            ]
        , div []
            [ button [ onClick ClickNewComentario ] [ text "Comentar" ]
            ]
        ]

viewAvaliacao : Avaliacao -> Html Msg
viewAvaliacao avaliacao =
    div []
        [ hr [] []
        , p [] [ text ("Username: " ++ avaliacao.userNome) ]
        , p [] [ text ("Comentario: " ++ avaliacao.comentario) ]
        , p [] [ text ("Pontuacao: " ++ String.fromInt(avaliacao.pontuacao)) ]
        , button [ onClick (Denuncia avaliacao.id) ] [ text "Denuncia" ]
        ]

viewError : Model -> Html Msg
viewError model =
    case model.errorMsg of
        (Just message) ->
            div []
                [ p [] [ text message ]
                ]

        Nothing ->
            div [] []

updateComentario : NewAvaliacao -> String -> NewAvaliacao
updateComentario avaliacao value =
    { avaliacao | comentario = value }

updatePontuacao : NewAvaliacao -> String -> NewAvaliacao
updatePontuacao avaliacao value =
    { avaliacao | pontuacao = ( String.toInt value
                                              |> Maybe.withDefault 0
                                              |> modBy 6)  }


addAvalicao : Turma -> Avaliacao -> Turma
addAvalicao turma avaliacao =
    { turma | avaliacoes = turma.avaliacoes ++ [avaliacao]
    , qtdAvaliacoes = turma.qtdAvaliacoes + 1
    , sumAvaliacoes = turma.sumAvaliacoes + avaliacao.pontuacao
    }
        
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        WebTurmaData result ->
            case result of 
                Ok turma ->
                    ( { model | turma = turma }, Cmd.none )
                    
                Err httpError ->
                    ( { model | errorMsg = Just (buildErrorMsg httpError) }, Cmd.none )

        WebNewAvaliacaoData result ->
            case result of 
                Ok avaliacao ->
                    ( { model | turma = addAvalicao model.turma avaliacao }, Cmd.none )
                    
                Err httpError ->
                    ( { model | errorMsg = Just (buildErrorMsg httpError) }, Cmd.none )

        WebDenunciaData result ->
            case result of 
                Ok message ->
                    ( { model | errorMsg = Just (message) }, Cmd.none )
                    
                Err httpError ->
                    ( { model | errorMsg = Just (buildErrorMsg httpError) }, Cmd.none )

        ( SetComentario comentario ) ->
            ( { model | newAvaliacao = updateComentario model.newAvaliacao comentario }, Cmd.none )
        ( SetPontuacao pontuacao ) ->
            ( { model | newAvaliacao = updatePontuacao model.newAvaliacao pontuacao }, Cmd.none )


        ( ClickNewComentario) ->
            (model, newAvaliacaoCmd model)

        ( Denuncia avaliacaoId) ->
            (model, denunciaCmd avaliacaoId)


init : (Int, Int) -> ( Model, Cmd Msg )
init (userId, turmaId) =
    ( { turma = emptyTurma
      , turmaId = turmaId
      , errorMsg = Nothing
      , state = Loading
      , newAvaliacao = { userId = userId, comentario = "", pontuacao = 0 }
      }
    , getTurma turmaId
    )

turmaUrl : Int -> String
turmaUrl id =
    "http://127.0.0.1:5000/api/turma/" ++ (String.fromInt id)

getTurma: Int -> Cmd Msg
getTurma turmaId =
    Http.get
        { url = turmaUrl turmaId
        , expect = Http.expectJson WebTurmaData turmaDecoder
        }

turmaDecoder: Decoder Turma
turmaDecoder =
    Decode.map8 Turma
        (Decode.field "numero" Decode.string)
        (Decode.field "professor_id" Decode.int)
        (Decode.field "professor_nome" Decode.string)
        (Decode.field "disciplina_id" Decode.int)
        (Decode.field "disciplina_nome" Decode.string)
        (Decode.field "qtd_avaliacoes" Decode.int)
        (Decode.field "sum_avaliacoes" Decode.int)
        (Decode.field "avaliacoes" (Decode.list avaliacaoDecoder))

avaliacaoDecoder : Decoder Avaliacao
avaliacaoDecoder =
    Decode.map5 Avaliacao
        (Decode.field "id" Decode.int)
        (Decode.field "user_id" Decode.int)
        (Decode.field "user_nome" Decode.string)
        (Decode.field "comentario" Decode.string)
        (Decode.field "pontuacao" Decode.int)

newAvaliacaoUrl : Int -> String
newAvaliacaoUrl id =
    "http://127.0.0.1:5000/api/turma/" ++ (String.fromInt id) ++ "/avaliacao"

newAvaliacaoEncoder : NewAvaliacao -> Encode.Value
newAvaliacaoEncoder avaliacao =
    Encode.object
        [ ("user_id",  Encode.int avaliacao.userId)
        , ("comentario", Encode.string avaliacao.comentario)
        , ("pontuacao", Encode.int avaliacao.pontuacao)
        ]

newAvaliacaoCmd : Model -> Cmd Msg
newAvaliacaoCmd model =
    Http.request
        { method = "POST"
        , url = newAvaliacaoUrl model.turmaId
        , body = Http.jsonBody (newAvaliacaoEncoder model.newAvaliacao)
        , expect = Http.expectJson WebNewAvaliacaoData avaliacaoDecoder
        , headers = []
        , timeout = Nothing
        , tracker = Nothing
        }

addDenuncia : String
addDenuncia =
    "http://127.0.0.1:5000/api/denuncias"
        
denunciaCmd : Int -> Cmd Msg
denunciaCmd avaliacaoId =
    Http.request
        { method = "POST"
        , url = addDenuncia
        , body = Http.jsonBody (denunciaEncoder avaliacaoId)
        , expect = Http.expectJson WebDenunciaData denunciaDecoder
        , headers = []
        , timeout = Nothing
        , tracker = Nothing
        }

denunciaDecoder : Decoder String
denunciaDecoder =
    Decode.field "message" Decode.string

denunciaEncoder : Int -> Encode.Value
denunciaEncoder avaliacaoId =
    Encode.object
        [ ("avaliacao_id",  Encode.int avaliacaoId)
        ]
