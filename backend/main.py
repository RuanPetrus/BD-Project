from fastapi import FastAPI, Depends, HTTPException
import models
from contextlib import asynccontextmanager
from connection import config_db, get_db
from typing import Annotated
import psycopg
from fastapi.middleware.cors import CORSMiddleware


Connection = Annotated[psycopg.AsyncConnection, Depends(get_db)]

@asynccontextmanager
async def lifespan(app: FastAPI):
    await config_db()
    yield


app = FastAPI(lifespan=lifespan)

origins = [
    "http://localhost",
    "http://localhost:8080",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/professores")
async def get_professores(
        conn: Connection
    ) -> list[models.ProfessorItem]:
    return await models.get_all_professores(conn)

@app.get("/api/disciplinas")
async def get_disciplinas(
        conn: Connection
    ) -> list[models.DisciplinaItem]:
    return await models.get_all_disciplinas(conn)

@app.get("/api/disciplina/{disciplina_id}")
async def get_disciplina(
        conn: Connection,
        disciplina_id: int
    ) -> models.DisciplinaInfo:
    return await models.get_disciplina_info(conn, disciplina_id)

@app.get("/api/professor/{professor_id}")
async def get_professor(
        conn: Connection,
        professor_id: int
    ) -> models.ProfessorInfo:
    return await models.get_professor_info(conn, professor_id)

@app.get("/api/turma/{turma_id}")
async def get_turma(
        conn: Connection,
        turma_id: int
    ) -> models.TurmaInfo:
    turma = await models.get_turma_info(conn, turma_id)

    if turma is None:
        raise HTTPException(status_code=404, detail="Turma not found")
    return turma

@app.post("/api/turma/{turma_id}/avaliacao")
async def add_avaliacao(
        conn: Connection,
        turma_id: int,
        avaliacao: models.AvaliacaoIn
    ) -> models.Avaliacao:
    new_avaliacao = await models.add_avaliacao_to_turma(conn, turma_id, avaliacao)

    if new_avaliacao is None:
        raise HTTPException(status_code=400, detail="Fail to add avaliação")

    return new_avaliacao

@app.post("/api/user")
async def login_user(
        conn: Connection,
        user_info: models.UserLogginIn,
    ) -> models.UserId:
    user_id = await models.logg_user(conn, user_info)

    if user_id is None:
        raise HTTPException(status_code=400, detail="email or password invalid")

    return user_id

@app.get("/api/user/{user_id}")
async def get_user(
        conn: Connection,
        user_id: int
    ) -> models.UserInfo:
    user = await models.get_user_info(conn, user_id)

    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    return user
