FROM python:3.12-slim
WORKDIR /app
RUN pip install imapclient requests
COPY ingest.py .
CMD ["python", "ingest.py"]