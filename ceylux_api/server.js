const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const app = express();
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

const JWT_SECRET = 'ceylux_secret_2025';

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

// PostgreSQL
const pool = new Pool({
  host: 'localhost', port: 5432,
  database: 'ceylux_db', user: 'postgres',
  password: 'Thisara@2245',
});

pool.connect((err) => {
  if (err) console.error('DB error:', err.message);
  else console.log('✅ PostgreSQL connected!');
});

// Create users table if not exists
pool.query(`
  CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    role TEXT DEFAULT 'staff',
    created_at TIMESTAMPTZ DEFAULT now()
  )
`).catch(console.error);

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

    const exists = await pool.query('SELECT id FROM users WHERE email=$1', [email]);
    if (exists.rows.length > 0)
      return res.status(400).json({ error: 'Email already registered' });

    const hashed = await bcrypt.hash(password, 10);
    const r = await pool.query(
      'INSERT INTO users (name,email,password) VALUES ($1,$2,$3) RETURNING id,name,email,role',
      [name, email, hashed]
    );
    const user = r.rows[0];
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

    const r = await pool.query('SELECT * FROM users WHERE email=$1', [email]);
    if (r.rows.length === 0)
      return res.status(400).json({ error: 'Email not found' });

    const user = r.rows[0];
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
  const url = `http://${req.headers.host}/uploads/${req.params.folder}/${req.file.filename}`;
  res.json({ url });
});

// ── STOCK ──────────────────────────────────────────────────────────────────
app.get('/stock', async (req, res) => {
  const r = await pool.query('SELECT * FROM stock ORDER BY name');
  res.json(r.rows);
});
app.post('/stock', async (req, res) => {
  const { name, category, sku, min_qty, price, cost, emoji, photo_url, sizes } = req.body;
  const r = await pool.query(
    'INSERT INTO stock (name,category,sku,min_qty,price,cost,emoji,photo_url,sizes) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *',
    [name, category, sku, min_qty, price, cost, emoji, photo_url, JSON.stringify(sizes)]
  );
  res.json(r.rows[0]);
});
app.put('/stock/:id', async (req, res) => {
  const { name, category, sku, min_qty, price, cost, emoji, photo_url, sizes } = req.body;
  const r = await pool.query(
    'UPDATE stock SET name=$1,category=$2,sku=$3,min_qty=$4,price=$5,cost=$6,emoji=$7,photo_url=$8,sizes=$9 WHERE id=$10 RETURNING *',
    [name, category, sku, min_qty, price, cost, emoji, photo_url, JSON.stringify(sizes), req.params.id]
  );
  res.json(r.rows[0]);
});
app.delete('/stock/:id', async (req, res) => {
  await pool.query('DELETE FROM stock WHERE id=$1', [req.params.id]);
  res.json({ success: true });
});

// ── CUSTOMERS ──────────────────────────────────────────────────────────────
app.get('/customers', async (req, res) => {
  const r = await pool.query('SELECT * FROM customers ORDER BY name');
  res.json(r.rows);
});
app.post('/customers', async (req, res) => {
  const { name, phone, email, address, photo_url } = req.body;
  const r = await pool.query(
    'INSERT INTO customers (name,phone,email,address,photo_url) VALUES ($1,$2,$3,$4,$5) RETURNING *',
    [name, phone, email, address, photo_url]
  );
  res.json(r.rows[0]);
});
app.put('/customers/:id', async (req, res) => {
  const { name, phone, email, address, photo_url } = req.body;
  const r = await pool.query(
    'UPDATE customers SET name=$1,phone=$2,email=$3,address=$4,photo_url=$5 WHERE id=$6 RETURNING *',
    [name, phone, email, address, photo_url, req.params.id]
  );
  res.json(r.rows[0]);
});
app.delete('/customers/:id', async (req, res) => {
  await pool.query('DELETE FROM customers WHERE id=$1', [req.params.id]);
  res.json({ success: true });
});

// ── ORDERS ─────────────────────────────────────────────────────────────────
app.get('/orders', async (req, res) => {
  const r = await pool.query('SELECT * FROM orders ORDER BY created_at DESC');
  res.json(r.rows);
});
app.post('/orders', async (req, res) => {
  const { order_ref, customer_id, customer_name, items, total, status, date } = req.body;
  const r = await pool.query(
    'INSERT INTO orders (order_ref,customer_id,customer_name,items,total,status,date) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *',
    [order_ref, customer_id, customer_name, JSON.stringify(items), total, status, date]
  );
  await pool.query(
    'UPDATE customers SET total_orders=total_orders+1,total_spent=total_spent+$1 WHERE id=$2',
    [total, customer_id]
  );
  res.json(r.rows[0]);
});
app.put('/orders/:id/status', async (req, res) => {
  const r = await pool.query(
    'UPDATE orders SET status=$1 WHERE id=$2 RETURNING *',
    [req.body.status, req.params.id]
  );
  res.json(r.rows[0]);
});

// ── SEED ───────────────────────────────────────────────────────────────────
app.get('/seed', async (req, res) => {
  const count = await pool.query('SELECT COUNT(*) FROM stock');
  if (parseInt(count.rows[0].count) > 0)
    return res.json({ message: 'Already seeded' });

  await pool.query(`
    INSERT INTO stock (name,category,sku,min_qty,price,cost,emoji,sizes) VALUES
    ('Silk Kurta - Navy','Men','MK-001',15,4500,2800,'👔','{"XS":0,"S":1,"M":2,"L":3,"XL":1,"XXL":0}'),
    ('Batik Saree - Maroon','Women','WS-012',15,6800,4200,'👗','{"XS":2,"S":4,"M":3,"L":2,"XL":1,"XXL":0}'),
    ('Linen Shirt - White','Men','ML-023',15,3200,1900,'👕','{"XS":0,"S":0,"M":1,"L":1,"XL":0,"XXL":0}'),
    ('Cotton Frock - Pink','Kids','KF-034',15,2100,1200,'👚','{"2Y":0,"4Y":0,"6Y":2,"8Y":1,"10Y":0,"12Y":0}'),
    ('Formal Trouser - Black','Men','MT-045',15,3800,2300,'👖','{"XS":1,"S":2,"M":3,"L":2,"XL":0,"XXL":0}'),
    ('Floral Blouse - Yellow','Women','WB-056',15,2900,1700,'👘','{"XS":1,"S":1,"M":2,"L":0,"XL":0,"XXL":0}')
  `);
  await pool.query(`
    INSERT INTO customers (name,phone,email,address,total_orders,total_spent) VALUES
    ('Nimal Perera','0771234567','nimal@gmail.com','12, Galle Rd, Colombo 3',5,28500),
    ('Sandya Silva','0712345678','sandya@yahoo.com','45, Kandy Rd, Kurunegala',3,15200),
    ('Rohan Fernando','0763456789','rohan@gmail.com','78, Temple Rd, Kandy',8,52000)
  `);
  res.json({ message: 'Seeded!' });
});

app.listen(3000, '0.0.0.0', () => console.log('🚀 Ceylux API on http://0.0.0.0:3000'));