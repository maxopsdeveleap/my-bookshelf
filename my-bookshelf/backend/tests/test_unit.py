import unittest
from unittest.mock import patch, MagicMock
from app import create_book, update_book_by_id, delete_book_by_id, Book

class TestBookLogic(unittest.TestCase):
    @patch('app.db.session')
    def test_create_book(self, mock_session):
        data = {'title': 'Test', 'author': 'Author'}
        book = create_book(data)
        mock_session.add.assert_called_once()
        mock_session.commit.assert_called_once()
        self.assertEqual(book.title, 'Test')

    @patch('app.db.session')
    def test_update_book_by_id_found(self, mock_session):
        book = MagicMock(spec=Book)
        book.id = 1
        book.title = 'Old Title'
        mock_session.get.return_value = book

        data = {'title': 'New Title'}
        updated = update_book_by_id(1, data)
        self.assertEqual(updated.title, 'New Title')
        mock_session.commit.assert_called_once()

    @patch('app.db.session')
    def test_update_book_by_id_not_found(self, mock_session):
        mock_session.get.return_value = None
        updated = update_book_by_id(999, {'title': 'Nope'})
        self.assertIsNone(updated)

    @patch('app.db.session')
    def test_delete_book_by_id_found(self, mock_session):
        book = MagicMock(spec=Book)
        mock_session.get.return_value = book
        deleted = delete_book_by_id(1)
        mock_session.delete.assert_called_once_with(book)
        mock_session.commit.assert_called_once()
        self.assertEqual(deleted, book)

    @patch('app.db.session')
    def test_delete_book_by_id_not_found(self, mock_session):
        mock_session.get.return_value = None
        deleted = delete_book_by_id(999)
        self.assertIsNone(deleted)

if __name__ == '__main__':
    unittest.main()
