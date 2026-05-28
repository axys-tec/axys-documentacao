# .venv

## Ativação/desativação da .venv

***ativar***
.\.venv\Scripts\activate

***desativar***
deactivate

## Criar a .venv

***criar***
python -m venv .venv

***excluir***
Remove-Item -Recurse -Force .venv
ou abreviado >rm -r -fo .venv

***recriar (substituir)***
rm -r -fo .venv
python -m venv .venv
.\.venv\Scripts\activate

## Instalar todas as dependências na .venv
pip install -r requirements.txt


## Rodar FastAPi
> uvicorn backend.app:app --reload --host 0.0.0.0 --port 8000 (O acesso ocorre pelo IP ou `localhost` na porta configurada)

> uvicorn backend.app:app --reload (acesso pelo ip http://127.0.0.1:8000 conforme configuração local)