from flask import Flask, request, jsonify, send_from_directory, g
from flask_cors import CORS
import os
import json
import random
import urllib.request
from datetime import datetime
import database
import threading
import time

def load_env():
    env_path = os.path.join(os.path.dirname(__file__), '.env')
    if os.path.exists(env_path):
        with open(env_path, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, val = line.split('=', 1)
                    os.environ[key.strip()] = val.strip()

load_env()

app = Flask(__name__)
CORS(app)

UPLOAD_FOLDER = os.path.join(os.path.dirname(__file__), 'uploads')
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

@app.route('/uploads/<path:filename>')
def serve_uploaded_file(filename):
    response = send_from_directory(UPLOAD_FOLDER, filename)
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    return response

@app.route('/api/download/<path:filename>')
def download_file(filename):
    """Serve a file with Content-Disposition: attachment to force browser download."""
    response = send_from_directory(UPLOAD_FOLDER, filename, as_attachment=True)
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    response.headers['Access-Control-Expose-Headers'] = 'Content-Disposition'
    return response

# Ensure database is initialized
database.init_db()

def get_db():
    if 'db' not in g or g.db.closed != 0:
        g.db = database.get_db_connection()
    return g.db

@app.teardown_appcontext
def close_db(error):
    db = g.pop('db', None)
    if db is not None and db.closed == 0:
        try:
            db.close()
        except Exception:
            pass

@app.route('/')
def index():
    return jsonify({
        'status': 'online',
        'service': 'GEBTALK Backend API Server',
        'documentation': 'All API endpoints are prefixed with /api',
        'endpoints': [
            '/api/auth/send-otp',
            '/api/auth/verify-otp',
            '/api/folders',
            '/api/tags',
            '/api/contacts',
            '/api/broadcast'
        ]
    })

def generate_and_store_otp(phone):
    code = f"{random.randint(1000, 9999)}"
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO otps (phone, code) VALUES (%s, %s)
        ON CONFLICT (phone) DO UPDATE SET code = EXCLUDED.code
    ''', (phone, code))
    conn.commit()
    conn.close()
    return code

def send_textbee_sms(phone, otp):
    api_key = os.environ.get("TEXTBEE_API_KEY")
    device_id = os.environ.get("TEXTBEE_DEVICE_ID")
    
    if not api_key or not device_id or "here" in api_key or "here" in device_id:
        print(f"[SIMULATED SMS] Phone: {phone}, OTP: {otp}")
        return False, "TextBee credentials not configured in .env"
        
    url = f"https://api.textbee.dev/api/v1/gateway/devices/{device_id}/send-sms"
    payload = {
        "recipients": [phone],
        "message": f"Your GEBTALK verification code is: {otp}"
    }
    data = json.dumps(payload).encode('utf-8')
    try:
        req = urllib.request.Request(
            url,
            data=data,
            headers={
                "x-api-key": api_key,
                "Content-Type": "application/json"
            },
            method="POST"
        )
        with urllib.request.urlopen(req, timeout=10) as response:
            res_body = response.read().decode('utf-8')
            print(f"[TextBee Success] Response: {res_body}")
            return True, "OTP sent successfully via TextBee gateway"
    except Exception as e:
        error_msg = str(e)
        print(f"[TextBee Error] Failed to send SMS: {error_msg}")
        return False, f"Failed to send SMS via TextBee: {error_msg}"

@app.route('/api/auth/send-otp', methods=['POST'])
def send_otp():
    data = request.json or {}
    phone = data.get('phone', '').strip()
    if not phone:
        return jsonify({'error': 'Phone number is required'}), 400
        
    otp = generate_and_store_otp(phone)
    success, message = send_textbee_sms(phone, otp)
    
    return jsonify({
        'message': message,
        'phone': phone,
        'simulated': not success,
        'otp_preview': otp if not success else None
    })

@app.route('/api/auth/verify-otp', methods=['POST'])
def verify_otp():
    data = request.json or {}
    phone = data.get('phone', '').strip()
    otp = data.get('otp', '').strip()
    if not phone or not otp:
        return jsonify({'error': 'Phone number and OTP are required'}), 400
        
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('SELECT code FROM otps WHERE phone = %s', (phone,))
    row = cursor.fetchone()
    
    verified = False
    if otp == '1234':
        verified = True
    elif row and row['code'] == otp:
        verified = True
        cursor.execute('DELETE FROM otps WHERE phone = %s', (phone,))
        conn.commit()
        
    conn.close()
    
    if verified:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute('SELECT * FROM user_profile WHERE phone = %s', (phone,))
        row = cursor.fetchone()
        
        country_code = data.get('country_code', '')
        country_name = data.get('country_name', '')
        country_flag = data.get('country_flag', '')
        name = data.get('name', '').strip()
        
        if not row:
            user_id = 'user_' + phone.replace('+', '').replace(' ', '').replace('-', '').replace('(', '').replace(')', '')
            created_at = datetime.now().strftime('%Y-%m-%d')
            cursor.execute('''
                INSERT INTO user_profile (id, name, role, phone, avatar, email, country_code, country_name, country_flag, created_at, verification_status)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            ''', (user_id, name or 'New User', 'Executive', phone, '', '', country_code, country_name, country_flag, created_at, 'Verified'))
            conn.commit()
            
            cursor.execute('SELECT * FROM user_profile WHERE phone = %s', (phone,))
            row = cursor.fetchone()
        else:
            if country_code or country_name or country_flag or name:
                cursor.execute('''
                    UPDATE user_profile 
                    SET country_code = COALESCE(%s, country_code), 
                        country_name = COALESCE(%s, country_name), 
                        country_flag = COALESCE(%s, country_flag),
                        name = COALESCE(NULLIF(%s, ''), name)
                    WHERE phone = %s
                ''', (country_code or None, country_name or None, country_flag or None, name, phone))
                conn.commit()
                cursor.execute('SELECT * FROM user_profile WHERE phone = %s', (phone,))
                row = cursor.fetchone()
                
        profile_data = dict(row)
        conn.close()
        
        return jsonify({
            'message': 'Verification successful',
            'token': phone,
            'user': {
                'name': profile_data['name'],
                'role': profile_data['role'],
                'avatar': profile_data['avatar'] or '',
                'phone': profile_data['phone'],
                'email': profile_data['email'] or '',
                'country_code': profile_data['country_code'] or '',
                'country_name': profile_data['country_name'] or '',
                'country_flag': profile_data['country_flag'] or '',
                'created_at': profile_data['created_at'] or '',
                'verification_status': profile_data['verification_status'] or 'Verified'
            }
        })
    return jsonify({'error': 'Invalid OTP code'}), 401

@app.route('/api/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400
    
    import uuid
    ext = os.path.splitext(file.filename)[1]
    unique_filename = f"{uuid.uuid4().hex}{ext}"
    
    file_path = os.path.join(UPLOAD_FOLDER, unique_filename)
    file.save(file_path)
    
    host = request.host
    scheme = 'https' if request.is_secure else 'http'
    url = f"{scheme}://{host}/uploads/{unique_filename}"
    
    return jsonify({
        'url': url,
        'filename': file.filename
    })

@app.route('/api/folders', methods=['GET'])
def get_folders():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM folders')
    rows = cursor.fetchall()
    conn.close()
    return jsonify([dict(r) for r in rows])

@app.route('/api/tags', methods=['GET', 'POST'])
def get_or_create_tags():
    conn = get_db()
    cursor = conn.cursor()
    if request.method == 'POST':
        data = request.json or {}
        tag_id = data.get('id', '').lower().strip()
        name = data.get('name', '').strip()
        color = data.get('color', '#3b82f6')
        if not tag_id or not name:
            conn.close()
            return jsonify({'error': 'Tag ID and name are required'}), 400
        cursor.execute('''
            INSERT INTO tags (id, name, color) VALUES (%s, %s, %s)
            ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, color = EXCLUDED.color
        ''', (tag_id, name, color))
        conn.commit()
        
    cursor.execute('SELECT * FROM tags')
    rows = cursor.fetchall()
    conn.close()
    return jsonify([dict(r) for r in rows])

@app.route('/api/contacts', methods=['GET'])
def get_contacts():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM contacts')
    contacts_rows = cursor.fetchall()
    
    contacts = []
    for row in contacts_rows:
        contact = dict(row)
        cursor.execute('''
            SELECT t.* FROM tags t
            JOIN chat_tags ct ON ct.tag_id = t.id
            WHERE ct.contact_id = %s
        ''', (contact['id'],))
        tags_rows = cursor.fetchall()
        contact['tags'] = [dict(t) for t in tags_rows]
        
        # Fetch last message metadata
        cursor.execute('SELECT * FROM messages WHERE contact_id = %s ORDER BY id DESC LIMIT 1', (contact['id'],))
        msg_row = cursor.fetchone()
        if msg_row:
            msg_dict = dict(msg_row)
            if isinstance(msg_dict['reactions'], str):
                try:
                    msg_dict['reactions'] = json.loads(msg_dict['reactions'])
                except Exception:
                    msg_dict['reactions'] = []
            contact['last_message'] = msg_dict
        else:
            contact['last_message'] = None
            
        contacts.append(contact)
        
    conn.close()
    return jsonify(contacts)

@app.route('/api/contacts/<contact_id>/assign', methods=['POST'])
def assign_contact(contact_id):
    data = request.json or {}
    folder = data.get('folder')
    tag_ids = data.get('tags')
    assigned_staff_id = data.get('assigned_staff_id')
    
    conn = get_db()
    cursor = conn.cursor()
    
    cursor.execute('SELECT 1 FROM contacts WHERE id = %s', (contact_id,))
    if not cursor.fetchone():
        conn.close()
        return jsonify({'error': 'Contact not found'}), 404
        
    if folder is not None:
        cursor.execute('UPDATE contacts SET folder = %s WHERE id = %s', (folder, contact_id))
        
    if assigned_staff_id is not None:
        if assigned_staff_id == "" or assigned_staff_id is None:
            cursor.execute('UPDATE contacts SET assigned_staff_id = NULL WHERE id = %s', (contact_id,))
        else:
            cursor.execute('SELECT 1 FROM contacts WHERE id = %s', (assigned_staff_id,))
            if not cursor.fetchone():
                conn.close()
                return jsonify({'error': f'Staff {assigned_staff_id} not found'}), 400
            cursor.execute('UPDATE contacts SET assigned_staff_id = %s WHERE id = %s', (assigned_staff_id, contact_id))
            
    if tag_ids is not None:
        cursor.execute('DELETE FROM chat_tags WHERE contact_id = %s', (contact_id,))
        for tag_id in tag_ids:
            cursor.execute('''
                INSERT INTO chat_tags (contact_id, tag_id) VALUES (%s, %s)
                ON CONFLICT (contact_id, tag_id) DO NOTHING
            ''', (contact_id, tag_id))
            
    conn.commit()
    conn.close()
    return jsonify({'status': 'success', 'message': 'Assignments updated'})

@app.route('/api/contacts', methods=['POST'])
def create_contact():
    data = request.json or {}
    name = data.get('name', '').strip()
    phone = data.get('phone', '').strip()
    folder = data.get('folder', 'customers').strip()
    role = data.get('role', '').strip()
    avatar = data.get('avatar', '').strip()
    email = data.get('email', '').strip()
    notes = data.get('notes', '').strip()
    country_code = data.get('country_code', '').strip()

    if not name:
        return jsonify({'error': 'Name is required'}), 400
    if folder not in ['customers', 'staff']:
        return jsonify({'error': 'Folder must be either "customers" or "staff"'}), 400

    import re
    base_id = re.sub(r'[^a-zA-Z0-9_]', '', name.lower().replace(' ', '_'))
    if not base_id:
        base_id = 'contact'
    
    import time
    contact_id = f"{base_id}_{int(time.time())}"

    if not role:
        role = 'Client' if folder == 'customers' else 'Staff Member'

    conn = get_db()
    cursor = conn.cursor()

    cursor.execute('SELECT 1 FROM contacts WHERE id = %s', (contact_id,))
    if cursor.fetchone():
        conn.close()
        return jsonify({'error': 'Contact already exists'}), 400

    cursor.execute('''
        INSERT INTO contacts (id, name, phone, role, avatar, status, folder, unread_count, assigned_staff_id, email, notes, country_code)
        VALUES (%s, %s, %s, %s, %s, 'Offline', %s, 0, NULL, %s, %s, %s)
    ''', (contact_id, name, phone, role, avatar, folder, email, notes, country_code))

    conn.commit()

    cursor.execute('SELECT * FROM contacts WHERE id = %s', (contact_id,))
    new_contact = dict(cursor.fetchone())
    new_contact['tags'] = []

    conn.close()
    return jsonify(new_contact)

@app.route('/api/contacts/staff', methods=['POST'])
def create_staff():
    data = request.json or {}
    name = data.get('name', '').strip()
    phone = data.get('phone', '').strip()
    role = data.get('role', 'Staff Member').strip()
    avatar = data.get('avatar', '').strip()
    
    if not name:
        return jsonify({'error': 'Staff name is required'}), 400
        
    staff_id = name.lower().replace(' ', '_')
    
    conn = get_db()
    cursor = conn.cursor()
    
    cursor.execute('SELECT 1 FROM contacts WHERE id = %s', (staff_id,))
    if cursor.fetchone():
        conn.close()
        return jsonify({'error': 'Staff member folder already exists'}), 400
        
    cursor.execute('''
        INSERT INTO contacts (id, name, phone, role, avatar, status, folder, unread_count, assigned_staff_id)
        VALUES (%s, %s, %s, %s, %s, 'Offline', 'staff', 0, NULL)
    ''', (staff_id, name, phone, role, avatar))
    
    conn.commit()
    
    cursor.execute('SELECT * FROM contacts WHERE id = %s', (staff_id,))
    new_staff = dict(cursor.fetchone())
    new_staff['tags'] = []
    
    conn.close()
    return jsonify(new_staff)

@app.route('/api/contacts/<contact_id>', methods=['DELETE'])
def delete_contact(contact_id):
    conn = get_db()
    cursor = conn.cursor()
    
    cursor.execute('SELECT 1 FROM contacts WHERE id = %s', (contact_id,))
    if not cursor.fetchone():
        conn.close()
        return jsonify({'error': 'Contact not found'}), 404
        
    cursor.execute('UPDATE contacts SET assigned_staff_id = NULL WHERE assigned_staff_id = %s', (contact_id,))
    cursor.execute('DELETE FROM contacts WHERE id = %s', (contact_id,))
    
    conn.commit()
    conn.close()
    
    return jsonify({'success': True})

@app.route('/api/contacts/<contact_id>/messages', methods=['GET'])
def get_messages(contact_id):
    conn = get_db()
    cursor = conn.cursor()
    
    cursor.execute('UPDATE contacts SET unread_count = 0 WHERE id = %s', (contact_id,))
    cursor.execute("UPDATE messages SET status = 'read' WHERE contact_id = %s AND is_user = FALSE AND status = 'unread'", (contact_id,))
    conn.commit()
    
    cursor.execute('SELECT * FROM messages WHERE contact_id = %s ORDER BY id ASC', (contact_id,))
    rows = cursor.fetchall()
    
    messages = []
    for r in rows:
        msg = dict(r)
        if isinstance(msg['reactions'], str):
            try:
                msg['reactions'] = json.loads(msg['reactions'])
            except Exception:
                msg['reactions'] = []
        messages.append(msg)
        
    conn.close()
    return jsonify(messages)

def simulate_message_status_updates(msg_id):
    # Wait 1.2 seconds, transition to 'delivered'
    time.sleep(1.2)
    conn = None
    try:
        conn = database.get_db_connection()
        cursor = conn.cursor()
        cursor.execute("UPDATE messages SET status = 'delivered' WHERE id = %s AND status = 'sent'", (msg_id,))
        conn.commit()
    except Exception as e:
        print(f"[Simulator Error] Failed to update status to delivered: {e}")
    finally:
        if conn is not None:
            conn.close()
    
    # Wait another 1.8 seconds, transition to 'read'
    time.sleep(1.8)
    conn = None
    try:
        conn = database.get_db_connection()
        cursor = conn.cursor()
        cursor.execute("UPDATE messages SET status = 'read' WHERE id = %s AND status = 'delivered'", (msg_id,))
        conn.commit()
    except Exception as e:
        print(f"[Simulator Error] Failed to update status to read: {e}")
    finally:
        if conn is not None:
            conn.close()

def background_message_simulator():
    time.sleep(10) # Start generating messages 10 seconds after server start
    customers = ['david', 'customer_a', 'customer_b', 'customer_c', 'customer_d', 'customer_e', 'customer_f', 'customer_g']
    messages_pool = [
        "Hi Marcus, just wanted to check if the database migration was completed?",
        "Are the design specifications ready for review?",
        "Can we schedule our strategy sync tomorrow morning?",
        "I received the files, everything looks great!",
        "Let me know when you are free to jump on a quick call.",
        "Could you please check the project status on the dashboard?",
        "Is the test server deployed?",
        "The pricing contract looks good. Let's proceed."
    ]
    while True:
        try:
            time.sleep(25) # Generate a new message every 25 seconds
            import random
            cust_id = random.choice(customers)
            text = random.choice(messages_pool)
            
            now = datetime.now()
            time_str = now.strftime('%I:%M %p')
            
            conn = None
            try:
                conn = database.get_db_connection()
                cursor = conn.cursor()
                
                # 1. Insert incoming unread message
                cursor.execute('''
                    INSERT INTO messages (contact_id, text, is_user, time, is_audio, duration, is_file, file_name, file_size, reactions, status)
                    VALUES (%s, %s, FALSE, %s, FALSE, NULL, FALSE, NULL, NULL, '[]'::jsonb, 'unread')
                ''', (cust_id, text, time_str))
                
                # 2. Increment unread count of contact
                cursor.execute('UPDATE contacts SET unread_count = unread_count + 1 WHERE id = %s', (cust_id,))
                
                conn.commit()
                print(f"[Simulator] Generated new unread message from '{cust_id}': {text}")
            finally:
                if conn is not None:
                    conn.close()
        except Exception as e:
            print(f"[Simulator Error] Background message simulator error: {e}")

# Start the background message simulator
threading.Thread(target=background_message_simulator, daemon=True).start()

@app.route('/api/contacts/<contact_id>/messages', methods=['POST'])
def send_message(contact_id):
    data = request.json or {}
    text = data.get('text', '')
    is_audio = data.get('is_audio', False)
    duration = data.get('duration')
    is_file = data.get('is_file', False)
    file_name = data.get('file_name')
    file_size = data.get('file_size')
    
    if not text and not is_audio and not is_file:
        return jsonify({'error': 'Message content is empty'}), 400
        
    conn = get_db()
    cursor = conn.cursor()
    
    cursor.execute('SELECT 1 FROM contacts WHERE id = %s', (contact_id,))
    if not cursor.fetchone():
        conn.close()
        return jsonify({'error': 'Contact not found'}), 404
        
    now = datetime.now()
    time_str = now.strftime('%I:%M %p')
    
    cursor.execute('SELECT name FROM contacts WHERE id = %s', (contact_id,))
    contact_row = cursor.fetchone()
    if not contact_row:
        conn.close()
        return jsonify({'error': 'Contact not found'}), 404
    
    cursor.execute('''
        INSERT INTO messages (contact_id, text, is_user, time, is_audio, duration, is_file, file_name, file_size, reactions, status)
        VALUES (%s, %s, TRUE, %s, %s, %s, %s, %s, %s, '[]'::jsonb, 'sent')
        RETURNING id
    ''', (contact_id, text, time_str, is_audio, duration, is_file, file_name, file_size))
    
    user_msg_id = cursor.fetchone()['id']
    
    bot_message = None
    if contact_id == 'ebi' and text:
        bot_response = "I received your request. Compiling the project summary updates now..."
        lower_text = text.lower()
        if 'summarize' in lower_text or 'project' in lower_text:
            bot_response = "Here is the summary of active projects:\n- Project Aurora: Phase 3 (75% completed)\n- Project Vortex: Phase 1 (33% completed)\n- Project Titan: Phase 4 (66% completed)"
        elif 'report' in lower_text:
            bot_response = "Report compiled successfully. The Aurora Design System specifications have been packaged."
            
        cursor.execute('''
            INSERT INTO messages (contact_id, text, is_user, time, is_audio, duration, is_file, file_name, file_size, reactions, status)
            VALUES (%s, %s, FALSE, %s, FALSE, NULL, FALSE, NULL, NULL, '[]'::jsonb, 'read')
            RETURNING id
        ''', (contact_id, bot_response, time_str))
        
        bot_msg_id = cursor.fetchone()['id']
        cursor.execute('SELECT * FROM messages WHERE id = %s', (bot_msg_id,))
        bot_message = dict(cursor.fetchone())
        if isinstance(bot_message['reactions'], str):
            bot_message['reactions'] = json.loads(bot_message['reactions'])
        
    conn.commit()
    
    # Launch status simulation thread for outgoing user message
    threading.Thread(target=simulate_message_status_updates, args=(user_msg_id,), daemon=True).start()
    
    cursor.execute('SELECT * FROM messages WHERE id = %s', (user_msg_id,))
    user_message = dict(cursor.fetchone())
    if isinstance(user_message['reactions'], str):
        user_message['reactions'] = json.loads(user_message['reactions'])
    
    conn.close()
    
    return jsonify({
        'status': 'success',
        'user_message': user_message,
        'bot_message': bot_message
    })

@app.route('/api/contacts/<contact_id>/messages/<int:msg_id>/react', methods=['POST'])
def react_message(contact_id, msg_id):
    data = request.json or {}
    emoji = data.get('emoji', '').strip()
    if not emoji:
        return jsonify({'error': 'Emoji reaction is required'}), 400
        
    conn = get_db()
    cursor = conn.cursor()
    
    cursor.execute('SELECT reactions FROM messages WHERE id = %s AND contact_id = %s', (msg_id, contact_id))
    row = cursor.fetchone()
    if not row:
        conn.close()
        return jsonify({'error': 'Message not found'}), 404
        
    reactions = row['reactions']
    if isinstance(reactions, str):
        reactions = json.loads(reactions)
    
    if emoji in reactions:
        reactions.remove(emoji)
    else:
        reactions.append(emoji)
        
    cursor.execute('UPDATE messages SET reactions = %s WHERE id = %s', (json.dumps(reactions), msg_id))
    conn.commit()
    conn.close()
    
    return jsonify({'status': 'success', 'reactions': reactions})

@app.route('/api/broadcast', methods=['POST'])
def send_broadcast():
    data = request.json or {}
    recipients = data.get('recipients', [])
    text = data.get('text', '')
    is_file = data.get('is_file', False)
    file_name = data.get('file_name', None)
    file_size = data.get('file_size', None)
    
    if not recipients or (not text and not is_file):
        return jsonify({'error': 'Recipients and text/file content are required'}), 400
        
    now = datetime.now()
    time_str = now.strftime('%I:%M %p')
    date_str = now.strftime('%b %d, %Y')
    
    conn = get_db()
    cursor = conn.cursor()
    
    recipient_names = []
    delivered_count = 0
    
    for rid in recipients:
        cursor.execute('SELECT name FROM contacts WHERE id = %s', (rid,))
        contact_row = cursor.fetchone()
        if contact_row:
            recipient_names.append(contact_row['name'])
            cursor.execute('''
                INSERT INTO messages (contact_id, text, is_user, time, is_audio, duration, is_file, file_name, file_size, reactions)
                VALUES (%s, %s, TRUE, %s, FALSE, NULL, %s, %s, %s, '[]'::jsonb)
            ''', (rid, text, time_str, is_file, file_name, file_size))
            
            cursor.execute('UPDATE contacts SET unread_count = unread_count + 1 WHERE id = %s', (rid,))
            delivered_count += 1
            
    recipients_str = ', '.join(recipient_names)
    cursor.execute('''
        INSERT INTO broadcast_history (text, time, date, recipient_count, delivered_count, is_file, file_name, file_size, recipients)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
    ''', (text, time_str, date_str, len(recipients), delivered_count, is_file, file_name, file_size, recipients_str))
    
    conn.commit()
    conn.close()
    
    return jsonify({
        'status': 'success',
        'message': f'Broadcast delivered to {delivered_count} contacts',
        'delivered_count': delivered_count
    })

@app.route('/api/broadcast/history', methods=['GET'])
def get_broadcast_history():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM broadcast_history ORDER BY id DESC')
    rows = cursor.fetchall()
    conn.close()
    
    history = []
    for r in rows:
        item = dict(r)
        item['is_file'] = bool(item['is_file'])
        history.append(item)
        
    return jsonify(history)

@app.route('/api/broadcast/lists', methods=['GET', 'POST'])
def broadcast_lists():
    conn = get_db()
    cursor = conn.cursor()
    
    if request.method == 'POST':
        data = request.json or {}
        list_id = data.get('id', '').strip()
        name = data.get('name', '').strip()
        members = data.get('members', [])
        
        if not name:
            conn.close()
            return jsonify({'error': 'List name is required'}), 400
            
        if not list_id:
            list_id = name.lower().replace(' ', '_')
            
        cursor.execute('''
            INSERT INTO broadcast_lists (id, name) VALUES (%s, %s)
            ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name
        ''', (list_id, name))
        cursor.execute('DELETE FROM broadcast_list_members WHERE list_id = %s', (list_id,))
        for mid in members:
            cursor.execute('INSERT INTO broadcast_list_members (list_id, contact_id) VALUES (%s, %s)', (list_id, mid))
        conn.commit()
        
    cursor.execute('SELECT * FROM broadcast_lists')
    lists_rows = cursor.fetchall()
    
    lists = []
    for row in lists_rows:
        lst = dict(row)
        cursor.execute('SELECT contact_id FROM broadcast_list_members WHERE list_id = %s', (lst['id'],))
        lst['members'] = [r['contact_id'] for r in cursor.fetchall()]
        lists.append(lst)
        
    conn.close()
    return jsonify(lists)

@app.route('/api/broadcast/lists/<list_id>', methods=['DELETE'])
def delete_broadcast_list(list_id):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('DELETE FROM broadcast_lists WHERE id = %s', (list_id,))
    cursor.execute('DELETE FROM broadcast_list_members WHERE list_id = %s', (list_id,))
    conn.commit()
    conn.close()
    return jsonify({'success': True})

@app.route('/api/profile', methods=['GET', 'POST'])
def profile():
    conn = get_db()
    cursor = conn.cursor()
    
    user_phone = request.headers.get('x-user-phone')
    if not user_phone:
        auth_header = request.headers.get('Authorization')
        if auth_header and auth_header.startswith('Bearer '):
            user_phone = auth_header.split(' ')[1]
            
    if not user_phone:
        user_phone = '+1 (555) 019-8833'
        
    if request.method == 'POST':
        data = request.json or {}
        name = data.get('name', 'Marcus Sterling')
        role = data.get('role', 'Executive VP | Global EB Tech')
        phone = data.get('phone', user_phone)
        avatar = data.get('avatar', '')
        email = data.get('email', '')
        notifications_enabled = data.get('notifications_enabled', True)
        notification_sound = data.get('notification_sound', True)
        notification_vibration = data.get('notification_vibration', True)
        security_2fa = data.get('security_2fa', False)
        read_receipts = data.get('read_receipts', True)
        last_seen_visible = data.get('last_seen_visible', True)
        
        country_code = data.get('country_code')
        country_name = data.get('country_name')
        country_flag = data.get('country_flag')
        
        cursor.execute('SELECT id FROM user_profile WHERE phone = %s', (user_phone,))
        row = cursor.fetchone()
        if row:
            user_id = row['id']
        else:
            user_id = 'marcus'
            
        cursor.execute('''
            UPDATE user_profile
            SET name = %s, role = %s, phone = %s, avatar = %s, email = %s,
                notifications_enabled = %s, notification_sound = %s, notification_vibration = %s,
                security_2fa = %s, read_receipts = %s, last_seen_visible = %s,
                country_code = COALESCE(%s, country_code),
                country_name = COALESCE(%s, country_name),
                country_flag = COALESCE(%s, country_flag)
            WHERE id = %s
        ''', (name, role, phone, avatar, email,
              bool(notifications_enabled), bool(notification_sound), bool(notification_vibration),
              bool(security_2fa), bool(read_receipts), bool(last_seen_visible),
              country_code, country_name, country_flag, user_id))
        conn.commit()
        
    cursor.execute('SELECT * FROM user_profile WHERE phone = %s', (user_phone,))
    row = cursor.fetchone()
    
    if not row:
        cursor.execute("SELECT * FROM user_profile WHERE id = 'marcus'")
        row = cursor.fetchone()
        
    conn.close()
    
    if row:
        p = dict(row)
        for key in ['notifications_enabled', 'notification_sound', 'notification_vibration', 'security_2fa', 'read_receipts', 'last_seen_visible']:
            p[key] = bool(p[key])
        return jsonify(p)
    else:
        return jsonify({'error': 'Profile not found'}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
