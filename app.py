from flask import Flask, request, redirect, session
import sqlite3
import random
import string

app = Flask(__name__)
app.secret_key = 'tarun_fresh_fruits_secret_key'

SHOP_DETAILS = {
    "name": "Tarun Fresh Fruits & Daily Needs",
    "address": "Shop No. 12, Main Market, Sector 15, Faridabad, Haryana - 121007",
    "phone": "9876543210"
}

def init_db():
    conn = sqlite3.connect('store.db')
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            price REAL NOT NULL
        )
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_number TEXT UNIQUE NOT NULL,
            customer_name TEXT,
            customer_phone TEXT,
            customer_address TEXT,
            shop_address TEXT,
            total_amount REAL NOT NULL,
            status TEXT DEFAULT 'New Order - Ready for Broadcast',
            accepted_by TEXT DEFAULT NULL
        )
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS order_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_number TEXT,
            product_name TEXT,
            quantity INTEGER,
            price REAL
        )
    ''')
    conn.commit()
    conn.close()

def seed_products():
    conn = sqlite3.connect('store.db')
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM products")
    if cursor.fetchone()[0] == 0:
        sample_products = [
            ("Fresh Apples (1kg)", 150.0),
            ("Organic Bananas (1 Dozen)", 60.0),
            ("Fresh Oranges (1kg)", 120.0),
            ("Alphonso Mangoes (1kg)", 350.0)
        ]
        cursor.executemany("INSERT INTO products (name, price) VALUES (?, ?)", sample_products)
        conn.commit()
    conn.close()

init_db()
seed_products()

def generate_order_number():
    letters = ''.join(random.choices(string.ascii_uppercase, k=3))
    digits = ''.join(random.choices(string.digits, k=5))
    return f"ORD-{letters}-{digits}"

@app.route('/')
def index():
    conn = sqlite3.connect('store.db')
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM products")
    products = cursor.fetchall()
    conn.close()
    
    cart = session.get('cart', {})
    cart_count = sum(cart.values())
    
    prod_html = ""
    for prod in products:
        prod_html += f'''
        <div class="card">
            <h3>{prod[1]}</h3>
            <p>₹{prod[2]}</p>
            <form action="/add_to_cart/{prod[0]}" method="POST">
                <button type="submit" class="btn">Add to Cart</button>
            </form>
        </div>'''
        
    return base_layout("Shop Catalog", f'''
        <div class="product-grid">{prod_html}</div>
    ''', cart_count)

@app.route('/add_to_cart/<int:product_id>', methods=['POST'])
def add_to_cart(product_id):
    if 'cart' not in session:
        session['cart'] = {}
    cart = session['cart']
    str_id = str(product_id)
    cart[str_id] = cart.get(str_id, 0) + 1
    session['cart'] = cart
    return redirect('/')

@app.route('/cart')
def view_cart():
    cart = session.get('cart', {})
    if not cart:
        return base_layout("Cart", "<p>Your cart is empty. <a href='/'>Go back to shop</a></p>", 0)
    
    conn = sqlite3.connect('store.db')
    cursor = conn.cursor()
    items_html = ""
    total = 0
    
    for prod_id, qty in cart.items():
        cursor.execute("SELECT * FROM products WHERE id = ?", (prod_id,))
        prod = cursor.fetchone()
        if prod:
            subtotal = prod[2] * qty
            total += subtotal
            items_html += f"<tr><td>{prod[1]}</td><td>{qty}</td><td>₹{subtotal}</td></tr>"
            
    conn.close()
    
    content = f'''
        <div style="max-width: 600px; margin: auto; background: white; padding: 30px; border-radius: 10px;">
            <h2>🛒 Your Shopping Cart</h2>
            <table>
                <tr><th>Item Name</th><th>Qty</th><th>Subtotal</th></tr>
                {items_html}
            </table>
            <h3>Total Amount: ₹{total}</h3>
            <h3 style="margin-top: 20px;">Enter Complete Delivery Details</h3>
            <form action="/checkout" method="POST">
                <input type="text" name="name" placeholder="Full Name" required>
                <input type="text" name="phone" placeholder="Phone Number" required>
                <input type="text" name="address" placeholder="Full Delivery Address" required>
                <button type="submit" class="btn" style="margin-top: 15px;">Confirm & Send Order via WhatsApp 📱</button>
            </form>
        </div>
    '''
    return base_layout("Cart", content, sum(cart.values()))

@app.route('/checkout', methods=['POST'])
def checkout():
    name = request.form.get('name')
    phone = request.form.get('phone')
    address = request.form.get('address')
    cart = session.get('cart', {})
    if not cart:
        return redirect('/')
    
    conn = sqlite3.connect('store.db')
    cursor = conn.cursor()
    order_number = generate_order_number()
    total_amount = 0
    order_items_data = []
    
    for prod_id, qty in cart.items():
        cursor.execute("SELECT name, price FROM products WHERE id = ?", (prod_id,))
        prod = cursor.fetchone()
        if prod:
            subtotal = prod[1] * qty
            total_amount += subtotal
            order_items_data.append((order_number, prod[0], qty, prod[1]))
            
    cursor.execute('''
        INSERT INTO orders (order_number, customer_name, customer_phone, customer_address, shop_address, total_amount, status)
        VALUES (?, ?, ?, ?, ?, ?, 'New Order - Ready for Broadcast')
    ''', (order_number, name, phone, address, SHOP_DETAILS['address'], total_amount))
    
    cursor.executemany('''
        INSERT INTO order_items (order_number, product_name, quantity, price)
        VALUES (?, ?, ?, ?)
    ''', order_items_data)
    
    conn.commit()
    conn.close()
    
    whatsapp_text = f"*🛒 New Order Received!*\n\n🔢 *Order No:* {order_number}\n👤 *Customer Name:* {name}\n📞 *Phone:* {phone}\n\n📍 *Pickup Address (Shop):*\n{SHOP_DETAILS['address']}\n\n🏠 *Delivery Address (Customer):*\n{address}\n\n*📦 Items:*\n"
    for item in order_items_data:
        whatsapp_text += f"- {item[1]} x {item[2]} (₹{item[3] * item[2]})\n"
    whatsapp_text += f"\n💰 *Total Amount:* ₹{total_amount}"
    
    session.pop('cart', None)
    
    content = f'''
        <div style="text-align: center; max-width: 500px; margin: auto; background: white; padding: 40px; border-radius: 10px;">
            <h2 style="color: #27ae60;">Order Placed Successfully! 🎉</h2>
            <p>Your Order Number is: <strong>{order_number}</strong></p>
            <a id="waLink" class="wa-btn" href="#" target="_blank">Send Order to WhatsApp 📱</a>
            <br><br><a href="/">← Back to Shop</a>
        </div>
        <script>
            const text = `{whatsapp_text}`;
            document.getElementById('waLink').href = `https://wa.me/91{SHOP_DETAILS['phone']}?text=` + encodeURIComponent(text);
        </script>
    '''
    return base_layout("Success", content, 0)

@app.route('/shop-panel')
def shop_panel():
    conn = sqlite3.connect('store.db')
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM orders ORDER BY id DESC")
    orders = cursor.fetchall()
    conn.close()
    
    rows = ""
    for order in orders:
        broadcast_btn = f'''
            <form action="/broadcast-order/{order[1]}" method="POST">
                <button type="submit" class="btn" style="background:#f39c12; font-size:12px; padding:6px; width:auto;">📢 Broadcast</button>
            </form>''' if 'New Order' in order[7] else ""
            
        rows += f'''
        <tr>
            <td><strong>{order[1]}</strong></td>
            <td>{order[2]}<br><small>📞 {order[3]}</small></td>
            <td>
                <div class="address-box"><strong>📍 Pickup:</strong><br>{order[5]}</div>
                <div class="address-box" style="border-left-color: #27ae60;"><strong>🏠 Drop:</strong><br>{order[4]}</div>
            </td>
            <td><strong>₹{order[6]}</strong></td>
            <td>
                <span style="font-size:12px; background: #eef2f3; padding: 4px; border-radius: 4px;">{order[7]}</span><br><br>
                {broadcast_btn}
            </td>
        </tr>'''
        
    content = f'''
        <h2>🏪 Shop Owner Dashboard</h2>
        <table>
            <tr><th>Order No</th><th>Customer</th><th>Addresses</th><th>Total</th><th>Action</th></tr>
            {rows}
        </table>
    '''
    return base_layout("Shop Panel", content, 0)

@app.route('/broadcast-order/<order_number>', methods=['POST'])
def broadcast_order(order_number):
    conn = sqlite3.connect('store.db')
    cursor = conn.cursor()
    cursor.execute("UPDATE orders SET status = 'Broadcasted (Looking for Delivery Boy)' WHERE order_number = ?", (order_number,))
    conn.commit()
    conn.close()
    return redirect('/shop-panel')

@app.route('/delivery-panel')
def delivery_panel():
    conn = sqlite3.connect('store.db')
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM orders WHERE status LIKE 'Broadcasted%' OR status LIKE 'Picked%' OR status LIKE 'Out%' ORDER BY id DESC")
    orders = cursor.fetchall()
    conn.close()
    
    rows = ""
    for order in orders:
        action_html = ""
        if 'Broadcasted' in order[7]:
            action_html = f'''
            <form action="/accept-order/{order[1]}" method="POST">
                <input type="text" name="boy_name" placeholder="Your Name" required style="margin:0 0 5px 0; font-size:12px; padding:6px;">
                <button type="submit" class="btn" style="font-size:12px; padding:6px;">Accept ⚡</button>
            </form>'''
        elif 'Picked Up' in order[7] or 'Out' in order[7]:
            action_html = f'''
            <form action="/update-status/{order[1]}" method="POST">
                <select name="status" style="margin:0 0 5px 0; font-size:12px; padding:6px;">
                    <option value="Out for Delivery 🚀">Out for Delivery 🚀</option>
                    <option value="Delivered ✅">Delivered ✅</option>
                </select>
                <button type="submit" class="btn" style="background: #2980b9; font-size:12px; padding:6px;">Update</button>
            </form>'''
        else:
            action_html = "<span>Completed ✅</span>"
            
        rows += f'''
        <tr>
            <td><strong>{order[1]}</strong></td>
            <td>
                <div class="address-box"><strong>🚩 Pickup:</strong><br>{order[5]}</div>
                <div class="address-box" style="border-left-color: #27ae60;"><strong>🎯 Deliver:</strong><br>{order[4]}<br><small>👤 {order[2]} | 📞 {order[3]}</small></div>
            </td>
            <td><strong>₹{order[6]}</strong></td>
            <td>{order[7]}</td>
            <td>{action_html}</td>
        </tr>'''
        
    content = f'''
        <h2>🚚 Delivery Boy Panel (First-Come, First-Served)</h2>
        <table>
            <tr><th>Order No</th><th>Route Details</th><th>Total</th><th>Status</th><th>Action</th></tr>
            {rows}
        </table>
    '''
    return base_layout("Delivery Panel", content, 0)

@app.route('/accept-order/<order_number>', methods=['POST'])
def accept_order(order_number):
    delivery_boy_name = request.form.get('boy_name', 'Delivery Partner')
    conn = sqlite3.connect('store.db')
    cursor = conn.cursor()
    cursor.execute("SELECT accepted_by FROM orders WHERE order_number = ?", (order_number,))
    row = cursor.fetchone()
    if row and not row[0]:
        cursor.execute("UPDATE orders SET accepted_by = ?, status = ? WHERE order_number = ?", (delivery_boy_name, f"Picked Up by {delivery_boy_name}", order_number))
        conn.commit()
    conn.close()
    return redirect('/delivery-panel')

@app.route('/update-status/<order_number>', methods=['POST'])
def update_status(order_number):
    new_status = request.form.get('status')
    conn = sqlite3.connect('store.db')
    cursor = conn.cursor()
    cursor.execute("UPDATE orders SET status = ? WHERE order_number = ?", (new_status, order_number))
    conn.commit()
    conn.close()
    return redirect('/delivery-panel')

def base_layout(title, content, cart_count):
    return f'''<!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>{title} - Tarun Fresh Fruits</title>
        <style>
            body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background: #f4f7f6; color: #333; }}
            .header {{ display: flex; justify-content: space-between; align-items: center; background: #ffffff; padding: 15px 30px; box-shadow: 0 2px 8px rgba(0,0,0,0.05); }}
            .header h2 {{ margin: 0; color: #2c3e50; font-size: 20px; }}
            .nav-links a {{ margin-right: 15px; text-decoration: none; color: #7f8c8d; font-weight: 600; font-size: 14px; }}
            .nav-links a:hover {{ color: #2980b9; }}
            .cart-link {{ background: #2980b9; color: white; padding: 8px 15px; text-decoration: none; border-radius: 6px; font-weight: bold; font-size: 14px; }}
            .container {{ max-width: 1100px; margin: 30px auto; padding: 0 20px; }}
            .product-grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 20px; }}
            .card {{ background: #ffffff; padding: 20px; border-radius: 10px; text-align: center; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }}
            .card h3 {{ margin-bottom: 10px; color: #34495e; }}
            .card p {{ font-size: 18px; color: #27ae60; font-weight: bold; margin-bottom: 15px; }}
            .btn {{ background: #27ae60; color: white; border: none; padding: 10px 15px; cursor: pointer; border-radius: 6px; font-weight: bold; width: 100%; font-size: 14px; }}
            .btn:hover {{ background: #219653; }}
            input, select {{ width: 100%; padding: 10px; margin: 8px 0; box-sizing: border-box; border: 1px solid #ccc; border-radius: 5px; font-size: 14px; }}
            table {{ width: 100%; border-collapse: collapse; margin-top: 15px; background: white; }}
            th, td {{ border: 1px solid #e0e0e0; padding: 12px; text-align: left; font-size: 14px; }}
            th {{ background: #f8f9fa; color: #333; }}
            .wa-btn {{ background: #25D366; color: white; padding: 14px 25px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block; margin-top: 20px; }}
            .address-box {{ background: #f9f9f9; padding: 8px; border-left: 3px solid #3498db; margin: 6px 0; font-size: 13px; border-radius: 4px; }}
        </style>
    </head>
    <body>
        <div class="header">
            <div>
                <h2>🍎 Tarun Fresh Fruits</h2>
                <div class="nav-links" style="margin-top: 5px;">
                    <a href="/">🛍️ Shop Catalog</a>
                    <a href="/shop-panel">🏪 Shop Panel</a>
                    <a href="/delivery-panel">🚚 Delivery Panel</a>
                </div>
            </div>
            <a href="/cart" class="cart-link">🛒 Cart ({cart_count})</a>
        </div>
        <div class="container">
            {content}
        </div>
    </body>
    </html>'''

if __name__ == '__main__':
    app.run(debug=True)
