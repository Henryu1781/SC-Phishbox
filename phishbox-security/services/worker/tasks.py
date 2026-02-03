import os, io, clamd, email
from email import policy
from celery import Celery
from imapclient import IMAPClient

celery = Celery("phishbox", broker=os.getenv("REDIS_URL"))

def sandbox_scan(data):
    if b"EICAR-STANDARD-ANTIVIRUS-TEST-FILE" in data: return "malicious"
    try:
        cd = clamd.ClamdNetworkSocket(os.getenv("CLAMAV_HOST"), 3310)
        res = cd.instream(io.BytesIO(data))
        return "malicious" if 'FOUND' in str(res) else "clean"
    except: return "clean"

def imap_triage(uid, verdict):
    try:
        with IMAPClient(os.getenv("IMAP_HOST"), ssl=True) as client:
            client.login(os.getenv("IMAP_USER"), os.getenv("IMAP_PASSWORD"))
            folder = f"PhishBox/{'Infected' if verdict == 'malicious' else 'Clean'}"
            for f in ["PhishBox", folder]:
                if not client.folder_exists(f): client.create_folder(f)
            client.select_folder("INBOX")
            client.move([int(uid)], folder)
            print(f"[TRIAGEM] UID {uid} -> {folder}")
    except Exception as e: print(f"[IMAP ERR] {e}")

@celery.task(name="tasks.process_email")
def process_email(sid, filename, raw, imap_uid=None):
    verdict = "clean"
    try:
        msg = email.message_from_bytes(raw, policy=policy.default)
        for part in msg.walk():
            if part.get_content_maintype() == 'multipart': continue
            payload = part.get_payload(decode=True)
            if payload and sandbox_scan(payload) == "malicious":
                verdict = "malicious"; break
    except: pass
    if imap_uid: imap_triage(imap_uid, verdict)
