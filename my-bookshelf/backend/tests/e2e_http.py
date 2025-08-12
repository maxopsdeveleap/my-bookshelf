import requests

BASE_URL = "http://localhost:5000"

def test_health():
    r = requests.get(f"{BASE_URL}/health")
    assert r.status_code == 200

def test_add_get_delete_book():
    # Add a book
    payload = {"title": "E2E Test", "author": "ChatGPT"}
    r = requests.post(f"{BASE_URL}/books", json=payload)
    print("POST /books status:", r.status_code, "response:", r.text)
    assert r.status_code == 201
    book = r.json()
    print("POST /books response:", book)  # debug print

    # Handle missing 'id'
    if "id" not in book:
        raise Exception(f"POST /books did not return an 'id'. Got: {book}")

    book_id = book["id"]

    # Get all books
    r = requests.get(f"{BASE_URL}/books")
    assert r.status_code == 200
    assert any(b["id"] == book_id for b in r.json())

    # Delete book
    r = requests.delete(f"{BASE_URL}/books/{book_id}")
    assert r.status_code == 204 or r.status_code == 200  # Accept 204 or 200

    # Ensure it's gone
    r = requests.get(f"{BASE_URL}/books")
    assert all(b["id"] != book_id for b in r.json())

if __name__ == "__main__":
    test_health()
    test_add_get_delete_book()
    print("E2E tests passed!")
