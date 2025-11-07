#!/usr/bin/env python

import json
from collections import namedtuple
from urllib import request

DATA_ROOT = "https://raw.githubusercontent.com/BitCraftToolBox/BitCraft_GameData/refs/heads/sats-json/static/"

def gen_resources():
    data = json.load(request.urlopen(DATA_ROOT + 'resource_desc.json'))
    Type = namedtuple('Type', ('tier', 'id', 'name'))

    BLOCKED_TAGS = ['Bones', 'Depleted Resource', 'Door', 'Energy Font', 'Fruit', 'Insects', 'Note', 'Obstacle',
            'Dungeon Resource', 'Dungeon Obstacle', 'Enemy Spawner']
    BLOCKED_IDS = [763946195]  # TEST Birdspawn

    data = [Type(
        t['tier'] if t['tier'] > 0 else 0,
        t['id'],
        t['name'].strip(),
    ) for t in data if not ('Interior' in t['name'] or t['tag'] in BLOCKED_TAGS or t['id'] in BLOCKED_IDS)]
    resources = sorted(data, key=lambda t: (t.tier * -1, t.id))
    return resources

def gen_enemies():
    data = json.load(request.urlopen(DATA_ROOT + 'enemy_desc.json'))
    Type = namedtuple('Type', ('id', 'name'))

    BLOCKED_TAGS = []
    BLOCKED_IDS = [1]  # Practice Dummy

    data = [Type(
        t['enemy_type'],
        t['name'].strip(),
    ) for t in data if not (t['tag'] in BLOCKED_TAGS or t['enemy_type'] in BLOCKED_IDS)]
    enemies = sorted(data, key=lambda t: t.id)
    return enemies

def main():
    resources = gen_resources()
    enemies = gen_enemies()

    with open('config.json', 'w') as f:
        f.writelines([
            '{\n',
            '  "db": { "region": 2 },\n',
            '  "server": { "socket_addr": "0.0.0.0:3000" },\n',
            '  "resources": [\n',
            ',\n'.join(f'    {{ "id": {t.id:>10}, "name": "{t.name}" }}' for t in resources),
            '\n  ],\n'
            '  "enemies": [\n',
            ',\n'.join(f'    {{ "id": {t.id:>2}, "name": "{t.name}" }}' for t in enemies),
            '\n  ]\n'
            '}\n'
        ])

if __name__ == "__main__":
    main()

