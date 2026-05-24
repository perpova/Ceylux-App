require('dotenv').config();
const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const app = express();
app.set('trust proxy', true);
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

const JWT_SECRET = process.env.JWT_SECRET || 'ceylux_secret_2025';

// Multer
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const folder = path.join(__dirname, 'uploads', req.params.folder);
    fs.mkdirSync(folder, { recursive: true });
    cb(null, folder);
  },
  filename: (req, file, cb) => cb(null, Date.now() + '.jpg')
});
const upload = multer({ storage });

// MySQL pool connection
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'loacalhost',
  port: parseInt(process.env.DB_PORT) || 3306,
  database: process.env.DB_NAME || 'u321040896_ceylux_ak',
  user: process.env.DB_USER || 'u321040896_mr_kishen',
  password: process.env.DB_PASS || '2&eL4|YEIrlU',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// Initialize database schema (Create tables if not exists)
async function initDB() {
  try {
    // 1. users table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        role VARCHAR(50) DEFAULT 'staff',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // 2. stock table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS stock (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        category VARCHAR(100),
        sku VARCHAR(100),
        min_qty INT DEFAULT 0,
        price DECIMAL(10,2) DEFAULT 0.00,
        cost DECIMAL(10,2) DEFAULT 0.00,
        emoji VARCHAR(50),
        photo_url TEXT,
        sizes JSON,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // 3. customers table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS customers (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        phone VARCHAR(50),
        email VARCHAR(255),
        address TEXT,
        photo_url TEXT,
        total_orders INT DEFAULT 0,
        total_spent DECIMAL(10,2) DEFAULT 0.00,
        owner_rating DECIMAL(2,1) DEFAULT 0.0,
        owner_note TEXT DEFAULT '',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // 4. orders table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS orders (
        id INT AUTO_INCREMENT PRIMARY KEY,
        order_ref VARCHAR(100) NOT NULL,
        customer_id INT,
        customer_name VARCHAR(255),
        items JSON,
        total DECIMAL(10,2) DEFAULT 0.00,
        status VARCHAR(50) DEFAULT 'Pending',
        date VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    console.log('✅ MySQL Database initialized and tables verified!');
  } catch (err) {
    console.error('❌ Error initializing MySQL database schema:', err.message);
  }
}

// Test connection and initialize schema
(async () => {
  try {
    const connection = await pool.getConnection();
    console.log('✅ MySQL connected!');
    connection.release();
    await initDB();
  } catch (err) {
    console.error('❌ MySQL Connection/Initialization error:', err.message);
  }
})();

// Health check endpoint
app.get('/', (req, res) => {
  res.json({
    status: 'ok',
    message: 'Ceylux API is running successfully'
  });
});

// ── AUTH MIDDLEWARE ────────────────────────────────────────────────────────
function auth(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token' });
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ error: 'Invalid token' });
  }
}

// ── SIGNUP ─────────────────────────────────────────────────────────────────
app.post('/auth/signup', async (req, res) => {
  try {
    const { name, email, password } = req.body;
    if (!name || !email || !password)
      return res.status(400).json({ error: 'All fields required' });

    const [exists] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
    if (exists.length > 0)
      return res.status(400).json({ error: 'Email already registered' });

    const hashed = await bcrypt.hash(password, 10);
    const [result] = await pool.query(
      'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
      [name, email, hashed]
    );

    const [userRows] = await pool.query('SELECT id, name, email, role FROM users WHERE id = ?', [result.insertId]);
    const user = userRows[0];

    const token = jwt.sign({ id: user.id, email: user.email, name: user.name }, JWT_SECRET, { expiresIn: '30d' });
    res.json({ token, user });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── SIGNIN ─────────────────────────────────────────────────────────────────
app.post('/auth/signin', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password)
      return res.status(400).json({ error: 'Email and password required' });

    const [rows] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
    if (rows.length === 0)
      return res.status(400).json({ error: 'Email not found' });

    const user = rows[0];
    const valid = await bcrypt.compare(password, user.password);
    if (!valid)
      return res.status(400).json({ error: 'Wrong password' });

    const token = jwt.sign({ id: user.id, email: user.email, name: user.name }, JWT_SECRET, { expiresIn: '30d' });
    res.json({ token, user: { id: user.id, name: user.name, email: user.email, role: user.role } });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── PHOTO UPLOAD ───────────────────────────────────────────────────────────
app.post('/upload/:folder', upload.single('photo'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No file' });
  const protocol = req.headers['x-forwarded-proto'] || req.protocol;
  const baseUrl = process.env.BASE_URL || `${protocol}://${req.headers.host}`;
  const url = `${baseUrl}/uploads/${req.params.folder}/${req.file.filename}`;
  res.json({ url });
});

// ── STOCK ──────────────────────────────────────────────────────────────────
app.get('/stock', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM stock ORDER BY name');
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/stock', async (req, res) => {
  try {
    const { name, category, sku, min_qty, price, cost, emoji, photo_url, sizes } = req.body;
    const [result] = await pool.query(
      'INSERT INTO stock (name, category, sku, min_qty, price, cost, emoji, photo_url, sizes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [name, category, sku, min_qty, price, cost, emoji, photo_url, JSON.stringify(sizes)]
    );
    const [rows] = await pool.query('SELECT * FROM stock WHERE id = ?', [result.insertId]);
    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.put('/stock/:id', async (req, res) => {
  try {
    const { name, category, sku, min_qty, price, cost, emoji, photo_url, sizes } = req.body;
    await pool.query(
      'UPDATE stock SET name = ?, category = ?, sku = ?, min_qty = ?, price = ?, cost = ?, emoji = ?, photo_url = ?, sizes = ? WHERE id = ?',
      [name, category, sku, min_qty, price, cost, emoji, photo_url, JSON.stringify(sizes), req.params.id]
    );
    const [rows] = await pool.query('SELECT * FROM stock WHERE id = ?', [req.params.id]);
    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.delete('/stock/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM stock WHERE id = ?', [req.params.id]);
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── CUSTOMERS ──────────────────────────────────────────────────────────────
app.get('/customers', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM customers ORDER BY name');
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/customers', async (req, res) => {
  try {
    const { name, phone, email, address, photo_url, owner_rating, owner_note } = req.body;
    const [result] = await pool.query(
      'INSERT INTO customers (name, phone, email, address, photo_url, owner_rating, owner_note) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [name, phone, email, address, photo_url, owner_rating || 0, owner_note || '']
    );
    const [rows] = await pool.query('SELECT * FROM customers WHERE id = ?', [result.insertId]);
    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.put('/customers/:id', async (req, res) => {
  try {
    const { name, phone, email, address, photo_url, owner_rating, owner_note } = req.body;
    await pool.query(
      'UPDATE customers SET name = ?, phone = ?, email = ?, address = ?, photo_url = ?, owner_rating = ?, owner_note = ? WHERE id = ?',
      [name, phone, email, address, photo_url, owner_rating || 0, owner_note || '', req.params.id]
    );
    const [rows] = await pool.query('SELECT * FROM customers WHERE id = ?', [req.params.id]);
    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.delete('/customers/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM customers WHERE id = ?', [req.params.id]);
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── ORDERS ─────────────────────────────────────────────────────────────────
app.get('/orders', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM orders ORDER BY created_at DESC');
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/orders', async (req, res) => {
  try {
    const { order_ref, customer_id, customer_name, items, total, status, date } = req.body;
    const [result] = await pool.query(
      'INSERT INTO orders (order_ref, customer_id, customer_name, items, total, status, date) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [order_ref, customer_id, customer_name, JSON.stringify(items), total, status, date]
    );
    const [rows] = await pool.query('SELECT * FROM orders WHERE id = ?', [result.insertId]);

    await pool.query(
      'UPDATE customers SET total_orders = total_orders + 1, total_spent = total_spent + ? WHERE id = ?',
      [total, customer_id]
    );

    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.put('/orders/:id/status', async (req, res) => {
  try {
    await pool.query(
      'UPDATE orders SET status = ? WHERE id = ?',
      [req.body.status, req.params.id]
    );
    const [rows] = await pool.query('SELECT * FROM orders WHERE id = ?', [req.params.id]);
    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── SEED ───────────────────────────────────────────────────────────────────
app.get('/seed', async (req, res) => {
  try {
    const [countRows] = await pool.query('SELECT COUNT(*) AS count FROM stock');
    if (parseInt(countRows[0].count) > 0)
      return res.json({ message: 'Already seeded' });

    await pool.query(`
      INSERT INTO stock (name, category, sku, min_qty, price, cost, emoji, sizes) VALUES
      ('Silk Kurta - Navy', 'Men', 'MK-001', 15, 4500, 2800, '👔', '{"XS":0,"S":1,"M":2,"L":3,"XL":1,"XXL":0}'),
      ('Batik Saree - Maroon', 'Women', 'WS-012', 15, 6800, 4200, '👗', '{"XS":2,"S":4,"M":3,"L":2,"XL":1,"XXL":0}'),
      ('Linen Shirt - White', 'Men', 'ML-023', 15, 3200, 1900, '👕', '{"XS":0,"S":0,"M":1,"L":1,"XL":0,"XXL":0}'),
      ('Cotton Frock - Pink', 'Kids', 'KF-034', 15, 2100, 1200, '👚', '{"2Y":0,"4Y":0,"6Y":2,"8Y":1,"10Y":0,"12Y":0}'),
      ('Formal Trouser - Black', 'Men', 'MT-045', 15, 3800, 2300, '👖', '{"XS":1,"S":2,"M":3,"L":2,"XL":0,"XXL":0}'),
      ('Floral Blouse - Yellow', 'Women', 'WB-056', 15, 2900, 1700, '👘', '{"XS":1,"S":1,"M":2,"L":0,"XL":0,"XXL":0}')
    `);

    await pool.query(`
      INSERT INTO customers (name, phone, email, address, total_orders, total_spent) VALUES
      ('Nimal Perera', '0771234567', 'nimal@gmail.com', '12, Galle Rd, Colombo 3', 5, 28500),
      ('Sandya Silva', '0712345678', 'sandya@yahoo.com', '45, Kandy Rd, Kurunegala', 3, 15200),
      ('Rohan Fernando', '0763456789', 'rohan@gmail.com', '78, Temple Rd, Kandy', 8, 52000)
    `);

    res.json({ message: 'Seeded!' });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => console.log(`🚀 Ceylux API on http://0.0.0.0:${PORT}`));