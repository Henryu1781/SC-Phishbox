# Troubleshooting

## Erro de autenticação IMAP

- Verifique `IMAP_HOST`, `IMAP_USER` e `IMAP_PASSWORD`.
- Use senha de app se seu provedor exigir.

## Sem e-mails processados

- Confirme se há novas mensagens na INBOX.
- Verifique o arquivo `phishbox-security/data/last_uid.json`.

## ClamAV indisponível

- Confira se o container `clamav` está saudável.
- Veja logs: `./phishbox.sh --logs-worker`.

## API indisponível

- Verifique se o serviço `api` subiu corretamente.
- Veja logs: `docker compose logs -f api` (no diretório `phishbox-security`).
