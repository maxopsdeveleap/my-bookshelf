const API_BASE_URL = (() => {
  if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
    return ''; // Relative URLs for dev
  }
  return 'https://mybookshelf.ddns.net'; // Production API URL
})();

document.addEventListener("DOMContentLoaded", function() {
  let editId = null;

  async function load() {
    const books = await fetch(API_BASE + '/books').then(r => r.json());
    const body = document.getElementById('list');
    body.innerHTML = '';
    books.forEach(b => {
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td><strong>${b.title}</strong></td>
        <td>${b.author}</td>
        <td>${b.genre || ''}</td>
        <td>${b.rating ? b.rating + '/5' : ''}</td>
        <td>${b.note || ''}</td>
        <td>
          <button class="edit" onclick="editBook(${b.id})">Edit</button>
          <button class="edit delete" onclick="del(${b.id})">Delete</button>
        </td>`;
      body.appendChild(tr);
    });
  }

  window.del = async function(id){
    await fetch(API_BASE + '/books/' + id, { method: 'DELETE' });
    load();
  };

  window.editBook = async function(id) {
    const books = await fetch(API_BASE + '/books').then(r => r.json());
    const book = books.find(b => b.id === id);
    if (!book) return;
    for (const [key, value] of Object.entries(book)) {
      const field = document.querySelector(`[name="${key}"]`);
      if (field) field.value = value || '';
    }
    editId = id;
    document.querySelector('button[type="submit"]').textContent = 'Update Book';
  };

  document.getElementById('form').onsubmit = async e => {
    e.preventDefault();
    const data = Object.fromEntries(new FormData(e.target).entries());
    if (editId) {
      await fetch(API_BASE + '/books/' + editId, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
      });
      editId = null;
      document.querySelector('button[type="submit"]').textContent = 'Add Book';
    } else {
      await fetch(API_BASE + '/books', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
      });
    }
    e.target.reset();
    load();
  };

  load();
});
