"""Seed the risk_zones, evacuation_centres, and evacuation_routes tables.

Run from the backend_fastapi directory:
    python -m scripts.seed_risk_map
"""

import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.risk_zones import (
    create_risk_zone,
    create_evacuation_centre,
    create_evacuation_route,
)


# ── Sample Risk Zones near Kuantan, Pahang ──────────────────────────────────

RISK_ZONES = [
    {
        "name": "Sungai Lembing Flood Zone",
        "zone_type": "danger",
        "hazard_type": "flood",
        "latitude": 3.9200,
        "longitude": 103.0200,
        "radius_km": 3.0,
        "risk_score": 0.92,
        "description": "Historical flood-prone area along Sungai Lembing. "
                       "Water levels regularly exceed danger threshold during monsoon season.",
    },
    {
        "name": "Kuantan Riverbank Risk Area",
        "zone_type": "danger",
        "hazard_type": "flood",
        "latitude": 3.8100,
        "longitude": 103.3280,
        "radius_km": 2.5,
        "risk_score": 0.85,
        "description": "Low-lying area near Kuantan River. Prone to flooding during heavy rainfall.",
    },
    {
        "name": "Bukit Pelindung Landslide Zone",
        "zone_type": "warning",
        "hazard_type": "landslide",
        "latitude": 3.8300,
        "longitude": 103.3500,
        "radius_km": 1.5,
        "risk_score": 0.68,
        "description": "Hillside area with elevated landslide risk due to soil erosion. "
                       "Monitor during extended rainfall.",
    },
    {
        "name": "Taman Gelora Elevated Risk",
        "zone_type": "warning",
        "hazard_type": "flood",
        "latitude": 3.7950,
        "longitude": 103.3100,
        "radius_km": 2.0,
        "risk_score": 0.55,
        "description": "Moderate flood risk — drainage capacity may be exceeded during heavy rain.",
    },
    {
        "name": "Teluk Cempedak Safe Zone",
        "zone_type": "safe",
        "hazard_type": "flood",
        "latitude": 3.8000,
        "longitude": 103.3770,
        "radius_km": 1.0,
        "risk_score": 0.10,
        "description": "Elevated coastal area, designated as safe zone and evacuation assembly point.",
    },
    {
        "name": "Bukit Ubi Safe Area",
        "zone_type": "safe",
        "hazard_type": "flood",
        "latitude": 3.8150,
        "longitude": 103.3400,
        "radius_km": 1.2,
        "risk_score": 0.08,
        "description": "High ground area — designated as emergency rally point for surrounding kampungs.",
    },
]

# ── Sample Evacuation Centres ──────────────────────────────────────────────

EVACUATION_CENTRES = [
    {
        "name": "Dewan Komuniti Bukit Pelindung",
        "latitude": 3.8350,
        "longitude": 103.3450,
        "capacity": 500,
        "current_occupancy": 0,
        "contact_phone": "+60129876543",
        "address": "Jalan Bukit Pelindung, Kuantan, Pahang",
    },
    {
        "name": "SK Pandan Perdana (School Shelter)",
        "latitude": 3.8180,
        "longitude": 103.3350,
        "capacity": 300,
        "current_occupancy": 12,
        "contact_phone": "+60137654321",
        "address": "Jalan Pandan, Kuantan, Pahang",
    },
    {
        "name": "Masjid Al-Hidayah Relief Centre",
        "latitude": 3.8050,
        "longitude": 103.3180,
        "capacity": 200,
        "current_occupancy": 0,
        "contact_phone": "+60112233445",
        "address": "Jalan Masjid, Taman Gelora, Kuantan",
    },
    {
        "name": "Dewan Serbaguna Teluk Cempedak",
        "latitude": 3.8020,
        "longitude": 103.3750,
        "capacity": 400,
        "current_occupancy": 0,
        "contact_phone": "+60198877665",
        "address": "Persiaran Teluk Cempedak, Kuantan",
    },
]

# ── Sample Evacuation Routes ──────────────────────────────────────────────

EVACUATION_ROUTES = [
    {
        "name": "Route A: Town -> Bukit Pelindung",
        "start_lat": 3.8077,
        "start_lon": 103.3260,
        "end_lat": 3.8350,
        "end_lon": 103.3450,
        "waypoints": [
            {"lat": 3.8100, "lon": 103.3300},
            {"lat": 3.8150, "lon": 103.3350},
            {"lat": 3.8250, "lon": 103.3400},
        ],
        "distance_km": 4.2,
        "estimated_minutes": 15,
        "elevation_gain_m": 45.0,
        "status": "clear",
    },
    {
        "name": "Route B: Riverbank -> Teluk Cempedak",
        "start_lat": 3.8100,
        "start_lon": 103.3280,
        "end_lat": 3.8020,
        "end_lon": 103.3750,
        "waypoints": [
            {"lat": 3.8080, "lon": 103.3350},
            {"lat": 3.8050, "lon": 103.3500},
            {"lat": 3.8030, "lon": 103.3650},
        ],
        "distance_km": 6.1,
        "estimated_minutes": 22,
        "elevation_gain_m": 30.0,
        "status": "clear",
    },
    {
        "name": "Route C: Gelora -> Masjid Relief Centre",
        "start_lat": 3.7950,
        "start_lon": 103.3100,
        "end_lat": 3.8050,
        "end_lon": 103.3180,
        "waypoints": [
            {"lat": 3.7980, "lon": 103.3130},
            {"lat": 3.8020, "lon": 103.3160},
        ],
        "distance_km": 1.8,
        "estimated_minutes": 7,
        "elevation_gain_m": 12.0,
        "status": "clear",
    },
]


def main():
    print("-" * 60)
    print("  Seeding AI Risk Map data")
    print("-" * 60)

    print("\n[ZONES] Risk Zones:")
    for i, z in enumerate(RISK_ZONES, 1):
        try:
            rec = create_risk_zone(**z)
            icon = {"danger": "[DANGER]", "warning": "[WARNING]", "safe": "[SAFE]"}[rec["zone_type"]]
            print(f"  {icon} [{i}] {rec['name']} ({rec['zone_type']}) - score: {rec['risk_score']}")
        except Exception as e:
            print(f"  [X] [{i}] Failed: {z['name']}: {e}")

    print("\n[CENTRES] Evacuation Centres:")
    for i, c in enumerate(EVACUATION_CENTRES, 1):
        try:
            rec = create_evacuation_centre(**c)
            print(f"  [HOME] [{i}] {rec['name']} - capacity: {rec['capacity']}")
        except Exception as e:
            print(f"  [X] [{i}] Failed: {c['name']}: {e}")

    print("\n[ROUTES] Evacuation Routes:")
    for i, r in enumerate(EVACUATION_ROUTES, 1):
        try:
            rec = create_evacuation_route(**r)
            print(f"  [>>>] [{i}] {rec['name']} - {rec['distance_km']}km, ~{rec['estimated_minutes']}min")
        except Exception as e:
            print(f"  [X] [{i}] Failed: {r['name']}: {e}")

    print("\n" + "-" * 60)
    print("  Done! Risk map data seeded successfully.")
    print("-" * 60)


if __name__ == "__main__":
    main()
