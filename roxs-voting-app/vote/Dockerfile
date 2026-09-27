FROM python:3.12-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

FROM base AS pruebas
RUN pip install --no-cache-dir pytest==8.3.4
CMD ["python", "-m", "pytest", "tests/", "-v"]

FROM base AS produccion
RUN useradd --system --no-create-home --uid 1001 vote && chown -R 1001:1001 /app
USER 1001
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8080/')"]
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "app:app"]
