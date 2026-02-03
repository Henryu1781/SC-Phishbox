# Configuração

## Variáveis obrigatórias

Copie o arquivo de exemplo e ajuste conforme seu ambiente:

- [phishbox-security/.env.example](../phishbox-security/.env.example)

### Descrição

- `IMAP_HOST`: host do servidor IMAP.
- `IMAP_USER`: usuário/conta de e-mail.
- `IMAP_PASSWORD`: senha de app (recomendado).
- `IMAP_POLL_SECONDS`: intervalo de varredura (segundos).
- `REDIS_URL`: broker do Celery.
- `CLAMAV_HOST`: host do ClamAV.

## Pastas IMAP

O sistema cria automaticamente:

- `PhishBox/Clean`
- `PhishBox/Infected`

## Persistência

- Estado de UIDs processados: `phishbox-security/data/last_uid.json`
