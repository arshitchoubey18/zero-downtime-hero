FROM python:3.11-slim
WORKDIR /app
RUN pip install flask prometheus_client
COPY main.py .
ENV VERSION=v1.0.0
EXPOSE 8080
CMD ["python","main.py"]
