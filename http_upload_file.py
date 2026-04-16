import os
import sys
import uuid
import mimetypes
import http.client
import json

HOST = "8.148.73.190"
PORT = 5000
PATH = "/upload"

APP_KEY = ""
APP_SECRET = ""

def upload_file(file_path, target_path, serial):
    if not os.path.isfile(file_path):
        print("error: file not found")
        return 1

    boundary = "----WebKitFormBoundary" + uuid.uuid4().hex
    filename = os.path.basename(file_path)

    with open(file_path, "rb") as f:
        file_data = f.read()

    content_type = mimetypes.guess_type(filename)[0] or "application/octet-stream"

    parts = []
    parts.append(f"--{boundary}\r\n".encode())
    parts.append(f'Content-Disposition: form-data; name="target_path"\r\n\r\n{target_path}\r\n'.encode())

    parts.append(f"--{boundary}\r\n".encode())
    parts.append(f'Content-Disposition: form-data; name="serial"\r\n\r\n{serial}\r\n'.encode())

    parts.append(f"--{boundary}\r\n".encode())
    parts.append(
        f'Content-Disposition: form-data; name="target_file"; filename="{filename}"\r\n'.encode()
    )
    parts.append(f"Content-Type: {content_type}\r\n\r\n".encode())
    parts.append(file_data)
    parts.append(b"\r\n")
    parts.append(f"--{boundary}--\r\n".encode())

    body = b"".join(parts)

    headers = {
        "Content-Type": f"multipart/form-data; boundary={boundary}",
        "Content-Length": str(len(body)),
    }

    if APP_KEY:
        headers["app_key"] = APP_KEY
    if APP_SECRET:
        headers["app_secret"] = APP_SECRET

    try:
        conn = http.client.HTTPConnection(HOST, PORT, timeout=30)
        conn.request("POST", PATH, body=body, headers=headers)
        resp = conn.getresponse()
        data = resp.read().decode(errors="ignore")
        conn.close()

        print("status:", resp.status)
        print(data)

        if resp.status != 200:
            return 2

        try:
            obj = json.loads(data)
            if obj.get("error_code") == 0:
                return 0
            else:
                return 3
        except Exception:
            return 4

    except Exception as e:
        print("exception:", str(e))
        return 5

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("usage: python3 http_upload_file.py <file_path> <target_path> <serial>")
        sys.exit(1)

    file_path = sys.argv[1]
    target_path = sys.argv[2]
    serial = sys.argv[3]

    ret = upload_file(file_path, target_path, serial)
    sys.exit(ret)