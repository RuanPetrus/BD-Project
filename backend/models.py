from __future__ import annotations
from typing import Optional, Any
from pydantic import BaseModel
import psycopg


class AvaliacaoIn(BaseModel):
    user_id: int
    comentario: str
    pontuacao: int

class UserLogginIn(BaseModel):
    password: str
    email: str

class UserId(BaseModel):
    user_id: int

class UserInfo(BaseModel):
    email: str
    nome: str
    matricula: str
    curso: str

class Avaliacao(BaseModel):
    id: int
    user_id: int
    user_nome: str
    comentario: str
    pontuacao: int


class TurmaInfo(BaseModel):
    id: int
    professor_id: int
    professor_nome: str
    disciplina_id: int
    disciplina_nome: str
    qtd_avaliacoes: int
    sum_avaliacoes: int
    avaliacoes: list[Avaliacao]


class ProfessorItem(BaseModel):
    id: int
    nome: str
    disciplinas: set[str]
    qtd_avaliacoes: int
    sum_avaliacoes: int


class ProfessorInfoTurma(BaseModel):
        id: int
        nome: str

class ProfessorInfo(BaseModel):
    id: int
    nome: str
    turmas: list[ProfessorInfoTurma]
    qtd_avaliacoes: int
    sum_avaliacoes: int


class DisciplinaItem(BaseModel):
    id: int
    nome: str


class DisciplinaInfo(BaseModel):
    id: int
    nome: str
    professores: list[ProfessorInfo]


async def get_professor_info(conn: psycopg.AsyncConnection, professor_id: int) -> ProfessorInfo:
    nome = ""
    qtd_avaliacoes = 0
    sum_avaliacoes = 0
    turmas: set[tuple[int, str]] = set()

    def add_information(row: tuple[Any, ...]) -> None:
        nonlocal nome, qtd_avaliacoes, sum_avaliacoes
        if nome == "":
            nome = row[1]

        qtd_avaliacoes += row[3]
        sum_avaliacoes += row[4]
        turmas.add((row[0], row[2]))

    async with conn.cursor() as curr:
        await curr.execute("""
                           SELECT turma_id,
                           professor_nome, disciplina_nome,  
                           qtd_avaliacoes, sum_avaliacoes
                           FROM Turmas_Avaliacoes_View
                           WHERE professor_id=%s
        """, (professor_id,))
        for row in await curr.fetchall():
                add_information(row)

    professor = ProfessorInfo(
        id=professor_id, nome=nome, 
        qtd_avaliacoes=qtd_avaliacoes, 
        sum_avaliacoes=sum_avaliacoes, 
        turmas = [
            ProfessorInfoTurma(id=id, nome=nome) for id, nome in turmas
        ]
    )
    return professor

async def get_disciplina_info(conn: psycopg.AsyncConnection, disciplina_id: int) -> DisciplinaInfo:
    professores: dict[int, ProfessorInfo] = {}
    def add_professor(
            professor_id: int, professor_nome: str,
            qtd_avaliacoes: int, sum_avaliacoes: int
    ):
        if professor_id in professores:
            p = professores[professor_id]
            p.sum_avaliacoes += sum_avaliacoes
            p.qtd_avaliacoes += qtd_avaliacoes
            return

        professores[professor_id] = ProfessorInfo(
                id=professor_id, nome=professor_nome,
                sum_avaliacoes=sum_avaliacoes, qtd_avaliacoes=qtd_avaliacoes,
                turmas=[]
        )

    async with conn.cursor() as curr:
        await curr.execute(
                """SELECT professor_id, professor_nome, qtd_avaliacoes, sum_avaliacoes, disciplina_nome
                FROM Turmas_Avaliacoes_View
                WHERE disciplina_id=%s""", (disciplina_id,)
        )
        nome_disciplina = ""
        for p_id, p_nome, qtd_a, sum_a, d_nome in await curr.fetchall():
            nome_disciplina = d_nome
            add_professor(p_id, p_nome, qtd_a, sum_a)

        return DisciplinaInfo(id=disciplina_id, nome=nome_disciplina, professores=list(professores.values()))


async def get_all_disciplinas(conn: psycopg.AsyncConnection) -> list[DisciplinaItem]:
    async with conn.cursor() as curr:
        await curr.execute("SELECT id, nome FROM Disciplinas")
        return [DisciplinaItem(id=id, nome=nome) for id, nome in await curr.fetchall()]

async def get_all_professores(conn: psycopg.AsyncConnection) -> list[ProfessorItem]:
    professores: dict[int, ProfessorItem] = {}
    def add_professor(
            professor_id: int, disciplina_id: int, 
            professor_nome: str, disciplina_nome: str, 
            qtd_avaliacoes: int, sum_avaliacoes: int
    ):
        if professor_id in professores:
            p = professores[professor_id]
            p.sum_avaliacoes += sum_avaliacoes
            p.qtd_avaliacoes += qtd_avaliacoes
            p.disciplinas.add(disciplina_nome)
            return

        professores[professor_id] = ProfessorItem(
                id=professor_id, nome=professor_nome,
                sum_avaliacoes=sum_avaliacoes, qtd_avaliacoes=qtd_avaliacoes,
                disciplinas=set([disciplina_nome])
        )

    async with conn.cursor() as curr:
        await curr.execute("""
                           SELECT professor_id, disciplina_id, 
                           professor_nome, disciplina_nome,  
                           qtd_avaliacoes, sum_avaliacoes
                           FROM Turmas_Avaliacoes_View
        """)
        for p_id, d_id, p_nome, d_nome, qtd_a, sum_a in await curr.fetchall():
            add_professor(p_id, d_id, p_nome, d_nome, qtd_a, sum_a)

        return list(professores.values())

async def get_turma_info(conn: psycopg.AsyncConnection, turma_id: int) -> Optional[TurmaInfo]:
    async with conn.cursor() as curr:
        await curr.execute("""
                           SELECT professor_id, professor_nome, 
                           disciplina_id, disciplina_nome, 
                           qtd_avaliacoes, sum_avaliacoes
                           FROM Turmas_Avaliacoes_View
                           WHERE turma_id=%s
        """, (turma_id,))
        res = await curr.fetchone()
        if res is None:
            return res

        p_id, p_nome, d_id, d_nome, qtd_a, sum_a = res

        await curr.execute("""
                           SELECT Avaliacoes.id as avaliacao_id ,
                           Users.nome as user_nome, Avaliacoes.user_id, 
                           Avaliacoes.pontuacao, Avaliacoes.comentario
                           FROM Avaliacoes
                           INNER JOIN Users
                           ON Avaliacoes.user_id=Users.id
                           WHERE Avaliacoes.turma_id=%s
        """, (turma_id,))
        avaliacoes = [
                Avaliacao(id=a_id, user_id=u_id, user_nome=u_nome, pontuacao=pontuacao, comentario=comentario)
                for a_id, u_nome, u_id, pontuacao, comentario in await curr.fetchall()
        ]

        return TurmaInfo(
                id=turma_id,
                professor_id=p_id, professor_nome=p_nome, 
                disciplina_id=d_id, disciplina_nome=d_nome,
                qtd_avaliacoes=qtd_a, sum_avaliacoes=sum_a,
                avaliacoes=avaliacoes
        )

async def add_avaliacao_to_turma(
        conn: psycopg.AsyncConnection, 
        turma_id: int, 
        avaliacao: AvaliacaoIn
) -> Optional[Avaliacao]:
    async with conn.cursor() as curr:
        await curr.execute("""
        INSERT INTO Avaliacoes(pontuacao, comentario, user_id, turma_id)
        VALUES
            (%s, %s, %s, %s)
        RETURNING id, (SELECT nome FROM Users WHERE id=user_id);
        """, (avaliacao.pontuacao, avaliacao.comentario, avaliacao.user_id, turma_id))
        res = await curr.fetchone()
        if res is None:
            return None

        avaliacao_id, user_nome = res
        return Avaliacao(
                id=avaliacao_id, user_id=avaliacao.user_id,
                user_nome=user_nome, comentario=avaliacao.comentario, pontuacao=avaliacao.pontuacao
        )

async def logg_user(
        conn: psycopg.AsyncConnection, 
        user_info: UserLogginIn,
)-> Optional[UserId]:
    async with conn.cursor() as curr:
        await curr.execute("""
        SELECT id
        FROM Users
        WHERE email=%s AND senha=%s
        """, (user_info.email, user_info.password))
        res = await curr.fetchone()
        if res is None:
            return None
        return UserId(user_id=res[0])

async def get_user_info(conn: psycopg.AsyncConnection, user_id: int) -> Optional[UserInfo]:
    async with conn.cursor() as curr:
        await curr.execute("""
                           SELECT email, nome, 
                           matricula, curso
                           FROM Users
                           WHERE id=%s
        """, (user_id,))
        res = await curr.fetchone()
        if res is None:
            return res

        email, nome, matricula, curso = res
        return UserInfo(email=email, nome=nome, matricula=matricula, curso=curso)

