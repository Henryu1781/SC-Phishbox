# Operação

## Subir a stack

```bash
./phishbox.sh --up
```

## Logs

```bash
./phishbox.sh --logs-worker
./phishbox.sh --logs-ingest
```

## Parar e limpar volumes

```bash
./phishbox.sh --purge
```

## Estrutura dos serviços

- `api`: porta 8080 interna (via Docker network).
- `worker`: Celery worker.
- `ingest`: ciclo de 20 e-mails a cada 5 minutos.
