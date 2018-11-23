FROM python:3.6-alpine

WORKDIR /app/django_demo

ENV DJANGO_SETTINGS_MODULE django_demo.settings
ENV PIPENV_DONT_USE_PYENV 1

RUN apk add --update \
    coreutils \
    gcc \
    libffi-dev \
    make \
    musl-dev \
    postgresql-dev \
    python3-dev \
  && pip install pipenv \
  && rm -rf /var/cache/apk/*

COPY Makefile /app/django_demo
COPY Pipfile /app/django_demo
COPY Pipfile.lock /app/django_demo

# TODO Switch to environment variable when https://github.com/pypa/pipenv/issues/3278 is resolved.
RUN pipenv install --dev --system

COPY . /app/django_demo

RUN mkdir -p /logs \
    && touch /logs/app.log \
    && touch /logs/gunicorn.log

ENV PUBLIC_ROOT /public
ENV LOG_FILE_PATH /logs
ENV ENABLE_LOGGING_TO_FILE true

VOLUME /public/media

EXPOSE 8000

ENTRYPOINT ["/app/django_demo/docker-entrypoint.sh"]
