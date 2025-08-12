from flask import Flask, request, jsonify, Response
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import text
import sys
import os
import time
import logging
from pythonjsonlogger import jsonlogger
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
from flask_cors import CORS

db = SQLAlchemy()

# Prometheus metric for HTTP requests
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP Requests', ['method', 'endpoint', 'http_status'])

class Book(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String, nullable=False)
    author = db.Column(db.String, nullable=False)
    genre = db.Column(db.String)
    rating = db.Column(db.Integer)
    note = db.Column(db.String)

def create_book(data):
    book = Book(**data)
    db.session.add(book)
    db.session.commit()
    return book

def update_book_by_id(book_id, data):
    book = db.session.get(Book, book_id)
    if not book:
        return None
    for field in ['title', 'author', 'genre', 'rating', 'note']:
        if field in data:
            setattr(book, field, data[field])
    db.session.commit()
    return book

def delete_book_by_id(book_id):
    book = db.session.get(Book, book_id)
    if not book:
        return None
    db.session.delete(book)
    db.session.commit()
    return book

def create_app(test_config=None):
    app = Flask(__name__)
    # Fixed CORS configuration with correct domain
    CORS(app, origins=["https://d29uf7fg4cztcx.cloudfront.net"], supports_credentials=True, methods=["GET", "POST", "PUT", "DELETE"], allow_headers=["Content-Type"])
    
    # Setup JSON logging
    logger = logging.getLogger()
    logHandler = logging.StreamHandler()
    formatter = jsonlogger.JsonFormatter('%(asctime)s %(levelname)s %(message)s %(name)s %(module)s %(funcName)s')
    logHandler.setFormatter(formatter)
    logger.addHandler(logHandler)
    logger.setLevel(logging.INFO)

    if test_config:
        app.config.update(test_config)
    else:
        app.config["SQLALCHEMY_DATABASE_URI"] = os.getenv(
            "DATABASE_URL", "postgresql://postgres:postgres@db:5432/books"
        )
    db.init_app(app)
    with app.app_context():
        db.create_all()
    
    @app.before_request
    def before_request():
        request.start_time = time.time()

    @app.after_request
    def after_request(response):
        REQUEST_COUNT.labels(request.method, request.path, response.status_code).inc()
        return response

    @app.route("/metrics")
    def metrics():
        return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

    @app.route("/books", methods=["GET"])
    def get_books():
        books = Book.query.all()
        return jsonify([{
            "id": b.id,
            "title": b.title,
            "author": b.author,
            "genre": b.genre,
            "rating": b.rating,
            "note": b.note
        } for b in books])

    @app.route("/books", methods=["POST"])
    def add_book():
        data = request.json
        book = create_book(data)
        return jsonify({
            "id": book.id,
            "title": book.title,
            "author": book.author,
            "genre": book.genre,
            "rating": book.rating,
            "note": book.note
        }), 201

    @app.route("/books/<int:id>", methods=["DELETE"])
    def delete_book(id):
        book = delete_book_by_id(id)
        if not book:
            return jsonify({"error": "Not found"}), 404
        return jsonify({"message": "Book deleted"})

    @app.route("/books/<int:id>", methods=["PUT"])
    def update_book(id):
        data = request.json
        book = update_book_by_id(id, data)
        if not book:
            return jsonify({"error": "Not found"}), 404
        return jsonify({"message": "Book updated"})

    @app.route("/health")
    def health():
        try:
            db.session.execute(text("SELECT 1"))
            return "OK", 200
        except Exception as e:
            app.logger.error("Health error: %s", e)
            return "DB error", 500

    # Liveness probe: app running
    @app.route("/livez")
    def livez():
        return "OK", 200

    # Readiness probe: DB connectivity
    @app.route("/readyz")
    def readyz():
        try:
            db.session.execute(text("SELECT 1"))
            return "OK", 200
        except Exception as e:
            app.logger.error("Readyz DB error: %s", e)
            return "DB error", 500

    print("STARTING APP.PY", file=sys.stderr)
    return app

if __name__ == "__main__":
    app = create_app()
    app.run(host="0.0.0.0")