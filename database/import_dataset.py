
import pandas as pd
import psycopg

FILE = "brahmaputra_synthetic_dataset_boys_only.xlsx"

# Read the three sheets from the Excel workbook.
rooms = pd.read_excel(FILE, sheet_name="Rooms")
students = pd.read_excel(FILE, sheet_name="Students")
assignments = pd.read_excel(FILE, sheet_name="Room_Assignments")

# Adjust these credentials if your local PostgreSQL setup differs.
with psycopg.connect(
    "host=localhost port=5432 dbname=brahmaputra_hostel "
    "user=mysha_11 password=YOUR_POSTGRES_PASSWORD"
) as conn:
    with conn.cursor() as cur:

        # Import rooms first because assignments reference them.
        for _, r in rooms.iterrows():
            cur.execute(
                """
                INSERT INTO rooms
                    (room_number, floor, capacity, type)
                VALUES (%s, %s, %s, %s)
                ON CONFLICT (room_number) DO UPDATE SET
                    floor = EXCLUDED.floor,
                    capacity = EXCLUDED.capacity,
                    type = EXCLUDED.type
                """,
                (
                    r["room_number"],
                    int(r["floor"]),
                    int(r["capacity"]),
                    r["room_type"],
                ),
            )

        # Import students.
        for _, s in students.iterrows():
            cur.execute(
                """
                INSERT INTO students (roll_number, name, email)
                VALUES (%s, %s, %s)
                ON CONFLICT (roll_number) DO UPDATE SET
                    name = EXCLUDED.name,
                    email = EXCLUDED.email
                """,
                (s["roll_number"], s["name"], s["email"]),
            )

        # Import room-to-student mappings.
        for _, a in assignments.iterrows():
            cur.execute(
                """
                INSERT INTO room_assignments
                    (room_number, student_roll_number)
                VALUES (%s, %s)
                ON CONFLICT (student_roll_number) DO UPDATE SET
                    room_number = EXCLUDED.room_number
                """,
                (a["room_number"], a["student_roll_number"]),
            )

print("Dataset imported successfully!")
