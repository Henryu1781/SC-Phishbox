# Monitoramento

## Healthchecks

- Verifique containers: `docker compose ps`.
- Logs: `docker compose logs -f <serviço>`.

## Alertas recomendados

- Falhas de login IMAP.
- Celery sem tarefas consumidas.
- ClamAV indisponível.

## Métricas sugeridas

- Número de e-mails processados por ciclo.
- Tempo médio de análise.
- Taxa de detecção.
