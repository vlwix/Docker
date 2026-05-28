# Stage 1: build production dependencies
FROM python:3.12-slim AS builder
WORKDIR /app
COPY pyproject.toml .
RUN python -m venv /venv && \
    /venv/bin/pip install --no-cache-dir .

# Stage 2: test image — adds test deps on top of builder
FROM builder AS test
RUN /venv/bin/pip install --no-cache-dir \
    "pytest>=6.2.5" \
    "pytest-asyncio==0.25.3" \
    "httpx==0.28.1"
COPY . .
ENV PATH="/venv/bin:$PATH"
CMD ["pytest", "tests", "-v"]

# Stage 3: production image — minimal, without test deps
FROM python:3.12-slim AS production
WORKDIR /app
COPY --from=builder /venv /venv
COPY src/ ./src/
ENV PATH="/venv/bin:$PATH"
EXPOSE 8063
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8063"]
