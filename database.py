import sqlite3
import random
import string

def init_db():
    conn = sqlite3.connect('store.db')
    cursor = conn.cursor()
    
    # प्रोडक्ट्स टेबल
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            price REAL NOT NULL,
            image TEXT
        )
    ''')
    
    # ऑर्डर्स टेबल (शॉप और कस्टमर दोनों के पूरे पते के साथ)
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
    
    # ऑर्डर आइटम्स टेबल
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

def generate_order_number():
    # रैंडम अल्फा-न्यूमेरिक ऑर्डर नंबर जनरेट करने के लिए
    letters = ''.join(random.choices(string.ascii_uppercase, k=3))
    digits = ''.join(random.choices(string.digits, k=5))
    return f"ORD-{letters}-{digits}"
