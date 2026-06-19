import psycopg2
from psycopg2.extras import RealDictCursor
import os

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

def get_db_connection():
    db_url = os.environ.get('SUPABASE_DB_URL', '')
    if not db_url or 'YOUR_PASSWORD' in db_url:
        raise ValueError("Please configure your real SUPABASE_DB_URL in the backend .env file.")
    conn = psycopg2.connect(db_url, cursor_factory=RealDictCursor)
    return conn

def init_db():
    try:
        conn = get_db_connection()
    except Exception as e:
        print(f"Database connection failed: {e}")
        print("Please ensure SUPABASE_DB_URL is correctly configured in your .env file.")
        return

    cursor = conn.cursor()

    # Create Contacts table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS contacts (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            phone TEXT,
            role TEXT,
            avatar TEXT,
            status TEXT,
            folder TEXT,
            unread_count INTEGER DEFAULT 0,
            assigned_staff_id TEXT,
            email TEXT,
            notes TEXT,
            country_code TEXT,
            FOREIGN KEY (assigned_staff_id) REFERENCES contacts (id) ON DELETE SET NULL
        )
    ''')

    # Create Folders table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS folders (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            color TEXT
        )
    ''')

    # Create Tags table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS tags (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            color TEXT
        )
    ''')

    # Create Chat Tags mapping table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS chat_tags (
            contact_id TEXT,
            tag_id TEXT,
            PRIMARY KEY (contact_id, tag_id),
            FOREIGN KEY (contact_id) REFERENCES contacts (id) ON DELETE CASCADE,
            FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
        )
    ''')

    # Create Messages table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS messages (
            id SERIAL PRIMARY KEY,
            contact_id TEXT,
            text TEXT,
            is_user BOOLEAN,
            time TEXT,
            is_audio BOOLEAN DEFAULT FALSE,
            duration TEXT,
            is_file BOOLEAN DEFAULT FALSE,
            file_name TEXT,
            file_size TEXT,
            reactions JSONB DEFAULT '[]'::jsonb,
            FOREIGN KEY (contact_id) REFERENCES contacts (id) ON DELETE CASCADE
        )
    ''')

    # Create User Profile table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS user_profile (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            role TEXT NOT NULL,
            phone TEXT NOT NULL,
            avatar TEXT,
            email TEXT,
            notifications_enabled BOOLEAN DEFAULT TRUE,
            notification_sound BOOLEAN DEFAULT TRUE,
            notification_vibration BOOLEAN DEFAULT TRUE,
            security_2fa BOOLEAN DEFAULT FALSE,
            read_receipts BOOLEAN DEFAULT TRUE,
            last_seen_visible BOOLEAN DEFAULT TRUE,
            country_code TEXT,
            country_name TEXT,
            country_flag TEXT,
            created_at TEXT,
            verification_status TEXT
        )
    ''')

    # Schema migration helper for user_profile columns
    cursor.execute("""
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name='user_profile' AND column_name='country_code'
    """)
    if not cursor.fetchone():
        cursor.execute("ALTER TABLE user_profile ADD COLUMN country_code TEXT")
        cursor.execute("ALTER TABLE user_profile ADD COLUMN country_name TEXT")
        cursor.execute("ALTER TABLE user_profile ADD COLUMN country_flag TEXT")
        cursor.execute("ALTER TABLE user_profile ADD COLUMN created_at TEXT")
        cursor.execute("ALTER TABLE user_profile ADD COLUMN verification_status TEXT")

    # Schema migration helper for contacts columns
    cursor.execute("""
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name='contacts' AND column_name='email'
    """)
    if not cursor.fetchone():
        cursor.execute("ALTER TABLE contacts ADD COLUMN email TEXT")
        cursor.execute("ALTER TABLE contacts ADD COLUMN notes TEXT")
        cursor.execute("ALTER TABLE contacts ADD COLUMN country_code TEXT")

    # Create Broadcast Lists table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS broadcast_lists (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL
        )
    ''')

    # Create Broadcast List Members table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS broadcast_list_members (
            list_id TEXT,
            contact_id TEXT,
            PRIMARY KEY (list_id, contact_id),
            FOREIGN KEY (list_id) REFERENCES broadcast_lists (id) ON DELETE CASCADE,
            FOREIGN KEY (contact_id) REFERENCES contacts (id) ON DELETE CASCADE
        )
    ''')

    # Create Broadcast History table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS broadcast_history (
            id SERIAL PRIMARY KEY,
            text TEXT,
            time TEXT,
            date TEXT,
            recipient_count INTEGER,
            delivered_count INTEGER,
            is_file BOOLEAN DEFAULT FALSE,
            file_name TEXT,
            file_size TEXT,
            recipients TEXT
        )
    ''')

    # Create OTPs table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS otps (
            phone TEXT PRIMARY KEY,
            code TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    # Seed User Profile
    cursor.execute('''
        INSERT INTO user_profile (id, name, role, phone, avatar, email, notifications_enabled, notification_sound, notification_vibration, security_2fa, read_receipts, last_seen_visible, country_code, country_name, country_flag, created_at, verification_status)
        VALUES ('marcus', 'Marcus Sterling', 'Executive VP | Global EB Tech', '+1 (555) 019-8833', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80', 'marcus.sterling@ebglobal.com', TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, '+1', 'United States', '🇺🇸', '2026-06-18', 'Verified')
        ON CONFLICT (id) DO NOTHING
    ''')

    # Seed Folders
    folders = [
        ('all', 'All', '#3b82f6'),
        ('customers', 'Customers', '#10b981'),
        ('staff', 'Staff', '#3b82f6')
    ]
    cursor.executemany('INSERT INTO folders (id, name, color) VALUES (%s, %s, %s) ON CONFLICT (id) DO NOTHING', folders)

    # Seed Tags
    tags = [
        ('vip', 'VIP', '#ef4444'),
        ('customer', 'Customer', '#10b981'),
        ('alumni', 'Alumni', '#8b5cf6'),
        ('sponsor', 'Sponsor', '#f59e0b'),
        ('urgent', 'Urgent', '#ef4444')
    ]
    cursor.executemany('INSERT INTO tags (id, name, color) VALUES (%s, %s, %s) ON CONFLICT (id) DO NOTHING', tags)

    # Seed Contacts (Staff & Customers)
    contacts = [
        # Staff members (folder = 'staff')
        ('sarah', 'Sarah Jenkins', '+1 (555) 019-2834', 'Project Lead', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=100&q=80', 'Active Now', 'staff', 0, None),
        ('emma', 'Emma Watson', '+1 (555) 014-9821', 'HR Manager', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=100&q=80', 'Offline', 'staff', 0, None),
        ('john', 'John Doe', '+1 (555) 012-3456', 'Senior Architect', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=100&q=80', 'Active Now', 'staff', 0, None),
        ('michael', 'Michael Chang', '+1 (555) 017-6543', 'Lead Developer', 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=100&q=80', 'Away', 'staff', 0, None),
        
        # Support/Special
        ('ebi', 'EBI (AI Engine)', '', 'GEBTALK Mascot', '', 'Operational', 'support', 0, None),
        ('support', 'Support Desk', '+1 (555) 010-0000', 'Tech Support', 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=100&q=80', 'Online', 'support', 0, None),
        
        # Customers (folder = 'customers', assigned to staff)
        ('david', 'David Miller', '+1 (555) 015-1122', 'Client VP', 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=100&q=80', 'Away', 'customers', 1, 'sarah'),
        ('customer_a', 'Alice Johnson', '+1 (555) 016-3344', 'CEO at Aurora Corp', '', 'Offline', 'customers', 0, 'john'),
        ('customer_b', 'Bob Smith', '+1 (555) 018-5566', 'CFO at Aurora Corp', '', 'Offline', 'customers', 0, 'john'),
        ('customer_c', 'Charlie Brown', '+1 (555) 011-7788', 'Director at Aurora Corp', '', 'Online', 'customers', 0, 'john'),
        ('customer_d', 'Diana Prince', '+1 (555) 013-9900', 'Manager at Vortex', '', 'Active Now', 'customers', 2, 'sarah'),
        ('customer_e', 'Ethan Hunt', '+1 (555) 015-2233', 'Agent at Vortex', '', 'Online', 'customers', 0, 'sarah'),
        ('customer_f', 'Fiona Gallagher', '+1 (555) 017-4455', 'Executive at Titan', '', 'Offline', 'customers', 0, 'michael'),
        ('customer_g', 'George Clark', '+1 (555) 019-6677', 'Lead at Titan', '', 'Online', 'customers', 0, 'michael')
    ]
    cursor.executemany('''
        INSERT INTO contacts (id, name, phone, role, avatar, status, folder, unread_count, assigned_staff_id)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s) ON CONFLICT (id) DO NOTHING
    ''', contacts)

    # Seed Chat Tags association
    chat_tags = [
        ('sarah', 'vip'),
        ('ebi', 'vip'),
        ('david', 'vip'),
        ('david', 'customer'),
        ('emma', 'alumni'),
        ('support', 'urgent'),
        ('customer_a', 'vip'),
        ('customer_a', 'customer'),
        ('customer_d', 'urgent'),
        ('customer_d', 'customer'),
        ('customer_f', 'customer')
    ]
    cursor.executemany('INSERT INTO chat_tags (contact_id, tag_id) VALUES (%s, %s) ON CONFLICT (contact_id, tag_id) DO NOTHING', chat_tags)

    # Seed Messages (Only if table is empty)
    cursor.execute('SELECT COUNT(*) FROM messages')
    if cursor.fetchone()['count'] == 0:
        messages = [
            # Sarah Jenkins
            ('sarah', 'Hi! EBI informed me you wanted to review the project status. I uploaded the design system specs and left a voice note.', 0, '10:24 AM', 0, None, 0, None, None, '[]'),
            ('sarah', None, 0, '10:25 AM', 1, '0:42', 0, None, None, '[]'),
            ('sarah', None, 0, '10:25 AM', 0, None, 1, 'aurora_design_specs.pdf', '4.8 MB • PDF', '[]'),
            ('sarah', "Thanks Sarah! EBI is compiling the code framework now. I'll review these specs right away.", 1, '10:28 AM', 0, None, 0, None, None, '[]'),
            
            # EBI Bot
            ('ebi', "Hello! I am EBI, your business co-pilot. I can compile spreadsheets, schedule strategy recaps, or write code templates. Ask me to 'summarize projects' or 'generate report'!", 0, 'Just Now', 0, None, 0, None, None, '[]'),
            
            # David Miller
            ('david', 'Hi Marcus, the Aurora prototype looks great. Can we review the pricing contract today?', 0, '9:45 AM', 0, None, 0, None, None, '[]'),
            
            # Diana Prince (Vortex)
            ('customer_d', 'Hey, we noticed some issues in the integration workspace. Can we jump on a call?', 0, 'Yesterday', 0, None, 0, None, None, '[]'),
            ('customer_d', 'Let me know when you are free.', 0, 'Yesterday', 0, None, 0, None, None, '[]'),
            
            # Emma Watson
            ('emma', 'Hi Marcus, please approve the team expansion request on the HR portal when you get a chance.', 0, 'Yesterday', 0, None, 0, None, None, '[]'),
            
            # Support
            ('support', 'Ticket TKT-8902 has been routed to engineering. System status is fully optimized.', 0, 'Monday', 0, None, 0, None, None, '[]'),
            
            # Other Customers placeholder messages to avoid empty histories
            ('customer_a', 'Hello, Alice here. Looking forward to our sync.', 0, 'Tuesday', 0, None, 0, None, None, '[]'),
            ('customer_b', 'Hi Marcus, did you receive the transaction reports?', 0, 'Wednesday', 0, None, 0, None, None, '[]'),
            ('customer_c', 'We are good to go for the project launch next week.', 0, 'Monday', 0, None, 0, None, None, '[]'),
            ('customer_e', 'Understood. Will update the team.', 0, 'Friday', 0, None, 0, None, None, '[]'),
            ('customer_f', 'Can you send me the contract drafts?', 0, 'Thursday', 0, None, 0, None, None, '[]'),
            ('customer_g', 'The Titan build looks stable on our end.', 0, '3 Days Ago', 0, None, 0, None, None, '[]')
        ]
        
        # Convert integers to actual Python booleans for PostgreSQL boolean fields
        postgres_messages = []
        for msg in messages:
            msg_list = list(msg)
            msg_list[2] = bool(msg_list[2]) # is_user
            msg_list[4] = bool(msg_list[4]) # is_audio
            msg_list[6] = bool(msg_list[6]) # is_file
            postgres_messages.append(tuple(msg_list))

        cursor.executemany('''
            INSERT INTO messages (contact_id, text, is_user, time, is_audio, duration, is_file, file_name, file_size, reactions)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        ''', postgres_messages)

    conn.commit()
    conn.close()
    print("Database initialized successfully.")

if __name__ == '__main__':
    init_db()
