from __future__ import annotations
from typing import Optional, Any
from pydantic import BaseModel
import psycopg


class AvaliacaoIn(BaseModel):
    user_id: int
    comentario: str
    pontuacao: int

class UserLogginIn(BaseModel):
    email: str
    password: str

class UserRegisterIn(BaseModel):
    email: str
    nome: str
    matricula: str
    curso: str
    password: str

class UserId(BaseModel):
    user_id: int
    is_admin: bool

class UserUpdateIn(BaseModel):
    email: str
    nome: str
    matricula: str
    curso: str

class PasswordUpdateIn(BaseModel):
    current_password: str
    new_password: str

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
    numero: str
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
        numero: str

class ProfessorInfo(BaseModel):
    id: int
    nome: str
    turmas: list[ProfessorInfoTurma]
    qtd_avaliacoes: int
    sum_avaliacoes: int
    img: Optional[str]
    avaliacoes: list[Avaliacao]

class DisciplinasProfessor(BaseModel):
    id: int
    nome: str
    qtd_avaliacoes: int
    sum_avaliacoes: int

class DisciplinaItem(BaseModel):
    id: int
    nome: str


class DisciplinaInfo(BaseModel):
    id: int
    nome: str
    professores: list[DisciplinasProfessor]

class DenunciaIn(BaseModel):
    avaliacao_id: int

class Denuncia(BaseModel):
    id: int
    avaliacao_id: int
    comentario: str

async def get_professor_info(conn: psycopg.AsyncConnection, professor_id: int) -> Optional[ProfessorInfo]:
    async with conn.cursor() as curr:
        await curr.execute("""
                           SELECT nome, qtd_avaliacoes, sum_avaliacoes
                           FROM Professores
                           WHERE id=%s
        """, (professor_id,))
        result = await curr.fetchone()
        if result is None:
            return None
        nome, qtd_avaliacoes, sum_avaliacoes = result

    async with conn.cursor() as curr:
        await curr.execute("""
                           SELECT T.id, T.numero, D.nome
                           FROM Turmas AS T
                           INNER JOIN Disciplinas AS D
                           ON T.disciplina_id=D.id
                           WHERE T.professor_id=%s
        """, (professor_id,))
        turmas = [
            ProfessorInfoTurma(
                id=id,
                nome=nome, numero=numero,
            )
            for id, numero, nome
            in await curr.fetchall()
        ]

    async with conn.cursor() as curr:
        await curr.execute("""
                           SELECT A.id, A.pontuacao, A.comentario, U.id, U.nome
                           FROM AvaliacoesProfessores AS A
                           INNER JOIN Users AS U
                           ON A.user_id=U.id
                           WHERE A.professor_id=%s
        """, (professor_id,))
        avaliacoes = [
            Avaliacao(
                id=id,
                user_id=user_id, user_nome=user_nome,
                comentario=comentario, pontuacao=pontuacao
            )
            for id, pontuacao, comentario, user_id,  user_nome
            in await curr.fetchall()
        ]

    return ProfessorInfo(
        id=professor_id, nome=nome,
        turmas=turmas, avaliacoes=avaliacoes,
        qtd_avaliacoes=qtd_avaliacoes, sum_avaliacoes=sum_avaliacoes,
    )

async def get_disciplina_info(conn: psycopg.AsyncConnection, disciplina_id: int) -> DisciplinaInfo:
    professores: dict[int, DisciplinasProfessor] = {}
    def add_professor(
            professor_id: int, professor_nome: str,
            qtd_avaliacoes: int, sum_avaliacoes: int
    ):
        if professor_id in professores:
            p = professores[professor_id]
            p.sum_avaliacoes += sum_avaliacoes
            p.qtd_avaliacoes += qtd_avaliacoes
            return

        professores[professor_id] = DisciplinasProfessor(
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
                           SELECT turma_numero, professor_id, professor_nome, 
                           disciplina_id, disciplina_nome, 
                           qtd_avaliacoes, sum_avaliacoes
                           FROM Turmas_Avaliacoes_View
                           WHERE turma_id=%s
        """, (turma_id,))
        res = await curr.fetchone()
        if res is None:
            return res

        t_numero, p_id, p_nome, d_id, d_nome, qtd_a, sum_a = res

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
                numero=t_numero,
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

async def add_avaliacao_to_professor(
        conn: psycopg.AsyncConnection, 
        professor_id: int, 
        avaliacao: AvaliacaoIn
) -> Optional[Avaliacao]:
    async with conn.cursor() as curr:
        await curr.execute("""
        INSERT INTO AvaliacoesProfessores(pontuacao, comentario, user_id, professor_id)
        VALUES
            (%s, %s, %s, %s)
        RETURNING id, (SELECT nome FROM Users WHERE id=user_id);
        """, (avaliacao.pontuacao, avaliacao.comentario, avaliacao.user_id, professor_id))
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
        SELECT id, is_admin
        FROM Users
        WHERE email=%s AND senha=%s
        """, (user_info.email, user_info.password))
        res = await curr.fetchone()
        if res is None:
            return None
        return UserId(user_id=res[0], is_admin=res[1])

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

async def update_user(
        conn: psycopg.AsyncConnection,
        user_id: int, user_info: UserUpdateInfo
) -> Optional[UserInfo]:
    async with conn.cursor() as curr:
        await curr.execute("""
                           UPDATE Users SET (email, nome, matricula, curso)
                               = (%s, %s, %s, %s)
                           WHERE id=%s
                           RETURNING email, nome, matricula, curso

        """, (
            user_info.email, user_info.nome,
            user_info.matricula, user_info.curso,
            user_id
        ))
        res = await curr.fetchone()
        if res is None:
            return res

        email, nome, matricula, curso = res
        return UserInfo(email=email, nome=nome, matricula=matricula, curso=curso)

async def update_password(
        conn: psycopg.AsyncConnection,
        user_id: int, password_info: PasswordUpdateIn
) -> bool:
    async with conn.cursor() as curr:
        await curr.execute("""
                           UPDATE Users SET
                             senha = %s
                           WHERE id=%s and senha=%s
                           RETURNING id

        """, (
            password_info.new_password,
            user_id, password_info.current_password,
        ))
        res = await curr.fetchone()
        if res is None:
            return False

        return True

async def register_user(
        conn: psycopg.AsyncConnection,
        user_info: UserRegisterIn
) -> bool:
    async with conn.cursor() as curr:
        await curr.execute("""
             SELECT id, is_admin
             FROM Users
             WHERE matricula=%s OR email=%s
        """, ( user_info.matricula, user_info.email)
        )
        res = await curr.fetchone()
        if res is not None:
            return None

        await curr.execute("""
            INSERT INTO Users(email, nome, matricula, curso, senha, is_admin)
            VALUES
                (%s, %s, %s, %s, %s, false)
            RETURNING id
        """, (
                  user_info.email, user_info.nome,
                  user_info.matricula, user_info.curso,
                  user_info.password,
             )
        )
        res = await curr.fetchone()
        if res is None:
            return None

        return UserId(user_id=res[0], is_admin=res[1])

async def delete_user(
        conn: psycopg.AsyncConnection,
        user_id: int
) -> bool:
    async with conn.cursor() as curr:
        await curr.execute("""
             DELETE
             FROM Users
             WHERE id=%s
             RETURNING id
        """, ( user_id,)
        )
        res = await curr.fetchone()
        if res is None:
            return False
        return True

async def add_denuncia(
        conn: psycopg.AsyncConnection,
        denuncia: DenunciaIn
) -> bool:
    async with conn.cursor() as curr:
        await curr.execute("""
            INSERT INTO Denuncias(avaliacao_id)
            VALUES (%s)
            RETURNING id;
        """, ( denuncia.avaliacao_id,)
        )
        res = await curr.fetchone()
        if res is None:
            return False
        return True

async def get_denuncias(
        conn: psycopg.AsyncConnection,
) -> list[Denuncia]:
    async with conn.cursor() as curr:
        await curr.execute("""
            SELECT D.id, A.id, A.comentario
            FROM DENUNCIAS as D
            INNER JOIN Avaliacoes as A
            ON A.id=D.avaliacao_id
        """ )
        return [
            Denuncia(id=id, avaliacao_id=avalicao_id, comentario=comentario)
            for id, avalicao_id, comentario
            in await curr.fetchall()
        ]

async def delete_denuncia(
        conn: psycopg.AsyncConnection,
        denuncia_id: int
) -> bool:
    async with conn.cursor() as curr:
        await curr.execute("""
             DELETE
             FROM Denuncias
             WHERE id=%s
             RETURNING id
        """, ( denuncia_id,)
        )
        res = await curr.fetchone()
        if res is None:
            return False
        return True

async def delete_avaliacao(
        conn: psycopg.AsyncConnection,
        avaliacao_id: int
) -> bool:
    async with conn.cursor() as curr:
        await curr.execute("""
             DELETE
             FROM Avaliacoes
             WHERE id=%s
             RETURNING id
        """, ( avaliacao_id,)
        )
        res = await curr.fetchone()
        if res is None:
            return False
        return True
