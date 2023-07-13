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
    professor =  await models.get_professor_info(conn, professor_id)
    if professor is None:
        raise HTTPException(status_code=404, detail="Professor not found")
    return professor
        

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
async def add_avaliacao_turma(
        conn: Connection,
        turma_id: int,
        avaliacao: models.AvaliacaoIn
    ) -> models.Avaliacao:
    new_avaliacao = await models.add_avaliacao_to_turma(conn, turma_id, avaliacao)

    if new_avaliacao is None:
        raise HTTPException(status_code=400, detail="Fail to add avaliação")

    return new_avaliacao

@app.post("/api/professor/{professor_id}/avaliacao")
async def add_avaliacao_professor(
        conn: Connection,
        professor_id: int,
        avaliacao: models.AvaliacaoIn
    ) -> models.Avaliacao:
    new_avaliacao = await models.add_avaliacao_to_professor(conn, professor_id, avaliacao)

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

@app.post("/api/user/register")
async def register_user(
        conn: Connection,
        user_info: models.UserRegisterIn,
    ) -> models.UserId:
    user_id = await models.register_user(conn, user_info)

    if user_id is None:
        raise HTTPException(status_code=400, detail="fail to register user")

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

@app.delete("/api/user/{user_id}")
async def delete_user(
        conn: Connection,
        user_id: int
    ) -> dict[str, str]:
    ok = await models.delete_user(conn, user_id)

    if not ok:
        raise HTTPException(status_code=400, detail="Fail to delete user")

    return {"message": "User deleted sucessfully"}

@app.put("/api/user/{user_id}")
async def update_user(
        conn: Connection,
        user_id: int,
        user_info: models.UserUpdateIn,
    ) -> models.UserInfo:
    user = await models.update_user(conn, user_id, user_info)

    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    return user

@app.put("/api/user/{user_id}/password")
async def update_password(
        conn: Connection,
        user_id: int,
        password_info: models.PasswordUpdateIn,
    ) -> dict[str, str]:
    ok = await models.update_password(conn, user_id, password_info)

    if not ok:
        raise HTTPException(status_code=404, detail="Password fail to update")

    return {"message" : "password update sucessful"}

@app.post("/api/denuncias")
async def add_denuncia(
        conn: Connection,
        denuncia: models.DenunciaIn,
    ) -> dict[str, str]:
    ok = await models.add_denuncia(conn, denuncia)

    if not ok:
        raise HTTPException(status_code=404, detail="Fail to add denucia")

    return {"message" : "Denucia add sucessfully"}

@app.get("/api/denuncias")
async def get_denuncias(
        conn: Connection,
    ) -> list[models.Denuncia]:
    return await models.get_denuncias(conn)

@app.delete("/api/denuncia/{denuncia_id}")
async def delete_denuncia(
        conn: Connection,
        denuncia_id: int
    ) -> dict[str, str]:
    ok = await models.delete_denuncia(conn, denuncia_id)

    if not ok:
        raise HTTPException(status_code=400, detail="Fail to delete denuncia")

    return {"message": "Denuncia deleted sucessfully"}

@app.delete("/api/avaliacao/{avaliacao_id}")
async def delete_avaliacao(
        conn: Connection,
        avaliacao_id: int
    ) -> dict[str, str]:
    ok = await models.delete_avaliacao(conn, avaliacao_id)

    if not ok:
        raise HTTPException(status_code=400, detail="Fail to delete avaliacao")

    return {"message": "Avaliacao deleted sucessfully"}
