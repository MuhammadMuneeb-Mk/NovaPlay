require('dotenv').config();
const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const jwt = require('jsonwebtoken');

const app = express();
app.use(cors());
app.use(express.json());

const pool = mysql.createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});
const promisePool = pool.promise();

const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
    console.error('JWT_SECRET is not set. Add it to backend/.env before starting the server.');
    process.exit(1);
}

// Middleware to verify JWT token
const verifyToken = (req, res, next) => {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
        return res.status(401).json({ success: false, message: 'No token provided' });
    }
    const token = authHeader.split(' ')[1];
    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        req.user = decoded;
        next();
    } catch (err) {
        return res.status(401).json({ success: false, message: 'Invalid token' });
    }
};

// ---------- GAMES CRUD ----------
app.get('/api/games', async (req, res) => {
    try {
        const [rows] = await promisePool.query('SELECT * FROM games');
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/games/:id', async (req, res) => {
    const { id } = req.params;
    try {
        const [rows] = await promisePool.query('SELECT * FROM games WHERE id = ?', [id]);
        if (rows.length === 0) return res.status(404).json({ message: 'Game not found' });
        res.json(rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/games', verifyToken, async (req, res) => {
    const { title, image, description, price } = req.body;
    if (!title || !image || !description || price === undefined) {
        return res.status(400).json({ message: 'Missing required fields' });
    }
    try {
        const [result] = await promisePool.query(
            'INSERT INTO games (title, image, description, price) VALUES (?, ?, ?, ?)',
            [title, image, description, price]
        );
        const newGame = { id: result.insertId, title, image, description, price };
        res.status(201).json({ success: true, data: newGame });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.put('/api/games/:id', verifyToken, async (req, res) => {
    const { id } = req.params;
    const { title, image, description, price } = req.body;
    try {
        const [result] = await promisePool.query(
            'UPDATE games SET title = ?, image = ?, description = ?, price = ? WHERE id = ?',
            [title, image, description, price, id]
        );
        if (result.affectedRows === 0) return res.status(404).json({ message: 'Game not found' });
        res.json({ success: true, data: { id, title, image, description, price } });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.delete('/api/games/:id', verifyToken, async (req, res) => {
    const { id } = req.params;
    try {
        const [result] = await promisePool.query('DELETE FROM games WHERE id = ?', [id]);
        if (result.affectedRows === 0) return res.status(404).json({ message: 'Game not found' });
        res.status(204).send();
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ---------- USERS CRUD ----------
app.get('/api/users', async (req, res) => {
    try {
        const [rows] = await promisePool.query('SELECT id, username, email, display_name FROM users');
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/users/:id', async (req, res) => {
    const { id } = req.params;
    try {
        const [rows] = await promisePool.query('SELECT id, username, email, display_name FROM users WHERE id = ?', [id]);
        if (rows.length === 0) return res.status(404).json({ message: 'User not found' });
        res.json(rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/users', async (req, res) => {
    const { username, email, password, display_name } = req.body;
    if (!username || !email || !password) {
        return res.status(400).json({ message: 'Username, email and password required' });
    }
    try {
        const [result] = await promisePool.query(
            'INSERT INTO users (username, email, password, display_name) VALUES (?, ?, ?, ?)',
            [username, email, password, display_name || username]
        );
        const newUser = { id: result.insertId, username, email, display_name: display_name || username };
        res.status(201).json(newUser);
    } catch (err) {
        if (err.code === 'ER_DUP_ENTRY') {
            res.status(409).json({ message: 'Username or email already exists' });
        } else {
            res.status(500).json({ error: err.message });
        }
    }
});

// Change password (separate endpoint)
app.post('/api/users/:id/change-password', verifyToken, async (req, res) => {
    const { id } = req.params;
    const { currentPassword, newPassword } = req.body;
    if (!currentPassword || !newPassword) {
        return res.status(400).json({ success: false, message: 'Current and new password required' });
    }
    if (newPassword.length < 4) {
        return res.status(400).json({ success: false, message: 'New password must be at least 4 characters' });
    }
    try {
        // Verify current password
        const [userRows] = await promisePool.query('SELECT password FROM users WHERE id = ?', [id]);
        if (userRows.length === 0) return res.status(404).json({ success: false, message: 'User not found' });
        if (userRows[0].password !== currentPassword) {
            return res.status(401).json({ success: false, message: 'Current password is incorrect' });
        }
        // Update password
        await promisePool.query('UPDATE users SET password = ? WHERE id = ?', [newPassword, id]);
        res.json({ success: true, message: 'Password changed successfully' });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

app.put('/api/users/:id', verifyToken, async (req, res) => {
    const { id } = req.params;
    const { username, email, display_name, currentPassword } = req.body;

    // Current password is required
    if (!currentPassword) {
        return res.status(400).json({ success: false, message: 'Current password required' });
    }

    try {
        // Verify current password
        const [userRows] = await promisePool.query('SELECT password FROM users WHERE id = ?', [id]);
        if (userRows.length === 0) return res.status(404).json({ success: false, message: 'User not found' });
        if (userRows[0].password !== currentPassword) {
            return res.status(401).json({ success: false, message: 'Current password is incorrect' });
        }

        // Build dynamic update query for profile fields (username, email, display_name)
        const updates = [];
        const values = [];
        if (username !== undefined) {
            updates.push('username = ?');
            values.push(username);
        }
        if (email !== undefined) {
            updates.push('email = ?');
            values.push(email);
        }
        if (display_name !== undefined) {
            updates.push('display_name = ?');
            values.push(display_name);
        }

        if (updates.length === 0) {
            return res.status(400).json({ success: false, message: 'No fields to update' });
        }

        values.push(id);
        const query = `UPDATE users SET ${updates.join(', ')} WHERE id = ?`;
        await promisePool.query(query, values);

        // Fetch updated user
        const [rows] = await promisePool.query('SELECT id, username, email, display_name FROM users WHERE id = ?', [id]);
        res.json({ success: true, data: rows[0] });
    } catch (err) {
        if (err.code === 'ER_DUP_ENTRY') {
            if (err.message.includes('username')) {
                return res.status(409).json({ success: false, message: 'Username already taken' });
            } else if (err.message.includes('email')) {
                return res.status(409).json({ success: false, message: 'Email already registered' });
            }
        }
        res.status(500).json({ success: false, error: err.message });
    }
});

app.delete('/api/users/:id', verifyToken, async (req, res) => {
    const { id } = req.params;
    try {
        const [result] = await promisePool.query('DELETE FROM users WHERE id = ?', [id]);
        if (result.affectedRows === 0) return res.status(404).json({ message: 'User not found' });
        res.status(204).send();
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ---------- LOGIN ----------
app.post('/api/users/login', async (req, res) => {
    const { username, password } = req.body;
    if (!username || !password) {
        return res.status(400).json({ success: false, message: 'Username and password required' });
    }
    try {
        const [rows] = await promisePool.query(
            'SELECT id, username, email, display_name FROM users WHERE username = ? AND password = ?',
            [username, password]
        );
        if (rows.length === 0) {
            return res.status(401).json({ success: false, message: 'Invalid credentials' });
        }
        const user = rows[0];
        const token = jwt.sign(
            { id: user.id, username: user.username },
            JWT_SECRET,
            { expiresIn: '7d' }
        );
        res.json({ success: true, token, user });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

// ---------- GET CURRENT USER (working endpoint) ----------
app.get('/api/current-users', verifyToken, async (req, res) => {
    try {
        const username = req.user.username;
        const [rows] = await promisePool.query(
            'SELECT id, username, email, display_name FROM users WHERE username = ?',
            [username]
        );
        if (rows.length === 0) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }
        res.json({ success: true, user: rows[0] });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});


// ---------- PURCHASES ----------
// Record a purchase (protected)
app.post('/api/purchases', verifyToken, async (req, res) => {
    const { game_id } = req.body;
    if (!game_id) {
        return res.status(400).json({ success: false, message: 'game_id required' });
    }
    const userId = req.user.id;
    try {

        const [existing] = await promisePool.query(
            'SELECT * FROM purchases WHERE user_id = ? AND game_id = ?',
            [userId, game_id]
        );
        if (existing.length > 0) {
            return res.status(409).json({ success: false, message: 'Game already purchased' });
        }
        const [result] = await promisePool.query(
            'INSERT INTO purchases (user_id, game_id) VALUES (?, ?)',
            [userId, game_id]
        );
        res.status(201).json({ success: true, purchase_id: result.insertId });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

// Get owned games for current user (protected)
app.get('/api/users/me/games', verifyToken, async (req, res) => {
    const userId = req.user.id;
    try {
        const [rows] = await promisePool.query(
            `SELECT g.* FROM games g
             JOIN purchases p ON g.id = p.game_id
             WHERE p.user_id = ?`,
            [userId]
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ---------- CATCH-ALL ROUTE (for undefined endpoints) ----------
app.use((req, res) => {
    res.status(404).json({ message: 'Route not found' });
});

// ---------- START SERVER ----------
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`✅ Server running on http://localhost:${PORT}`);
});