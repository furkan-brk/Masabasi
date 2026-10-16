#!/usr/bin/env python3
"""
BGG enrichment script using api.geekdo.com/api/geekitems (no auth required).
Hardcoded BGG IDs for all 111 club games — bypasses blocked XML API.

Usage (Windows host, psycopg2-binary installed):
  python bgg_seed.py

Connects to localhost:5434 by default (compose DB port).
"""

import os
import sys
import time
import requests
import psycopg2

# Force UTF-8 output on Windows (avoids cp1252 UnicodeEncodeError on Turkish chars)
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_PORT = int(os.environ.get("DB_PORT", "5434"))
DB_NAME = os.environ.get("DB_NAME", "masabasi")
DB_USER = os.environ.get("DB_USER", "masabasi")
DB_PASS = os.environ.get("DB_PASS", "masabasi_dev_pw")

# BGG ID map — all 111 club games
# Format: "DB title": BGG_ID
BGG_IDS = {
    "7 Wonders":                                          68448,
    "7 Wonders Architects":                               346703,    # 7 Wonders: Architects
    "7 Wonders Duel":                                     173346,
    "Agricola":                                           31260,
    "Amiral Battı":                                       2425,      # Battleship
    "Anlatamaz ki!":                                      0,         # Turkish, BGG unknown
    "Arnak Harabeleri":                                   312484,    # Lost Ruins of Arnak (base game)
    "Astro Drive":                                        260335,    # Astro Drive
    "Azul":                                               230802,
    "Azul: Master Chocolatier":                           363247,    # Azul: Master Chocolatier
    "Bang":                                               3955,
    "Banned Words XL":                                    0,
    "Barrage":                                            251247,
    "Bay Böcek Firarda":                                  0,
    "Ben Daha Önce Hiç":                                  0,
    "Biblios":                                            34219,     # Biblios
    "Bomba":                                              0,
    "Carcassonne":                                        822,
    "Cascadia":                                           295947,
    "Cash n Guns":                                        155362,    # Ca$h 'n Guns Second Edition
    "Casus Belli":                                        10630,     # Memoir '44
    "Catan":                                              13,
    "Century: Golem Edition":                             232832,
    "Citadelles":                                         478,       # Citadels
    "Coatl":                                              274841,    # Cóatl
    "Codenames":                                          178900,
    "Cryptid":                                            246784,
    "Çatlak Yumurta":                                     0,
    "Çek Bir Kart":                                       0,
    "Çiziver":                                            0,
    "Darkective":                                         0,         # ID unknown (254640 wrong)
    "Dedektif":                                           0,
    "Deep Sea Adventure":                                 169654,
    "Destek Köstek!":                                     0,
    "Dice Forge":                                         194594,
    "Direniş":                                            128882,    # The Resistance
    "Dixit":                                              39856,
    "Dost Kazığı":                                        0,
    "Ejder Avcıları":                                     0,
    "Entrika":                                            131357,    # Coup
    "Epik Büyü Savaşları: Kurukafa Dağında Duello":       112686,    # Epic Spell Wars 1: Duel at Mt. Skullzfyre
    "Epik Büyü Savaşları: Ölüm Şatosunda Kapışma":        173200,    # Epic Spell Wars 2: Rumble at Castle Tentakill
    "Fenomen Kim":                                        0,
    "Forbidden":                                          136063,    # Forbidden Desert
    "Frog Balance Game":                                  0,
    "Gelişine":                                           0,
    "Gulyabani":                                          25821,     # Ultimate Werewolf
    "Harekat: Normandiya":                                10630,     # Memoir '44
    "İhtilâl":                                            12333,     # Twilight Struggle
    "İnkılap":                                            28720,     # Brass Lancashire
    "İstanbul Big Box":                                   148949,    # Istanbul
    "İye":                                                119632,    # IOTA card game
    "İz Peşinde":                                         223321,    # Detective: A Modern Crime
    "Jungle Speed":                                       8098,
    "Kadim Yolculuk":                                     129437,    # Legendary: A Marvel Deck Building Game
    "Katerogi X":                                         0,
    "Kayıp Diyarlar":                                     312484,    # Lost Ruins of Arnak (base game)
    "Kelime Oyunu":                                       0,
    "Keşif: Gezegen 9 Görevi":                            258779,    # Planet Unknown
    "King of Tokyo":                                      70323,
    "Kingdomino":                                         204583,
    "Komplo":                                             131357,    # Coup
    "Korku Kapanı":                                       113294,    # Escape: The Curse of the Temple
    "Kuzey Kaşifleri":                                    263918,    # Cartographers
    "Lanetli Ada":                                        65244,     # Forbidden Island
    "Lichterfest":                                        160851,    # Lanterns: The Harvest Festival
    "Lords of Waterdeep":                                 110327,
    "Machi Koro":                                         143884,
    "Makara":                                             0,
    "Marvel Champions":                                   285774,
    "Metropol":                                           25568,     # Metropolys (city tower building game)
    "MicroMacro: Crime City":                             318977,
    "Monopoly":                                           1406,
    "Monopoly Deal":                                      40398,
    "Monopoly Duello":                                    0,
    "Munchkin":                                           1927,
    "Munchkin Cthulhu":                                   25071,     # Munchkin Cthulhu
    "Munchkin Zombies":                                   86955,     # Munchkin Zombies
    "Otokrat":                                            0,
    "Pandemic":                                           30549,
    "Patika":                                             338628,    # Trails (Keymaster Games 2021)
    "Pictionary Air":                                     272889,    # Pictionary Air
    "Puerto Rico":                                        3076,
    "Risk":                                               181,
    "Sagrada":                                            199561,
    "Sahtekar":                                           131357,    # Coup
    "Satranç":                                            171,       # Chess
    "Sinners":                                            0,         # ID unknown (338716 wrong)
    "Smash Up":                                           122522,
    "Splendor":                                           148228,
    "Splendor Duel":                                      364073,
    "Star Realms":                                        147020,
    "Sub Terra":                                          204472,    # Sub Terra
    "Suç Günlükleri":                                     223321,    # Chronicles of Crime
    "Tabu":                                               1111,      # Taboo
    "Tabu XL":                                            1111,      # Taboo (same cover)
    "Terraforming Mars":                                  167791,
    "Ticket to Ride: Asia":                               106637,    # TtR Map Collection 1: Asia + Legendary Asia
    "Ticket to Ride: Europe":                             14996,
    "Truva":                                              0,
    "Tzolk'in: The Mayan Calendar":                       126163,
    "Uno":                                                2223,
    "Uno Flip":                                           271460,    # UNO Flip!
    "Uno Pokemon":                                        0,
    "Uykucu Kraliçeler":                                  17053,     # Sleeping Queens
    "Vampir Köylü":                                       147949,    # One Night Ultimate Werewolf
    "Villainous":                                         256382,
    "Viticulture":                                        128621,
    "Wingspan":                                           266192,
    "Wyrmspan":                                           410201,
    "Yamalı Yorgan":                                      163412,    # Patchwork
}

GEEKDO_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept": "application/json",
    "Referer": "https://boardgamegeek.com/",
}

SESSION = requests.Session()
SESSION.headers.update(GEEKDO_HEADERS)


def fetch_bgg_images(bgg_id: int) -> dict:
    """Fetch cover + thumb from api.geekdo.com/api/geekitems with retry."""
    url = f"https://api.geekdo.com/api/geekitems?objectid={bgg_id}&objecttype=thing&pageid=1"
    for attempt in range(3):
        try:
            r = SESSION.get(url, timeout=25)
            r.raise_for_status()
            break
        except Exception as e:
            if attempt == 2:
                raise
            print(f"  retry {attempt+1}: {e}")
            time.sleep(3)
    d = r.json()
    images = d.get("item", {}).get("images", {})
    # prefer 'original', fall back to 'square200' then 'thumb'
    cover = (
        images.get("original") or
        images.get("square200") or
        images.get("tallthumb") or
        images.get("thumb") or
        ""
    )
    return {
        "cover_image_url": cover,
        "name_check": d.get("item", {}).get("primaryname", {}).get("name", ""),
    }


def main():
    conn = psycopg2.connect(
        host=DB_HOST, port=DB_PORT, dbname=DB_NAME,
        user=DB_USER, password=DB_PASS,
    )
    cur = conn.cursor()

    cur.execute("""
        SELECT id, title, description, duration_min
        FROM games
        WHERE cover_image_url IS NULL OR cover_image_url = ''
        ORDER BY title
    """)
    games = cur.fetchall()
    print(f"Enriching {len(games)} games without covers")

    unmatched = []
    no_id = []
    enriched = 0

    for i, (gid, title, desc, dur) in enumerate(games):
        bgg_id = BGG_IDS.get(title)
        print(f"[{i+1}/{len(games)}] {title} (BGG ID: {bgg_id})")

        if not bgg_id:
            print("  SKIP: no BGG ID in map")
            no_id.append(title)
            continue

        try:
            info = fetch_bgg_images(bgg_id)
            cover = info["cover_image_url"]
            bgg_name = info["name_check"]
            if not cover:
                raise ValueError(f"no image returned (BGG name: {bgg_name!r})")

            print(f"  BGG name: {bgg_name!r} | cover: {cover[:60]}...")
            cur.execute("""
                UPDATE games SET cover_image_url = %s, updated_at = NOW()
                WHERE id = %s
            """, (cover, gid))
            conn.commit()
            enriched += 1
        except Exception as e:
            conn.rollback()
            print(f"  SKIP: {e}")
            unmatched.append(title)

        time.sleep(0.5)   # polite delay

    print(f"\n=== DONE: enriched {enriched}/{len(games)} ===")
    if no_id:
        print(f"\nNo BGG ID mapped ({len(no_id)}):")
        for t in no_id:
            print(f"  - {t!r}")
    if unmatched:
        print(f"\nFailed fetch ({len(unmatched)}):")
        for t in unmatched:
            print(f"  - {t!r}")

    cur.close()
    conn.close()


if __name__ == "__main__":
    main()
