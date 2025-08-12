import pytest
from app import create_app, db, Book

@pytest.fixture
def client():
    test_config = {
        'TESTING': True,
        'SQLALCHEMY_DATABASE_URI': 'sqlite:///:memory:',
    }
    app = create_app(test_config)
    with app.test_client() as client:
        with app.app_context():
            db.create_all()
        yield client

def test_health_check(client):
    rv = client.get('/health')
    assert rv.status_code == 200

def test_crud_books(client):
    # Create
    rv = client.post('/books', json={'title': 'Test', 'author': 'Author'})
    assert rv.status_code == 201

    # Read
    rv = client.get('/books')
    data = rv.get_json()
    test_books = [b for b in data if b['title'] == 'Test']
    assert test_books

    # Update
    book_id = test_books[0]['id']
    rv = client.put(f'/books/{book_id}', json={'title': 'Updated'})
    assert rv.status_code == 200

    # Delete
    rv = client.delete(f'/books/{book_id}')
    assert rv.status_code == 200

    # Confirm deletion
    rv = client.get('/books')
    data = rv.get_json()
    assert all(b['id'] != book_id for b in data)

def test_integration_db(client):
    with client.application.app_context():
        book = Book(title='DB Test', author='Author')
        db.session.add(book)
        db.session.commit()
        b = Book.query.filter_by(title='DB Test').first()
        assert b is not None

