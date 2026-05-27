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
    const pathParts = req.path.split('/');
    const folderName = (pathParts.length >= 3 && pathParts[1] === 'upload')
      ? pathParts[2]
      : 'payment-proofs';
    const folder = path.join(__dirname, 'uploads', folderName);
    fs.mkdirSync(folder, { recursive: true });
    cb(null, folder);
  },
  filename: (req, file, cb) => cb(null, Date.now() + '.jpg')
});
const upload = multer({ storage });

// MySQL pool connection
const pool = mysql.createPool({
  host: process.env.DB_HOST || '127.0.0.1',
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
        phone VARCHAR(50),
        profileImageUrl TEXT,
        role VARCHAR(50) DEFAULT 'staff',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `)

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
        discount INT DEFAULT 0,
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
        customer_address TEXT,
        customer_phone VARCHAR(50),
        items JSON,
        total DECIMAL(10,2) DEFAULT 0.00,
        discount_percentage INT DEFAULT 0,
        loyalty_discount INT DEFAULT 0,
        status VARCHAR(50) DEFAULT 'Pending',
        date VARCHAR(50),
        delivery_method_id VARCHAR(100),
        delivery_method_name VARCHAR(255),
        payment_proof_url TEXT,
        delivery_notes TEXT,
        payment_method_id VARCHAR(100),
        payment_method_name VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);


    // 5. tiers table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS tiers (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        emoji VARCHAR(10),
        min_orders INT DEFAULT 0,
        min_spent DECIMAL(10,2) DEFAULT 0.00,
        min_rating DECIMAL(2,1) DEFAULT 0.0,
        discount_percentage INT DEFAULT 0,
        priority INT DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // 6. delivery_methods table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS delivery_methods (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        emoji VARCHAR(10),
        account_details TEXT,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // 7. payment_methods table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS payment_methods (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        emoji VARCHAR(10),
        is_active BOOLEAN DEFAULT TRUE,
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

// ── PAYMENT PROOF UPLOAD ───────────────────────────────────────────────────
app.post('/upload/payment-proofs', upload.single('proof'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No file' });
  const protocol = req.headers['x-forwarded-proto'] || req.protocol;
  const baseUrl = process.env.BASE_URL || `${protocol}://${req.headers.host}`;
  const url = `${baseUrl}/uploads/payment-proofs/${req.file.filename}`;
  res.json({ url });
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
    const { name, category, sku, min_qty, price, cost, discount, emoji, photo_url, sizes } = req.body;
    const [result] = await pool.query(
      'INSERT INTO stock (name, category, sku, min_qty, price, cost, discount, emoji, photo_url, sizes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [name, category, sku, min_qty, price, cost, discount || 0, emoji, photo_url, JSON.stringify(sizes)]
    );
    const [rows] = await pool.query('SELECT * FROM stock WHERE id = ?', [result.insertId]);
    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.put('/stock/:id', async (req, res) => {
  try {
    const { name, category, sku, min_qty, price, cost, discount, emoji, photo_url, sizes } = req.body;
    await pool.query(
      'UPDATE stock SET name = ?, category = ?, sku = ?, min_qty = ?, price = ?, cost = ?, discount = ?, emoji = ?, photo_url = ?, sizes = ? WHERE id = ?',
      [name, category, sku, min_qty, price, cost, discount || 0, emoji, photo_url, JSON.stringify(sizes), req.params.id]
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
    
    // Validation
    if (!name || !phone) {
      return res.status(400).json({ error: 'Name and phone are required' });
    }
    
    console.log('Adding customer:', { name, phone, email });
    
    const [result] = await pool.query(
      'INSERT INTO customers (name, phone, email, address, photo_url) VALUES (?, ?, ?, ?, ?)',
      [name || '', phone || '', email || '', address || '', photo_url || null]
    );
    
    console.log('Customer added with ID:', result.insertId);
    
    const [rows] = await pool.query('SELECT * FROM customers WHERE id = ?', [result.insertId]);
    
    if (rows.length === 0) {
      return res.status(500).json({ error: 'Failed to retrieve inserted customer' });
    }
    
    res.json(rows[0]);
  } catch (e) {
    console.error('Customer creation error:', e.message);
    res.status(500).json({ error: e.message });
  }
});

app.put('/customers/:id', async (req, res) => {
  try {
    const { name, phone, email, address, photo_url, owner_rating, owner_note } = req.body;
    await pool.query(
      'UPDATE customers SET name = ?, phone = ?, email = ?, address = ?, photo_url = ?, owner_rating = ?, owner_note = ? WHERE id = ?',
      [name, phone, email, address, photo_url || null, owner_rating || 0, owner_note || '', req.params.id]
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
    const { order_ref, customer_id, customer_name, customer_address, customer_phone, items, total, status, date, discount_percentage, loyalty_discount, delivery_method_id, delivery_method_name, payment_proof_url, delivery_notes, payment_method_id, payment_method_name } = req.body;
    
    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();

      const [result] = await conn.query(
        'INSERT INTO orders (order_ref, customer_id, customer_name, customer_address, customer_phone, items, total, status, date, discount_percentage, loyalty_discount, delivery_method_id, delivery_method_name, payment_proof_url, delivery_notes, payment_method_id, payment_method_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [order_ref, customer_id, customer_name, customer_address, customer_phone, JSON.stringify(items), total, status, date, discount_percentage || 0, loyalty_discount || 0, delivery_method_id || null, delivery_method_name || null, payment_proof_url || null, delivery_notes || null, payment_method_id || null, payment_method_name || null]
      );

      await conn.query(
        'UPDATE customers SET total_orders = total_orders + 1, total_spent = total_spent + ? WHERE id = ?',
        [total, customer_id]
      );

      // Decrease stock levels for each item
      const parsedItems = typeof items === 'string' ? JSON.parse(items) : items;
      if (Array.isArray(parsedItems)) {
        for (const orderItem of parsedItems) {
          const { name, size, qty } = orderItem;
          if (name && size && qty) {
            const [stockRows] = await conn.query(
              'SELECT id, sizes FROM stock WHERE name = ?',
              [name]
            );
            if (stockRows.length > 0) {
              const stockItem = stockRows[0];
              let sizesMap = {};
              try {
                sizesMap = typeof stockItem.sizes === 'string' ? JSON.parse(stockItem.sizes) : stockItem.sizes;
              } catch (_) {
                sizesMap = stockItem.sizes || {};
              }

              if (sizesMap && sizesMap[size] !== undefined) {
                sizesMap[size] = Math.max(0, sizesMap[size] - parseInt(qty));
                await conn.query(
                  'UPDATE stock SET sizes = ? WHERE id = ?',
                  [JSON.stringify(sizesMap), stockItem.id]
                );
              }
            }
          }
        }
      }

      await conn.commit();

      const [rows] = await pool.query('SELECT * FROM orders WHERE id = ?', [result.insertId]);
      res.json(rows[0]);
    } catch (err) {
      await conn.rollback();
      throw err;
    } finally {
      conn.release();
    }
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.put('/orders/:id/status', async (req, res) => {
  try {
    const now = new Date().toISOString().replace('T', ' ').substring(0, 19); // YYYY-MM-DD HH:MM:SS
    await pool.query(
      'UPDATE orders SET status = ?, date = ? WHERE id = ? OR order_ref = ?',
      [req.body.status, now, req.params.id, req.params.id]
    );
    const [rows] = await pool.query('SELECT * FROM orders WHERE id = ? OR order_ref = ?', [req.params.id, req.params.id]);
    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.put('/orders/:id', async (req, res) => {
  try {
    const { order_ref, customer_id, customer_name, customer_address, customer_phone, items, total, status, date, discount_percentage, loyalty_discount, delivery_method_id, delivery_method_name, payment_proof_url, delivery_notes, payment_method_id, payment_method_name } = req.body;
    
    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();

      // 1. Fetch old order details to restore stock
      const [oldOrderRows] = await conn.query(
        'SELECT items FROM orders WHERE id = ? OR order_ref = ?',
        [req.params.id, req.params.id]
      );

      if (oldOrderRows.length > 0) {
        const oldOrder = oldOrderRows[0];
        const oldItems = typeof oldOrder.items === 'string' ? JSON.parse(oldOrder.items) : oldOrder.items;

        // Restore stock levels from old items
        if (Array.isArray(oldItems)) {
          for (const orderItem of oldItems) {
            const { name, size, qty } = orderItem;
            if (name && size && qty) {
              const [stockRows] = await conn.query(
                'SELECT id, sizes FROM stock WHERE name = ?',
                [name]
              );
              if (stockRows.length > 0) {
                const stockItem = stockRows[0];
                let sizesMap = {};
                try {
                  sizesMap = typeof stockItem.sizes === 'string' ? JSON.parse(stockItem.sizes) : stockItem.sizes;
                } catch (_) {
                  sizesMap = stockItem.sizes || {};
                }

                if (sizesMap && sizesMap[size] !== undefined) {
                  sizesMap[size] = sizesMap[size] + parseInt(qty);
                  await conn.query(
                    'UPDATE stock SET sizes = ? WHERE id = ?',
                    [JSON.stringify(sizesMap), stockItem.id]
                  );
                }
              }
            }
          }
        }
      }

      // 2. Update the order in DB
      await conn.query(
        'UPDATE orders SET order_ref = ?, customer_id = ?, customer_name = ?, customer_address = ?, customer_phone = ?, items = ?, total = ?, status = ?, date = ?, discount_percentage = ?, loyalty_discount = ?, delivery_method_id = ?, delivery_method_name = ?, payment_proof_url = ?, delivery_notes = ?, payment_method_id = ?, payment_method_name = ? WHERE id = ? OR order_ref = ?',
        [order_ref, customer_id, customer_name, customer_address, customer_phone, JSON.stringify(items), total, status, date, discount_percentage || 0, loyalty_discount || 0, delivery_method_id || null, delivery_method_name || null, payment_proof_url || null, delivery_notes || null, payment_method_id || null, payment_method_name || null, req.params.id, req.params.id]
      );

      // 3. Deduct stock levels for new items
      const newItems = typeof items === 'string' ? JSON.parse(items) : items;
      if (Array.isArray(newItems)) {
        for (const orderItem of newItems) {
          const { name, size, qty } = orderItem;
          if (name && size && qty) {
            const [stockRows] = await conn.query(
              'SELECT id, sizes FROM stock WHERE name = ?',
              [name]
            );
            if (stockRows.length > 0) {
              const stockItem = stockRows[0];
              let sizesMap = {};
              try {
                sizesMap = typeof stockItem.sizes === 'string' ? JSON.parse(stockItem.sizes) : stockItem.sizes;
              } catch (_) {
                sizesMap = stockItem.sizes || {};
              }

              if (sizesMap && sizesMap[size] !== undefined) {
                sizesMap[size] = Math.max(0, sizesMap[size] - parseInt(qty));
                await conn.query(
                  'UPDATE stock SET sizes = ? WHERE id = ?',
                  [JSON.stringify(sizesMap), stockItem.id]
                );
              }
            }
          }
        }
      }

      await conn.commit();

      const [rows] = await pool.query('SELECT * FROM orders WHERE id = ? OR order_ref = ?', [req.params.id, req.params.id]);
      res.json(rows[0]);
    } catch (err) {
      await conn.rollback();
      throw err;
    } finally {
      conn.release();
    }
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.delete('/orders/:id', async (req, res) => {
  try {
    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();

      // 1. Fetch order details before deleting
      const [orderRows] = await conn.query(
        'SELECT items FROM orders WHERE id = ? OR order_ref = ?',
        [req.params.id, req.params.id]
      );

      if (orderRows.length > 0) {
        const order = orderRows[0];
        const parsedItems = typeof order.items === 'string' ? JSON.parse(order.items) : order.items;
        
        // 2. Restore stock levels
        if (Array.isArray(parsedItems)) {
          for (const orderItem of parsedItems) {
            const { name, size, qty } = orderItem;
            if (name && size && qty) {
              const [stockRows] = await conn.query(
                'SELECT id, sizes FROM stock WHERE name = ?',
                [name]
              );
              if (stockRows.length > 0) {
                const stockItem = stockRows[0];
                let sizesMap = {};
                try {
                  sizesMap = typeof stockItem.sizes === 'string' ? JSON.parse(stockItem.sizes) : stockItem.sizes;
                } catch (_) {
                  sizesMap = stockItem.sizes || {};
                }

                if (sizesMap && sizesMap[size] !== undefined) {
                  sizesMap[size] = sizesMap[size] + parseInt(qty);
                  await conn.query(
                    'UPDATE stock SET sizes = ? WHERE id = ?',
                    [JSON.stringify(sizesMap), stockItem.id]
                  );
                }
              }
            }
          }
        }
      }

      // 3. Delete order
      await conn.query('DELETE FROM orders WHERE id = ? OR order_ref = ?', [req.params.id, req.params.id]);

      await conn.commit();
      res.json({ success: true });
    } catch (err) {
      await conn.rollback();
      throw err;
    } finally {
      conn.release();
    }
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── EMAIL SENDING ENDPOINT ──────────────────────────────────────────────────
const nodemailer = require('nodemailer');

app.post('/orders/send-invoice-email', upload.single('pdf'), async (req, res) => {
  try {
    const { senderEmail, senderPassword, recipientEmail, orderId } = req.body;
    const file = req.file;

    if (!senderEmail || !senderPassword || !recipientEmail || !orderId || !file) {
      return res.status(400).json({ error: 'Missing required fields or PDF attachment' });
    }

    // Create transporter dynamically using Gmail SMTP
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: senderEmail,
        pass: senderPassword,
      },
    });

    const mailOptions = {
      from: `"Ceylux Clothing" <${senderEmail}>`,
      to: recipientEmail,
      subject: `Invoice for Order #${orderId} - Ceylux`,
      text: `Dear Customer,\n\nPlease find attached the PDF invoice for your order #${orderId}.\n\nThank you for shopping with Ceylux!\n\nBest regards,\nCeylux Clothing`,
      attachments: [
        {
          filename: `Ceylux_Invoice_${orderId}.pdf`,
          path: file.path,
          contentType: 'application/pdf',
        },
      ],
    };

    await transporter.sendMail(mailOptions);

    // Clean up temporary uploaded file from server
    try {
      fs.unlinkSync(file.path);
    } catch (e) {
      console.error('Failed to delete temp PDF file:', e);
    }

    res.json({ success: true, message: 'Email sent successfully!' });
  } catch (error) {
    console.error('Email sending error:', error);
    // Try cleaning up the file if it exists
    if (req.file && req.file.path) {
      try {
        fs.unlinkSync(req.file.path);
      } catch (_) {}
    }
    res.status(500).json({ error: error.message });
  }
});

app.post('/email/send', upload.single('pdf'), async (req, res) => {
  try {
    const { senderEmail, senderPassword, recipientEmail, subject, text, html } = req.body;
    const file = req.file;

    if (!senderEmail || !senderPassword || !recipientEmail || !subject) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: senderEmail,
        pass: senderPassword,
      },
    });

    const mailOptions = {
      from: `"Ceylux Clothing" <${senderEmail}>`,
      to: recipientEmail,
      subject: subject,
      text: text || '',
    };

    if (html) {
      mailOptions.html = html;
    }

    if (file) {
      mailOptions.attachments = [
        {
          filename: file.originalname || 'Ceylux_Attachment.pdf',
          path: file.path,
          contentType: file.mimetype || 'application/pdf',
        },
      ];
    }

    await transporter.sendMail(mailOptions);

    if (file) {
      try {
        fs.unlinkSync(file.path);
      } catch (e) {
        console.error('Failed to delete temp file:', e);
      }
    }

    res.json({ success: true, message: 'Email sent successfully!' });
  } catch (error) {
    console.error('Generic email sending error:', error);
    if (req.file && req.file.path) {
      try {
        fs.unlinkSync(req.file.path);
      } catch (_) {}
    }
    res.status(500).json({ error: error.message });
  }
});



// ── TIERS ──────────────────────────────────────────────────────────────────
app.get('/tiers', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM tiers ORDER BY priority DESC');
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/tiers', async (req, res) => {
  try {
    const { name, emoji, min_orders, min_spent, min_rating, discount_percentage, priority } = req.body;
    const [result] = await pool.query(
      'INSERT INTO tiers (name, emoji, min_orders, min_spent, min_rating, discount_percentage, priority) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [name, emoji, min_orders || 0, min_spent || 0, min_rating || 0, discount_percentage || 0, priority || 0]
    );
    const [rows] = await pool.query('SELECT * FROM tiers WHERE id = ?', [result.insertId]);
    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.put('/tiers/:id', async (req, res) => {
  try {
    const { name, emoji, min_orders, min_spent, min_rating, discount_percentage, priority } = req.body;
    await pool.query(
      'UPDATE tiers SET name = ?, emoji = ?, min_orders = ?, min_spent = ?, min_rating = ?, discount_percentage = ?, priority = ? WHERE id = ?',
      [name, emoji, min_orders || 0, min_spent || 0, min_rating || 0, discount_percentage || 0, priority || 0, req.params.id]
    );
    const [rows] = await pool.query('SELECT * FROM tiers WHERE id = ?', [req.params.id]);
    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.delete('/tiers/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM tiers WHERE id = ?', [req.params.id]);
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── DELIVERY METHODS ───────────────────────────────────────────────────────
app.get('/delivery-methods', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM delivery_methods WHERE is_active = TRUE ORDER BY name');
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/delivery-methods', async (req, res) => {
  try {
    const { name, description, emoji, account_details, is_active } = req.body;
    const [result] = await pool.query(
      'INSERT INTO delivery_methods (name, description, emoji, account_details, is_active) VALUES (?, ?, ?, ?, ?)',
      [name, description || '', emoji || '🚚', account_details || null, is_active !== false]
    );
    const [rows] = await pool.query('SELECT * FROM delivery_methods WHERE id = ?', [result.insertId]);
    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.put('/delivery-methods/:id', async (req, res) => {
  try {
    const { name, description, emoji, account_details, is_active } = req.body;
    await pool.query(
      'UPDATE delivery_methods SET name = ?, description = ?, emoji = ?, account_details = ?, is_active = ? WHERE id = ?',
      [name, description || '', emoji || '🚚', account_details || null, is_active !== false, req.params.id]
    );
    const [rows] = await pool.query('SELECT * FROM delivery_methods WHERE id = ?', [req.params.id]);
    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.delete('/delivery-methods/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM delivery_methods WHERE id = ?', [req.params.id]);
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── PAYMENT METHODS ────────────────────────────────────────────────────────
app.get('/payment-methods', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM payment_methods WHERE is_active = TRUE ORDER BY name');
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/payment-methods', async (req, res) => {
  try {
    const { name, description, emoji, is_active } = req.body;
    const [result] = await pool.query(
      'INSERT INTO payment_methods (name, description, emoji, is_active) VALUES (?, ?, ?, ?)',
      [name, description || '', emoji || '💳', is_active !== false]
    );
    const [rows] = await pool.query('SELECT * FROM payment_methods WHERE id = ?', [result.insertId]);
    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.put('/payment-methods/:id', async (req, res) => {
  try {
    const { name, description, emoji, is_active } = req.body;
    await pool.query(
      'UPDATE payment_methods SET name = ?, description = ?, emoji = ?, is_active = ? WHERE id = ?',
      [name, description || '', emoji || '💳', is_active !== false, req.params.id]
    );
    const [rows] = await pool.query('SELECT * FROM payment_methods WHERE id = ?', [req.params.id]);
    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.delete('/payment-methods/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM payment_methods WHERE id = ?', [req.params.id]);
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── USER PROFILES ──────────────────────────────────────────────────────────
app.get('/user/:userId', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT id, name, email, phone, profileImageUrl FROM users WHERE id = ? OR email = ?', [req.params.userId, req.params.userId]);
    if (rows.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.json(rows[0]);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.put('/user/:userId', async (req, res) => {
  try {
    const { name, email, phone, profileImageUrl } = req.body;
    
    // Check if user exists
    const [rows] = await pool.query('SELECT id FROM users WHERE id = ? OR email = ?', [req.params.userId, req.params.userId]);
    
    if (rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const userId = rows[0].id;
    
    // Update user profile
    await pool.query(
      'UPDATE users SET name = ?, email = ?, phone = ?, profileImageUrl = ? WHERE id = ?',
      [name, email, phone, profileImageUrl, userId]
    );
    
    const [updatedRows] = await pool.query('SELECT id, name, email, phone, profileImageUrl FROM users WHERE id = ?', [userId]);
    res.json({ message: 'Profile updated successfully', user: updatedRows[0] });
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