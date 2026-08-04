from flask import Flask, render_template, request, redirect, url_for, session
import sqlite3
from database import init_db, generate_order_number

app = Flask(__name__)
app.secret_key = 'tarun_secret_key_secure_system'

# दुकान का फिक्स पूरा पता (फरिदाबाद वाला)
SHOP_DETAILS = {
    "name": "Tarun Fresh Fruits & Daily Needs",
    "address": "Shop No. 12, Main Market, Sector 15, Faridabad, Haryana - 121007",
    "phone": "9876543210"
}

init_db()

def seed_products():
    conn = sqlite3.connect('store.db')
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM products")
    if cursor.fetchone()[0] == 0:
        sample_products = [
            ("Fresh Apples (1kg)", 150.0, "apple.jpg"),
            ("Organic Bananas (1 Dozen)", 60.0, "banana.jpg"),
            ("Fresh Oranges (1kg)", 120.0, "orange.jpg"),
            ("Alphonso Mangoes (1kg)", 350.0, "mango.jpg")
        ]
        cursor.executemany("INSERT INTO products (name, price, image) VALUES (?, ?, ?)", sample_products)
        conn.commit()
    conn.close()

seed_products()

@app.route('/')
def index():
    conn = sqlite3.connect('store.db')
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM products")
    products = cursor.fetchall()
    conn.close()
    
    cart = session.get('cart', {})
    cart_count = sum(cart.values())
    return render_template('index.html', products=products, cart_count=cart_count)

@app.route('/add_to_cart/<int:product_id>', methods=['POST'])
def add_to_cart(product_id):
    if 'cart' not in session:
        session['cart'] = {}
    cart = session['cart']
    str_id = str(product_id)
    cart[str_id] = cart.get(str_id, 0) + 1
    session['cart'] = cart
    return redirect(url_for('index'))

@app.route('/cart')
def view_cart():
    if 'cart' not in session or not session['cart']:
        return render_template('cart.html', items=[], total=0)
    
    conn = sqlite3.connect('store.db')
    cursor = conn.cursor()
    cart = session['cart']
    items = []
    total = 0
    
    for prod_id, qty in cart.items():
        cursor.execute("SELECT * FROM products WHERE id = ?", (prod_id,))
        prod = cursor.fetchone()
        if prod:
            subtotal = prod[2] * qty
            total += subtotal
            items.append({
                'id': prod[0],
                'name': prod[1],
                'price': prod[2],
                'quantity': qty,
                'subtotal': subtotal
            })
    conn.close()
    return render_template('cart.html', items=items, total=total)

@app.route('/checkout', methods=['POST'])
def checkout():
    name = request.form.get('name')
    phone = request.form.get('phone')
    address = request.form.get('address')
    
    cart = session.get('cart', {})
    if not cart:
        return redirect(url_for('index'))
    
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
            
    # आर्डर सेव करें (शॉप और कस्टमर दोनों के पते के साथ)
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
    
    # व्हाट्सएप समरी टेक्स्ट (पिकअप और ड्रॉप एड्रेस सहित)
    whatsapp_text = f"*🛒 New Order Received!*\n\n" \
                    f"🔢 *Order No:* {order_number}\n" \
                    f"👤 *Customer Name:* {name}\n" \
                    f"📞 *Phone:* {phone}\n\n" \
                    f"📍 *Pickup Address (Shop):*\n{SHOP_DETAILS['address']}\n\n" \
                    f"🏠 *Delivery Address (Customer):*\n{address}\n\n" \
                    f"*📦 Items:*\n"
    for item in order_items_data:
        whatsapp_text += f"- {item[1]} x {item[2]} (₹{item[3] * item[2]})\n"
    whatsapp_text += f"\n💰 *Total Amount:* ₹{total_amount}"
    
    session.pop('cart', None)
    return render_template('success.html', order_number=order_number, whatsapp_text=whatsapp_text, shop_phone=SHOP_DETAILS['phone'])

@app.route('/shop-panel')
def shop_panel():
    conn = sqlite3.connect('store.db')
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM orders ORDER BY id DESC")
    orders = cursor.fetchall()
    conn.close()
    return render_template('shop_panel.html', orders=orders)

@app.route('/broadcast-order/<order_number>', methods=['POST'])
def broadcast_order(order_number):
    conn = sqlite3.connect('store.db')
    cursor = conn.cursor()
    cursor.execute("UPDATE orders SET status = 'Broadcasted (Looking for Delivery Boy)' WHERE order_number = ?", (order_number,))
    conn.commit()
    conn.close()
    return redirect(url_for('shop_panel'))

@app.route('/delivery-panel')
def delivery_panel():
    conn = sqlite3.connect('store.db')
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM orders WHERE status LIKE 'Broadcasted%' OR status LIKE 'Picked%' OR status LIKE 'Out%' ORDER BY id DESC")
    orders = cursor.fetchall()
    conn.close()
    return render_template('delivery_panel.html', orders=orders)

@app.route('/accept-order/<order_number>', methods=['POST'])
def accept_order(order_number):
    delivery_boy_name = request.form.get('boy_name', 'Delivery Partner')
    conn = sqlite3.connect('store.db')
    cursor = conn.cursor()
    cursor.execute("SELECT accepted_by FROM orders WHERE order_number = ?", (order_number,))
    row = cursor.fetchone()
    if row and not row[0]:
        cursor.execute("UPDATE orders SET accepted_by = ?, status = 'Picked Up by " + delivery_boy_name + "' WHERE order_number = ?", (delivery_boy_name, order_number))
        conn.commit()
    conn.close()
    return redirect(url_for('delivery_panel'))

@app.route('/update-status/<order_number>', methods=['POST'])
def update_status(order_number):
    new_status = request.form.get('status')
    conn = sqlite3.connect('store.db')
    cursor = conn.cursor()
    cursor.execute("UPDATE orders SET status = ? WHERE order_number = ?", (new_status, order_number))
    conn.commit()
    conn.close()
    return redirect(url_for('delivery_panel'))

if __name__ == '__main__':
    app.run(debug=True)
