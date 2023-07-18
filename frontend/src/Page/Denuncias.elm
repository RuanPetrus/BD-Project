module Page.Denuncias exposing (Model, Msg, view, init, update)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import ErrorMsg exposing ( buildErrorMsg )

import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)

type Msg
    = WebData ( Result Http.Error ( List Denuncia ) )
    | WebRemoveAvaliacaoData ( Result Http.Error ( String ) )
    | WebRemoveDenunciaData ( Result Http.Error ( String ) )
    | RemoverAvaliacao Int Int
    | RemoverDenuncia Int
    | BanirUsuario Int

type State
    = Showing
    | Loading
    
                    
type alias Model =
    { denuncias : List Denuncia
    , errorMsg : Maybe String
    , state : State
    }

type alias Denuncia =
    { id : Int
    , comentario : String
    , avaliacaoId : Int
    }

view : Model -> Html Msg
view model =
    div []
        [  viewError model
        ,  viewDenuncias model
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

viewDenuncias : Model -> Html Msg
viewDenuncias model =
    div []
        [ h3 [] [ text "Denuncias" ]
        , ul [] (List.map viewDenuncia model.denuncias)
        ]

viewDenuncia : Denuncia-> Html Msg
viewDenuncia denuncia =
    div []
        [ hr [] []
        , p [] [ text ("Comentario: " ++ denuncia.comentario) ]
        , button [onClick (RemoverAvaliacao denuncia.avaliacaoId denuncia.id) ] [ text ("Remover Comentario") ]
        , button [onClick (BanirUsuario denuncia.avaliacaoId) ] [ text ("Banir Usuario") ]
        , button [onClick (RemoverDenuncia denuncia.id) ] [ text ("Manter comentario") ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        WebData result ->
            case result of 
                Ok denuncias ->
                    ( { model | denuncias = denuncias }, Cmd.none )
                    
                Err httpError ->
                    ( { model | errorMsg = Just (buildErrorMsg httpError) }, Cmd.none )

        WebRemoveDenunciaData result ->
            case result of 
                Ok message ->
                    ( { model | errorMsg = Just (message) }, getDenuncias )
                    
                Err httpError ->
                    ( { model | errorMsg = Just (buildErrorMsg httpError) }, Cmd.none )

        WebRemoveAvaliacaoData result ->
            case result of 
                Ok message ->
                    ( { model | errorMsg = Just (message) }, Cmd.none )
                    
                Err httpError ->
                    ( { model | errorMsg = Just (buildErrorMsg httpError) }, Cmd.none )

        ( RemoverAvaliacao avaliacaoId denunciaId ) ->
           ( model, Cmd.batch [removeAvaliacaoCmd avaliacaoId
                              ,removeDenunciaCmd denunciaId
                              ])

        ( RemoverDenuncia denunciaId ) ->
           ( model, removeDenunciaCmd denunciaId )

        ( BanirUsuario avaliacaoId ) ->
           ( model, banirUsuarioCmd avaliacaoId )



init : ( Model, Cmd Msg )
init =
    ( { denuncias = []
      , errorMsg = Nothing
      , state = Loading
      }
    , getDenuncias
    )

denunciasUrl : String
denunciasUrl =
    "http://127.0.0.1:5000/api/denuncias"

getDenuncias: Cmd Msg
getDenuncias =
    Http.get
        { url = denunciasUrl
        , expect = Http.expectJson WebData (Decode.list denunciaDecoder)
        }

denunciaDecoder: Decoder Denuncia
denunciaDecoder =
    Decode.map3 Denuncia
        (Decode.field "id" Decode.int)
        (Decode.field "comentario" Decode.string)
        (Decode.field "avaliacao_id" Decode.int)

removeAvaliacaoUrl : Int -> String
removeAvaliacaoUrl id =
    "http://127.0.0.1:5000/api/avaliacao/" ++ String.fromInt(id)


removeAvaliacaoCmd : Int -> Cmd Msg
removeAvaliacaoCmd avaliacaoId =
    Http.request
        { method = "DELETE"
        , url = removeAvaliacaoUrl avaliacaoId
        , body = Http.emptyBody
        , expect = Http.expectJson WebRemoveAvaliacaoData removeAvaliacaoDecoder
        , headers = []
        , timeout = Nothing
        , tracker = Nothing
        }

removeAvaliacaoDecoder: Decoder String
removeAvaliacaoDecoder =
    (Decode.field "message" Decode.string)

removeDenunciaUrl : Int -> String
removeDenunciaUrl id =
    "http://127.0.0.1:5000/api/denuncia/" ++ String.fromInt(id)
                     

removeDenunciaCmd : Int -> Cmd Msg
removeDenunciaCmd denunciaId =
    Http.request
        { method = "DELETE"
        , url = removeDenunciaUrl  denunciaId
        , body = Http.emptyBody
        , expect = Http.expectJson WebRemoveDenunciaData removeDenunciaDecoder
        , headers = []
        , timeout = Nothing
        , tracker = Nothing
        }

removeDenunciaDecoder: Decoder String
removeDenunciaDecoder =
    (Decode.field "message" Decode.string)


banirUsuarioUrl : Int -> String
banirUsuarioUrl id =
    "http://127.0.0.1:5000/api/avaliacao/userban/" ++ String.fromInt(id)
                     
banirUsuarioCmd: Int -> Cmd Msg
banirUsuarioCmd avaliacaoId =
    Http.request
        { method = "DELETE"
        , url = banirUsuarioUrl  avaliacaoId
        , body = Http.emptyBody
        , expect = Http.expectJson WebRemoveAvaliacaoData removeAvaliacaoDecoder
        , headers = []
        , timeout = Nothing
        , tracker = Nothing
        }
