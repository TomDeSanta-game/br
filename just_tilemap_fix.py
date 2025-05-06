
def extract_working_tilemaps():
    with open('Levels/House/House.tscn.backup.final', 'r') as f:
        working_file = f.read()
    with open('backups/House/House.tscn.current', 'r') as f:
        tile_data_file = f.read()
    tilemap_nodes = []
    start_pos = 0
    while True:
        node_start = tile_data_file.find('[node name="TileMapLayer_', start_pos)
        if node_start == -1:
            node_start = tile_data_file.find('[node name="TileMap', start_pos)
            if node_start == -1:
                break
        next_node = tile_data_file.find('[node name=', node_start + 10)
        if next_node == -1:
            node_text = tile_data_file[node_start:]
        else:
            node_text = tile_data_file[node_start:next_node]
        if 'layer_0/tile_data' in node_text:
            node_text = node_text.replace('type="TileMapLayer"', 'type="TileMap"')
            tilemap_nodes.append(node_text)
        if next_node == -1:
            break
        start_pos = next_node
    print(f"Found {len(tilemap_nodes)} TileMap nodes with layer_0/tile_data")
    main_node = working_file.find('[node name="MainTileMap"')
    if main_node == -1:
        print("Error: Could not find MainTileMap in working file")
        return
    next_after_main = working_file.find('[node name=', main_node + 10)
    if next_after_main == -1:
        print("Error: Could not find node after MainTileMap")
        return
    new_content = working_file[:next_after_main]
    for node in tilemap_nodes:
        new_content += node
    new_content += working_file[next_after_main:]
    with open('Levels/House/House.tscn.just_tilemaps', 'w') as f:
        f.write(new_content)
    print("Created file with just the TileMap nodes at Levels/House/House.tscn.just_tilemaps")
if __name__ == "__main__":
    extract_working_tilemaps()