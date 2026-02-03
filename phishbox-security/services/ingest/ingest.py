import os, time, requests, json
from imapclient import IMAPClient

STATE_FILE = "/data/last_uid.json"

def get_processed():
    if os.path.exists(STATE_FILE):
        try:
            with open(STATE_FILE, "r") as f:
                data = json.load(f)
                return set(data.get("processed", []))
        except Exception as e:
            print(f"[DEBUG] Erro ao ler estado: {e}")
            return set()
    return set()

def save_processed(processed_set):
    try:
        with open(STATE_FILE, "w") as f:
            json.dump({"processed": list(processed_set)}, f)
    except Exception as e:
        print(f"[DEBUG] Erro ao gravar estado: {e}")

def main():
    print("[SYSTEM] Ingest Service Iniciado. A aguardar primeira conexão...")
    while True:
        try:
            processed = get_processed()
            print(f"[DEBUG] Conectando ao host: {os.getenv('IMAP_HOST')}...")
            
            with IMAPClient(os.getenv("IMAP_HOST"), ssl=True) as client:
                client.login(os.getenv("IMAP_USER"), os.getenv("IMAP_PASSWORD"))
                client.select_folder("INBOX", readonly=True)
                
                print("[DEBUG] Procurando e-mails na Inbox (pode demorar)...")
                uids = client.search(["ALL"])
                uids.sort(reverse=True)
                
                print(f"[DEBUG] Total de e-mails encontrados: {len(uids)}")
                
                count = 0
                for uid in uids:
                    if count >= 20: break
                    if uid in processed: continue
                    
                    print(f"[+] Processando UID: {uid} ({count+1}/20)")
                    res = client.fetch([uid], ["RFC822"])
                    raw = res[uid][b"RFC822"]
                    
                    r = requests.post("http://api:8080/analyze", 
                                     files={"file": (f"{uid}.eml", raw)}, 
                                     data={"imap_uid": str(uid)})
                    
                    if r.status_code == 200:
                        processed.add(uid)
                        count += 1
                
                save_processed(processed)
                if count > 0:
                    print(f"[*] Ciclo concluído. {count} e-mails enviados.")
                else:
                    print("[*] Nada de novo para processar.")

            print("[ZzZ] Pausa de 5 minutos (300s)...")
            time.sleep(300)
            
        except Exception as e:
            print(f"[!!!] ERRO CRÍTICO: {e}")
            time.sleep(30)

if __name__ == "__main__": main()
