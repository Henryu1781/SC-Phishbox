# Instalação

## Passo a passo

1. Configure as credenciais IMAP:

   `./phishbox.sh --config`

2. Suba a stack:

   `./phishbox.sh --up`

3. Acompanhe logs:

   `./phishbox.sh --logs-ingest`
   `./phishbox.sh --logs-worker`

## Estrutura gerada

- `phishbox-security/.env`
- `phishbox-security/data/last_uid.json`
