# Arquitetura

## Fluxo principal

1. **ingest** consulta a inbox via IMAP e limita a 20 mensagens por ciclo.
2. Para cada e-mail novo, envia o conteúdo bruto para a **api**.
3. A **api** enfileira a tarefa no **Redis** (Celery).
4. O **worker** executa a análise com ClamAV.
5. Com base no veredito, move o e-mail para a pasta IMAP adequada.

## Componentes

- **Redis**: broker de mensagens do Celery.
- **ClamAV**: análise de anexos.
- **IMAP**: leitura e movimentação de mensagens.

## Pastas IMAP

- `PhishBox/Clean`
- `PhishBox/Infected`

As pastas são criadas automaticamente quando necessário.
