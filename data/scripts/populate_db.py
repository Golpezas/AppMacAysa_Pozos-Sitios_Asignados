import sqlite3
import pandas as pd
import re
import os

# Constantes
DB_PATH = 'assets/service_db.sqlite'
RAW_DATA_DIR = 'data/raw'
SITES_CSV = 'sites_data.csv'
WELLS_CSV = 'wells_data.csv'

def parse_mobile_unit(assignment):
    """
    Extrae el ID, nombre y teléfono de la unidad móvil a partir de la cadena de asignación.
    Ej: 'Movil 2 Caba - 113735-4716' -> (2, 'Movil 2 Caba', '113735-4716')
    """
    if not assignment:
        return None, None, None
    
    match = re.search(r'(\d+)\s*(.*?)\s*-\s*(\S+)', assignment.strip())
    if match:
        try:
            mobile_id = int(match.group(1))
            name = f"Móvil {mobile_id}"
            phone = match.group(3)
            return mobile_id, name, phone
        except (ValueError, IndexError):
            return None, None, None
    return None, None, None

def create_and_populate_db():
    """
    Crea la base de datos y sus tablas, y las puebla con datos de los CSV.
    """
    # Crea el directorio 'assets' si no existe
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # Crear tablas
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS MobileUnits (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            phone TEXT NOT NULL UNIQUE
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
    
    mobile_units = {}

    # Procesar y poblar la tabla 'Sites'
    try:
        sites_df = pd.read_csv(os.path.join(RAW_DATA_DIR, SITES_CSV), sep=';')
        sites = []
        for index, row in sites_df.iterrows():
            mobile_id, name, phone = parse_mobile_unit(row.get('Asignación'))
            if mobile_id:
                mobile_units[mobile_id] = (mobile_id, name, phone)
            
            site_parts = row.get('Sitio', '').split(' - ', 1)
            site_id = site_parts[0].strip()
            site_name = site_id
            site_address = site_parts[1].strip() if len(site_parts) > 1 else 'N/A'
            status = "Activo" if "Todos los dias - 24 hs" in row.get('Dias y Hora Servicio', '') else "Parcial"
            motive = row.get('Motivo', '')
            service_schedule = row.get('Dias y Hora Servicio', '')
            sites.append((site_id, site_name, site_address, mobile_id, status, motive, service_schedule))
        
        cursor.executemany('INSERT OR IGNORE INTO Sites (id, name, address, mobile_unit_id, status, motive, service_schedule) VALUES (?, ?, ?, ?, ?, ?, ?)', sites)
        print(f"Insertados {len(sites)} sitios.")

    except FileNotFoundError:
        print(f"Advertencia: No se encontró el archivo {SITES_CSV}")

    # Procesar y poblar la tabla 'Wells'
    try:
        wells_df = pd.read_csv(os.path.join(RAW_DATA_DIR, WELLS_CSV), sep=';')
        wells = []
        for index, row in wells_df.iterrows():
            mobile_id, name, phone = parse_mobile_unit(row.get('Asignación'))
            if mobile_id:
                mobile_units[mobile_id] = (mobile_id, name, phone)
            
            well_id = row.get('Pozo', '')
            well_name = well_id
            well_address = row.get('Ubicación/Calle/Dirección', '')
            status = "Activo" if "Todos los dias 24 hs" in row.get('Dias y Hora Servicio', '') else "Parcial"
            service_schedule = row.get('Dias y Hora Servicio', '')
            wells.append((well_id, well_name, well_address, mobile_id, status, service_schedule))
        
        cursor.executemany('INSERT OR IGNORE INTO Wells (id, name, address, mobile_unit_id, status, service_schedule) VALUES (?, ?, ?, ?, ?, ?)', wells)
        print(f"Insertados {len(wells)} pozos.")

    except FileNotFoundError:
        print(f"Advertencia: No se encontró el archivo {WELLS_CSV}")

    # Poblar la tabla 'MobileUnits' (incluye datos de sitios y pozos)
    cursor.executemany('INSERT OR IGNORE INTO MobileUnits (id, name, phone) VALUES (?, ?, ?)', mobile_units.values())
    
    conn.commit()
    conn.close()
    print(f"Base de datos {DB_PATH} creada y poblada exitosamente.")

if __name__ == '__main__':
    create_and_populate_db()