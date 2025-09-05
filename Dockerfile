FROM python:3.12-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg ca-certificates && \
    rm -rf /var/lib/apt/lists/*

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir --upgrade pip wheel && \
    pip install --no-cache-dir -r requirements.txt

COPY . .

RUN python - <<'PY'
import sysconfig, os, shutil
site = sysconfig.get_paths()["purelib"]  # site-packages 경로
dst_dir = os.path.join(site, "fakeyou")
os.makedirs(dst_dir, exist_ok=True)
shutil.copyfile("objects.py", os.path.join(dst_dir, "objects.py"))
shutil.copyfile("fakeyou_patched.py", os.path.join(dst_dir, "fakeyou.py"))
print("Patched fakeyou in:", dst_dir)
PY

RUN useradd -m app && chown -R app:app /usr/src/app
USER app

CMD ["python", "./main.py"]
