# SC-PhishBox

Sistema de triagem automática de e-mails suspeitos com ingestão IMAP, análise de anexos em sandbox e classificação automática em pastas IMAP (Clean/Infected).

## Visão geral

O projeto é composto por três serviços:

- **ingest**: coleta e-mails da caixa IMAP e envia para análise (limite de 20 e-mails a cada 5 minutos).
- **api**: endpoint HTTP para receber e enfileirar análises.
- **worker**: processa e-mails, varre anexos com ClamAV e aplica triagem no IMAP.

## Arquitetura

- **Redis**: fila de tarefas (Celery).
- **ClamAV**: motor de detecção para análise de anexos.
- **IMAP**: leitura e movimentação de e-mails para pastas de triagem.

Mais detalhes:

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- [docs/CONFIGURATION.md](docs/CONFIGURATION.md)
- [docs/OPERATIONS.md](docs/OPERATIONS.md)
- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

## Requisitos

- Docker + Docker Compose
- Conta IMAP com senha de app (recomendado)

## Configuração

1. Configurar credenciais IMAP (gera .env):

   ```bash
   ./phishbox.sh --config
   ```

2. Subir a stack (cria serviços e imagens):

   ```bash
   ./phishbox.sh --up
   ```

## Operação

- Logs do worker:

  ```bash
  ./phishbox.sh --logs-worker
  ```

- Logs do ingest:

  ```bash
  ./phishbox.sh --logs-ingest
  ```

- Encerrar e remover volumes:

  ```bash
  ./phishbox.sh --purge
  ```

## Variáveis de ambiente

Copie o arquivo de exemplo e ajuste:

- [phishbox-security/.env.example](phishbox-security/.env.example)

## Segurança

- Nunca commite credenciais IMAP.
- Use senha de app e conta dedicada.
- O arquivo [docs/SECURITY.md](docs/SECURITY.md) contém boas práticas.

## Licença

Defina uma licença apropriada antes de publicar. Sugestão: MIT.
