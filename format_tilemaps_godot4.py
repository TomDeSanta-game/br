
def convert_to_godot4_format():
    with open('backups/House/House.tscn.backup', 'r') as f:
        backup_content = f.read()
    with open('Levels/House/House.tscn.backup.final', 'r') as f:
        working_file = f.read()
    header_end = working_file.find('[node name="House"')
    if header_end == -1:
        print("Error: Could not find House node in working file")
        return
    working_header = working_file[:header_end]
    tile_data_blocks = []
    pos = 0
    while True:
        data_start = backup_content.find('tile_map_data = PackedByteArray(', pos)
        if data_start == -1:
            break
        data_end = backup_content.find(')', data_start)
        if data_end == -1:
            break
        data_block = backup_content[data_start:data_end+1]
        tile_data_blocks.append(data_block)
        pos = data_end + 1
    print(f"Found {len(tile_data_blocks)} tile_map_data blocks")
    tilemaps = []
    pos = 0
    while True:
        node_start = backup_content.find('[node name="TileMapLayer_', pos)
        if node_start == -1:
            break
        node_name_start = node_start + 12
        node_name_end = backup_content.find('"', node_name_start)
        node_name = backup_content[node_name_start:node_name_end]
        node_end = backup_content.find(']', node_start)
        node_def = backup_content[node_start:node_end+1]
        node_def = node_def.replace('type="TileMapLayer"', 'type="TileMap"')
        tilemaps.append((node_name, node_def))
        pos = node_end + 1
    print(f"Found {len(tilemaps)} TileMapLayer nodes")
    main_tilemap_start = working_file.find('[node name="MainTileMap"')
    if main_tilemap_start == -1:
        print("Warning: Could not find MainTileMap in working file")
        main_tilemap = ""
    else:
        main_tilemap_end = working_file.find('[node name=', main_tilemap_start + 10)
        if main_tilemap_end == -1:
            main_tilemap = working_file[main_tilemap_start:]
        else:
            main_tilemap = working_file[main_tilemap_start:main_tilemap_end]
    new_content = working_header
    house_node_start = working_file.find('[node name="House"')
    house_node_end = working_file.find('[node name=', house_node_start + 10)
    if house_node_end == -1:
        house_node = working_file[house_node_start:]
    else:
        house_node = working_file[house_node_start:house_node_end]
    new_content += house_node
    if main_tilemap:
        new_content += main_tilemap
    for i, (name, node_def) in enumerate(tilemaps):
        new_content += node_def + "\n"
        if i < len(tile_data_blocks):
            godot4_format = tile_data_blocks[i].replace('tile_map_data', 'layer_0/tile_data')
            new_content += godot4_format + "\n\n"
        else:
            print(f"Warning: No tile data for TileMap {name}")
    pos = header_end
    while True:
        node_start = working_file.find('[node name=', pos)
        if node_start == -1:
            break
        if working_file[node_start:node_start+16] == '[node name="House"' or \
           working_file[node_start:node_start+22] == '[node name="MainTileMap"':
            pos = node_start + 10
            continue
        if 'TileMap' in working_file[node_start:node_start+100]:
            pos = node_start + 10
            continue
        next_node = working_file.find('[node name=', node_start + 10)
        if next_node == -1:
            node_data = working_file[node_start:]
            new_content += node_data
            break
        else:
            node_data = working_file[node_start:next_node]
            new_content += node_data
            pos = next_node
    with open('Levels/House/House.tscn.godot4', 'w') as f:
        f.write(new_content)
    print("Created Godot 4 formatted file at Levels/House/House.tscn.godot4")
if __name__ == "__main__":
    convert_to_godot4_format()