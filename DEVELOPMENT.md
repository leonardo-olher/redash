# Redash — Guia de Desenvolvimento e Deploy

## Visão geral

```
[Mac — dev local]  →  git push  →  [GitHub]  →  sudo redash-deploy  →  [VM GCP]
  porta 5001                                                              porta 80
  postgres local                                                    postgres preservado
```

## Pré-requisitos locais

- Docker Desktop rodando
- Node.js 18+ e Yarn (`npm install -g yarn`)
- Python 3.11+ (opcional, para rodar testes sem Docker)

---

## Desenvolvimento local

### 1. Variáveis de ambiente

Crie o arquivo `.env` na raiz do projeto (já está no `.gitignore`):

```bash
REDASH_SECRET_KEY=dev-secret-key-local-only
REDASH_COOKIE_SECRET=dev-cookie-secret-local-only
```

### 2. Subir o ambiente

```bash
# Sobe backend + postgres + redis (frontend servido em modo estático)
docker compose up server worker scheduler

# Acesse em: http://localhost:5001
```

Para **hot-reload do frontend**, abra um segundo terminal:

```bash
yarn install
yarn start
# Frontend disponível em: http://localhost:8080
```

### 3. Primeira vez — inicializar o banco local

```bash
docker compose run --rm server create_db
```

### 4. Parar o ambiente

```bash
docker compose down
# Para apagar também o banco local:
docker compose down -v
```

---

## Fluxo de trabalho

```bash
# 1. Faça suas alterações no código
# 2. Teste localmente em http://localhost:5001
# 3. Commit e push
git add .
git commit -m "descrição da alteração"
git push origin master
```

---

## Deploy em produção (VM GCP)

### Acesso à VM

```bash
gcloud compute ssh redash --zone=us-central1-a
```

### Fazer deploy

```bash
sudo redash-deploy
```

O script (`/usr/local/bin/redash-deploy`) faz:
1. `git pull origin master` no `/opt/redash-src`
2. `docker compose build` nos containers de app
3. `docker compose up -d --no-deps` — reinicia só os serviços de app

**O PostgreSQL nunca é tocado.** Os dados ficam em `/opt/redash/postgres-data` (bind mount) e persistem independente de qualquer rebuild.

### Primeiro deploy após mudança de imagem

O primeiro build é mais lento (~5–10 min) porque compila o frontend. Os seguintes usam cache do Docker.

---

## Estrutura dos arquivos de infra

| Arquivo | Onde é usado | Para quê |
|---|---|---|
| `compose.yaml` | Local | Dev com hot-reload, postgres local |
| `compose.prod.yaml` | VM (`/opt/redash/compose.yaml`) | Produção, build a partir do fonte |
| `deploy.sh` | VM (`/usr/local/bin/redash-deploy`) | Script de deploy |
| `scripts/vm-setup.sh` | VM (setup inicial) | Configura a VM pela primeira vez |
| `.env` | Local only (gitignore) | Secrets de desenvolvimento |
| `/opt/redash/env` | VM only | Secrets de produção |

---

## Arquitetura na VM

```
/opt/redash/
├── compose.yaml          ← config de produção (build from source)
├── env                   ← variáveis de ambiente de produção (secrets)
└── postgres-data/        ← dados do PostgreSQL (nunca apagar)

/opt/redash-src/          ← código-fonte clonado do GitHub
```

Containers em produção:

| Container | Função |
|---|---|
| `redash-server-1` | API + servidor web (porta 5000) |
| `redash-nginx-1` | Proxy reverso (porta 80 pública) |
| `redash-adhoc_worker-1` | Execução de queries manuais |
| `redash-scheduled_worker-1` | Queries agendadas |
| `redash-scheduler-1` | Agendador de tarefas |
| `redash-worker-1` | Tarefas gerais (email, etc.) |
| `redash-postgres-1` | Banco de dados (dados em `/opt/redash/postgres-data`) |
| `redash-redis-1` | Cache e filas |

---

## Troubleshooting

### Ver logs em produção

```bash
# Todos os serviços
COMPOSE_FILE=/opt/redash/compose.yaml docker compose logs -f

# Só o servidor
COMPOSE_FILE=/opt/redash/compose.yaml docker compose logs -f server
```

### Reiniciar um serviço específico sem rebuild

```bash
COMPOSE_FILE=/opt/redash/compose.yaml docker compose restart server
```

### Build falhou no deploy

```bash
# Ver o erro completo
COMPOSE_FILE=/opt/redash/compose.yaml docker compose build server 2>&1 | tail -30
```

### Voltar para a imagem oficial (rollback)

```bash
# Na VM, restaurar o compose original
sudo cp /opt/redash/compose.yaml.bak /opt/redash/compose.yaml
COMPOSE_FILE=/opt/redash/compose.yaml docker compose up -d
```
