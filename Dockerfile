FROM python:3.12

WORKDIR /usr/src/app

RUN apt-get update
RUN apt-get install ffmpeg -y

COPY . .
RUN pip install --no-cache-dir -r requirements.txt

COPY objects.py /usr/local/lib/python3.12/site-packages/fakeyou/

CMD [ "python", "./main.py" ]
