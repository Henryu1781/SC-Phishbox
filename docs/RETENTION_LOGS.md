# Retenção e logs

## Retenção de UIDs

- Estado persistido em `phishbox-security/data/last_uid.json`.
- Mantém histórico de UIDs processados para evitar duplicidade.

## Logs

- Logs em stdout dos containers.
- Sugestão: usar driver de logs do Docker ou enviar para stack de observabilidade.

## Rotação

- Configure rotação conforme o ambiente (ex.: logrotate ou driver do Docker).
