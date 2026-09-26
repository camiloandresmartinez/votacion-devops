FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
	PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN useradd --system --no-create-home vote && chown -R vote:vote /app
# hadolint ignore=DL3066
USER 1001

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8080/')"]

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "app:app"]

