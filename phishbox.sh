#!/usr/bin/env bash
# PhishBox Orchestrator v10.1 - Precision 20/5 Rule
set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-$PWD/phishbox-security}"

green() { printf "\e[32m%s\e[0m\n" "$*"; }
red()   { printf "\e[31m%s\e[0m\n" "$*"; }

usage() {
    cat <<EOF
Uso:
  sudo $0 --install     (Instala Docker e ferramentas no Arch)
  $0 --config           (Configura Credenciais IMAP)
  $0 --up               (Sobe a stack com a regra de 20 e-mails / 5 min)
  $0 --logs-worker      (Ver a análise da Sandbox)
  $0 --logs-ingest      (Ver a contagem de e-mails processados)
  $0 --purge            (Limpa tudo)
EOF
}

# --- 1. INSTALAÇÃO ---
cmd_install() {
    green "Instalando Docker e ferramentas no Arch..."
    sudo pacman -Sy --needed --noconfirm docker docker-compose python-pip
    sudo systemctl enable --now docker
    [ "$USER" != "root" ] && sudo usermod -aG docker "$USER"
    green "Instalação concluída."
}

# --- 2. CONFIGURAÇÃO ---
cmd_config(){
    mkdir -p "$PROJECT_DIR"
    green "--- Configuração da Inbox ---"
    read -p "Email: " imap_user
    read -sp "Senha de App: " imap_pass
    echo ""
    read -p "Servidor IMAP (ex: imap.gmail.com): " imap_host
    
    cat <<EOF > "$PROJECT_DIR/.env"
IMAP_HOST=$imap_host
IMAP_USER=$imap_user
IMAP_PASSWORD=$imap_pass
IMAP_POLL_SECONDS=300
REDIS_URL=redis://redis:6379/0
CLAMAV_HOST=clamav
EOF
}

init_project(){
    mkdir -p "$PROJECT_DIR/services/api" "$PROJECT_DIR/services/worker" "$PROJECT_DIR/services/ingest" "$PROJECT_DIR/data"

    # API - Gateway
    cat <<'EOF' > "$PROJECT_DIR/services/api/main.py"
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
EOF

    # WORKER - Sandbox Deep Scan
    cat <<'EOF' > "$PROJECT_DIR/services/worker/tasks.py"
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
EOF

    # INGEST - Regra de 20 e-mails / 5 minutos
    cat <<'EOF' > "$PROJECT_DIR/services/ingest/ingest.py"
import os, time, requests, json
from imapclient import IMAPClient

STATE_FILE = "/data/last_uid.json"

def get_processed():
    if os.path.exists(STATE_FILE):
        try:
            with open(STATE_FILE, "r") as f: return set(json.load(f).get("processed", []))
        except: return set()
    return set()

def save_processed(processed_set):
    # Mantém apenas os últimos 5000 UIDs no histórico
    with open(STATE_FILE, "w") as f:
        json.dump({"processed": list(processed_set)[-5000:]}, f)

def main():
    while True:
        try:
            processed = get_processed()
            print("[*] Iniciando novo ciclo de varredura (Limite: 20 e-mails)")
            
            with IMAPClient(os.getenv("IMAP_HOST"), ssl=True) as client:
                client.login(os.getenv("IMAP_USER"), os.getenv("IMAP_PASSWORD"))
                client.select_folder("INBOX", readonly=True)
                
                uids = client.search(["ALL"])
                uids.sort(reverse=True) # Mais recentes primeiro

                count = 0
                for uid in uids:
                    if count >= 20: break
                    if uid in processed: continue
                    
                    print(f"[*] Capturando UID {uid} ({count+1}/20)")
                    res = client.fetch([uid], ["RFC822"])
                    raw = res[uid][b"RFC822"]
                    
                    r = requests.post("http://api:8080/analyze", 
                                     files={"file": (f"{uid}.eml", raw)}, 
                                     data={"imap_uid": str(uid)})
                    if r.status_code == 200:
                        processed.add(uid)
                        count += 1
                
                save_processed(processed)
                print(f"[*] Ciclo finalizado. {count} e-mails enviados.")

            print("[ZzZ] Pausa de 5 minutos para evitar bloqueio...")
            time.sleep(300) # 5 Minutos exatos
        except Exception as e:
            print(f"Erro: {e}"); time.sleep(30)

if __name__ == "__main__": main()
EOF

    # Docker-Compose
    cat <<EOF > "$PROJECT_DIR/docker-compose.yml"
services:
  redis: { image: "redis:7-alpine" }
  clamav: { image: "clamav/clamav:stable", restart: always }
  api:
    build: ./services/api
    env_file: .env
  worker:
    build: ./services/worker
    env_file: .env
    depends_on: [redis, clamav]
  ingest:
    build: ./services/ingest
    env_file: .env
    volumes: ["./data:/data"]
    depends_on: [api]
EOF

    # Dockerfiles simplificados
    printf "FROM python:3.12-slim\nWORKDIR /app\nRUN pip install fastapi uvicorn python-multipart celery redis\nCOPY main.py .\nCMD [\"uvicorn\", \"main:app\", \"--host\", \"0.0.0.0\", \"--port\", \"8080\"]" > "$PROJECT_DIR/services/api/Dockerfile"
    printf "FROM python:3.12-slim\nWORKDIR /app\nRUN pip install celery redis imapclient clamd\nCOPY tasks.py .\nCMD [\"celery\", \"-A\", \"tasks\", \"worker\", \"--loglevel=INFO\"]" > "$PROJECT_DIR/services/worker/Dockerfile"
    printf "FROM python:3.12-slim\nWORKDIR /app\nRUN pip install imapclient requests\nCOPY ingest.py .\nCMD [\"python\", \"ingest.py\"]" > "$PROJECT_DIR/services/ingest/Dockerfile"
}

cmd_up(){
    init_project
    cd "$PROJECT_DIR" && docker compose up -d --build
    green "Sistema Online com regra 20/5 Ativa!"
}

case "${1:-}" in
    --install) cmd_install ;;
    --config)  cmd_config ;;
    --up)      cmd_up ;;
    --logs-worker) cd "$PROJECT_DIR" && docker compose logs -f worker ;;
    --logs-ingest) cd "$PROJECT_DIR" && docker compose logs -f ingest ;;
    --purge)   cd "$PROJECT_DIR" && docker compose down -v ;;
    *) usage ;;
esac
