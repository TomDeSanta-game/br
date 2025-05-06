
def extract_all_tilemaps():
    with open('backups/House/House.tscn.backup', 'r') as f:
        house_backup = f.read()
    with open('backups/House.tscn.backup', 'r') as f:
        root_backup = f.read()
    with open('Levels/House/House.tscn.backup.final', 'r') as f:
        working_file = f.read()
    header_end = working_file.find('[node name="House"')
    working_header = working_file[:header_end]
    all_tilemaps = []
    pos = 0
    while True:
        tile_start = house_backup.find('[node name="TileMapLayer_', pos)
        if tile_start == -1:
            tile_start = house_backup.find('[node name="TileMap', pos)
            if tile_start == -1:
                break
        next_node = house_backup.find('[node name=', tile_start + 10)
        if next_node == -1:
            node_data = house_backup[tile_start:]
        else:
            node_data = house_backup[tile_start:next_node]
        node_data = node_data.replace('type="TileMapLayer"', 'type="TileMap"')
        all_tilemaps.append(node_data)
        if next_node == -1:
            break
        pos = next_node
    pos = 0
    while True:
        tile_start = root_backup.find('[node name="TileMapLayer_', pos)
        if tile_start == -1:
            tile_start = root_backup.find('[node name="TileMap', pos)
            if tile_start == -1:
                break
        next_node = root_backup.find('[node name=', tile_start + 10)
        if next_node == -1:
            node_data = root_backup[tile_start:]
        else:
            node_data = root_backup[tile_start:next_node]
        node_data = node_data.replace('type="TileMapLayer"', 'type="TileMap"')
        node_name_end = node_data.find('"', node_data.find('name="') + 6)
        node_name = node_data[node_data.find('name="') + 6:node_name_end]
        found = False
        for existing in all_tilemaps:
            if node_name in existing:
                found = True
                break
        if not found:
            all_tilemaps.append(node_data)
        if next_node == -1:
            break
        pos = next_node
    print(f"Found {len(all_tilemaps)} unique TileMap nodes")
    main_nodes = []
    pos = 0
    main_nodes_text = ""
    while True:
        node_start = working_file.find('[node name=', pos)
        if node_start == -1:
            break
        next_node = working_file.find('[node name=', node_start + 10)
        if next_node == -1:
            node_data = working_file[node_start:]
        else:
            node_data = working_file[node_start:next_node]
        if 'type="TileMap"' not in node_data and 'TileMap' not in node_data:
            main_nodes.append(node_data)
            main_nodes_text += node_data
        if next_node == -1:
            break
        pos = next_node
    complete_content = working_header
    house_node_start = working_file.find('[node name="House"')
    house_node_end = working_file.find('[node name=', house_node_start + 10)
    if house_node_end == -1:
        house_node = working_file[house_node_start:]
    else:
        house_node = working_file[house_node_start:house_node_end]
    complete_content += house_node
    for tile in all_tilemaps:
        complete_content += tile
    pos = header_end
    while True:
        node_start = working_file.find('[node name=', pos)
        if node_start == -1:
            break
        if working_file[node_start:node_start+16] == '[node name="House"':
            pos = node_start + 10
            continue
        if 'type="TileMap"' in working_file[node_start:node_start+100] or 'TileMap' in working_file[node_start:node_start+100]:
            pos = node_start + 10
            continue
        next_node = working_file.find('[node name=', node_start + 10)
        if next_node == -1:
            node_data = working_file[node_start:]
            complete_content += node_data
            break
        else:
            node_data = working_file[node_start:next_node]
            complete_content += node_data
            pos = next_node
    with open('Levels/House/House.tscn.complete_layers', 'w') as f:
        f.write(complete_content)
    print("Created comprehensive file with all layers at Levels/House/House.tscn.complete_layers")
if __name__ == "__main__":
    extract_all_tilemaps()