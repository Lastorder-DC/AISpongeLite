FROM python:3.12

WORKDIR /usr/src/app

RUN apt-get update
RUN apt-get install ffmpeg -y

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

COPY objects.py /usr/local/lib/python3.12/site-packages/fakeyou/
COPY fakeyou.py /usr/local/lib/python3.12/site-packages/fakeyou/

CMD [ "python", "./main.py" ]
