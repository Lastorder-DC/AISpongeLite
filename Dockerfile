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
COPY objects.py /usr/local/lib/python3.12/site-packages/fakeyou/
COPY fakeyou_patched.py /usr/local/lib/python3.12/site-packages/fakeyou/fakeyou.py

RUN useradd -m app && chown -R app:app /usr/src/app
USER app

CMD ["python", "./main.py"]
