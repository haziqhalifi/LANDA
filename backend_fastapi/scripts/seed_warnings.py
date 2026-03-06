"""Seed the Supabase `warnings` table with sample hyper-local warnings.

Run from the backend_fastapi directory:
    python -m scripts.seed_warnings
"""

import sys
import os

# Allow imports from the app package
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.warnings import create_warning


SAMPLE_WARNINGS = [
    {
        "title": "Flood Warning: Kg. Banjir",
        "description": "Water levels rising rapidly at Sungai Lembing. Current level at 2.5m, "
                       "approaching danger threshold. Immediate evacuation recommended for "
                       "low-lying areas. Follow the green path to higher ground.",
        "hazard_type": "flood",
        "alert_level": "warning",
        "latitude": 3.8100,
        "longitude": 103.3280,
        "radius_km": 5.0,
        "source": "MET Malaysia",
    },
    {
        "title": "Landslide Risk: Bukit Fraser",
        "description": "Soil erosion detected near hillside settlement area after heavy "
                       "rainfall. Ground instability increasing. Residents within 2km radius "
                       "should prepare for possible evacuation.",
        "hazard_type": "landslide",
        "alert_level": "observe",
        "latitude": 3.7200,
        "longitude": 101.7300,
        "radius_km": 3.0,
        "source": "JKR Malaysia",
    },
    {
        "title": "Flash Flood Alert: Kuantan Town",
        "description": "Heavy rainfall expected in the next 6 hours. Flash flood advisory "
                       "issued for Kuantan town centre and surrounding kampung areas. "
                       "Avoid low-lying roads.",
        "hazard_type": "flood",
        "alert_level": "advisory",
        "latitude": 3.8077,
        "longitude": 103.3260,
        "radius_km": 10.0,
        "source": "NADMA",
    },
    {
        "title": "EVACUATE: Sungai Pahang Overflow",
        "description": "Sungai Pahang has breached its banks at KM 12. Water level is 4.2m "
                       "and rising. ALL residents within 8km must evacuate to designated "
                       "relief centres IMMEDIATELY. Nearest safe zone: Dewan Komuniti "
                       "Bukit Pelindung.",
        "hazard_type": "flood",
        "alert_level": "evacuate",
        "latitude": 3.8050,
        "longitude": 103.3200,
        "radius_km": 8.0,
        "source": "DID Malaysia",
    },
]


def main():
    print("Seeding warnings table...\n")
    for i, w in enumerate(SAMPLE_WARNINGS, 1):
        try:
            record = create_warning(**w)
            print(f"  [{i}/{len(SAMPLE_WARNINGS)}] [SUCCESS] Created: {record['title']}")
            print(f"       ID: {record['id']}")
            print(f"       Level: {record['alert_level']}  |  Hazard: {record['hazard_type']}")
            print(f"       Location: ({record['latitude']}, {record['longitude']})  r={record['radius_km']}km\n")
        except Exception as e:
            print(f"  [{i}/{len(SAMPLE_WARNINGS)}] [FAILED] Failed: {w['title']}")
            print(f"       Error: {e}\n")

    print("Done! Warnings seeded successfully.")
    print("Start the backend and the Flutter app to see them in action.")


if __name__ == "__main__":
    main()
