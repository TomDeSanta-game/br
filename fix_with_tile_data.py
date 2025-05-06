
def fix_tilemaps_with_data():
    with open('temp_fix/full_backup.tscn', 'r') as f:
        original = f.read()
    with open('backups/House.tscn.backup', 'r') as f:
        clean_file = f.read()
    clean_file = clean_file.replace('format=4', 'format=3')
    tile_data_entries = []
    pos = 0
    while True:
        tile_data_start = original.find('tile_map_data = PackedByteArray(', pos)
        if tile_data_start == -1:
            break
        tile_data_end = original.find(')', tile_data_start + 30)
        if tile_data_end == -1:
            break
        tile_data = original[tile_data_start:tile_data_end+1]
        tile_data_entries.append(tile_data)
        pos = tile_data_end + 1
    print(f"Found {len(tile_data_entries)} tile_map_data entries")
    tilemaplayers = []
    start_idx = 0
    while True:
        node_start = original.find('[node name="TileMapLayer_', start_idx)
        if node_start == -1:
            break
        data_marker = original.find('tile_map_data', node_start)
        next_node = original.find('[node name=', node_start + 1)
        if next_node == -1:
            node_text = original[node_start:]
        else:
            if data_marker != -1 and data_marker < next_node:
                next_data_end = original.find(')', data_marker)
                if next_data_end != -1:
                    node_text = original[node_start:next_data_end+1]
                    next_node = original.find('[node name=', next_data_end)
                else:
                    node_text = original[node_start:next_node]
            else:
                node_text = original[node_start:next_node]
        node_text = node_text.replace('type="TileMapLayer"', 'type="TileMap"')
        tilemaplayers.append(node_text)
        start_idx = next_node if next_node != -1 else len(original)
    print(f"Found {len(tilemaplayers)} complete TileMapLayer nodes")
    final_content = clean_file
    existing_start = final_content.find('[node name="TileMapLayer_')
    if existing_start != -1:
        existing_end = final_content.find('[node name=', existing_start + 1)
        if existing_end != -1:
            final_content = final_content[:existing_start] + final_content[existing_end:]
    for layer in tilemaplayers:
        final_content += layer
    with open('Levels/House/House.tscn.complete', 'w') as f:
        f.write(final_content)
    print("Fixed file with complete tile data written to Levels/House/House.tscn.complete")
if __name__ == "__main__":
    fix_tilemaps_with_data()