# builder: ставим только runtime-зависимости приложения в venv
FROM python:3.12-slim AS builder

WORKDIR /app

COPY pyproject.toml .
COPY src/ ./src/

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir .

# runtime: финальный образ для podman/production (без тестов и pytest)
FROM python:3.12-slim AS runtime

WORKDIR /app

COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY --from=builder /app/src ./src

ENV PORT=8063
EXPOSE 8063

RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

CMD ["sh", "-c", "exec uvicorn src.main:app --host 0.0.0.0 --port ${PORT}"]

# test: слой только для CI (pytest + код тестов)
FROM runtime AS test

USER root
COPY pyproject.toml .
COPY tests/ ./tests/
RUN pip install --no-cache-dir ".[test]" \
    && chown -R appuser:appuser /app/tests
USER appuser

WORKDIR /app
CMD ["python", "-m", "pytest", "tests", "-v"]
