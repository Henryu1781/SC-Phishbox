import os, uuid
from fastapi import FastAPI, UploadFile, File, Form
from celery import Celery
celery = Celery("phishbox", broker=os.getenv("REDIS_URL"))
app = FastAPI()
@app.post("/analyze")
async def analyze(file: UploadFile = File(...), imap_uid: str = Form(None)):
    content = await file.read()
    celery.send_task("tasks.process_email", args=[str(uuid.uuid4()), file.filename, content, imap_uid])
    return {"status": "queued", "uid": imap_uid}
