import sqlite3
import csv
import re

# Ruta de la base de datos
DB_PATH = 'data/service_db.sqlite'

# Conexión a la base de datos
conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()

# Crear tablas con la nueva columna service_schedule
cursor.execute('''
    CREATE TABLE IF NOT EXISTS MobileUnits (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE
    )
''')
cursor.execute('''
    CREATE TABLE IF NOT EXISTS Wells (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        mobile_unit_id INTEGER,
        status TEXT NOT NULL,
        service_schedule TEXT NOT NULL,
        FOREIGN KEY (mobile_unit_id) REFERENCES MobileUnits(id)
    )
''')
cursor.execute('''
    CREATE TABLE IF NOT EXISTS Sites (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        mobile_unit_id INTEGER,
        status TEXT NOT NULL,
        motive TEXT,
        service_schedule TEXT NOT NULL,
        FOREIGN KEY (mobile_unit_id) REFERENCES MobileUnits(id)
    )
''')

# Función para extraer mobile_unit_id, name, phone
def parse_mobile_unit(asignacion):
    if not asignacion:
        return None, None, None
    # Manejar variaciones como 'Móvil 2 Caba - 113735-4716' o 'Acude Móvil 22 – Bernal - 1120314941'
    asignacion = asignacion.replace('Movil ', '').replace('Móvil ', '').replace('Acude ', '')
    parts = asignacion.split(' - ')
    if len(parts) >= 2:
        # Extraer el número al inicio de la primera parte
        first_part = parts[0].strip()
        if first_part:
            match = re.match(r'(\d+)', first_part)
            if match:
                mobile_id = int(match.group(1))
                name = 'Móvil ' + ' '.join(parts[0].split()[1:]) if ' '.join(parts[0].split()[1:]) else parts[0]
                phone = parts[1]
                return mobile_id, name, phone
    return None, None, None

# Procesar Wells (pozos)
with open('data/wells_data.csv', 'r', encoding='utf-8-sig') as file:
    reader = csv.DictReader(file, delimiter=';')
    wells = []
    mobile_units = {}
    print("Encabezados de wells:", reader.fieldnames)  # Depuración
    for row in reader:
        mobile_id, name, phone = parse_mobile_unit(row['Asignación'])
        if mobile_id:
            mobile_units[mobile_id] = (mobile_id, name, phone)
        status = "Activo" if "Todos los dias 24 hs" in row['Dias y Hora Servicio'] else "Parcial"
        wells.append((row['Pozo'], row['Pozo'], row['Ubicación/Calle/Dirección'], mobile_id, status, row['Dias y Hora Servicio']))
    cursor.executemany('INSERT OR IGNORE INTO MobileUnits (id, name, phone) VALUES (?, ?, ?)', mobile_units.values())
    cursor.executemany('INSERT OR IGNORE INTO Wells (id, name, address, mobile_unit_id, status, service_schedule) VALUES (?, ?, ?, ?, ?, ?)', wells)
    print(f"Insertados {len(wells)} pozos.")

# Procesar Sites (sitios)
with open('data/sites_data.csv', 'r', encoding='utf-8-sig') as file:
    reader = csv.DictReader(file, delimiter=';')
    sites = []
    mobile_units = {}
    print("Encabezados de sites:", reader.fieldnames)  # Depuración
    for row in reader:
        mobile_id, name, phone = parse_mobile_unit(row['Asignación'])
        if mobile_id:
            mobile_units[mobile_id] = (mobile_id, name, phone)
        status = "Activo" if "Todos los dias - 24 hs" in row['Dias y Hora Servicio'] else "Parcial"
        # Separar nombre y dirección en Sitio usando ' - ' como delimitador principal
        site_parts = row['Sitio'].split(' - ', 1)  # Divide solo en el primer ' - '
        site_id = site_parts[0].strip() if len(site_parts) > 0 else row['Sitio']
        site_name = site_parts[0].strip() if len(site_parts) > 0 else row['Sitio']
        site_address = site_parts[1].strip() if len(site_parts) > 1 else ''
        sites.append((site_id, site_name, site_address, mobile_id, status, row['Motivo'], row['Dias y Hora Servicio']))
    cursor.executemany('INSERT OR IGNORE INTO MobileUnits (id, name, phone) VALUES (?, ?, ?)', mobile_units.values())
    cursor.executemany('INSERT OR IGNORE INTO Sites (id, name, address, mobile_unit_id, status, motive, service_schedule) VALUES (?, ?, ?, ?, ?, ?, ?)', sites)
    print(f"Insertados {len(sites)} sitios.")

# Commit y cerrar
conn.commit()
conn.close()

print(f"Base de datos {DB_PATH} creada exitosamente con pozos y sitios.")