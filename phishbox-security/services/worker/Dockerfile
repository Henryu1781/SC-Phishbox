FROM python:3.12-slim
WORKDIR /app
RUN pip install celery redis imapclient clamd
COPY tasks.py .
CMD ["celery", "-A", "tasks", "worker", "--loglevel=INFO"]