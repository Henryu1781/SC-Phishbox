# API

## POST /analyze

Recebe um arquivo de e-mail (RFC822) e enfileira análise.

### Campos

- `file`: arquivo `.eml`
- `imap_uid`: UID do IMAP (opcional)

### Resposta

- `status`: queued
- `uid`: UID recebido
