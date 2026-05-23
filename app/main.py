from flask import Flask, request, jsonify
import random, time
app = Flask(__name__)
VERSION = "v1.0.0"

@app.route("/")
def home():
    return f"Hello from {VERSION}"

@app.route("/healthz")
def health():
    return "ok"

@app.route("/api")
def api():
    # simulate occasional errors in canary
    if request.headers.get("X-Version") == "canary" and random.random() < 0.03:
        return jsonify(error="boom"), 500
    time.sleep(random.uniform(0.02, 0.12))
    return jsonify(version=VERSION, ok=True)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
