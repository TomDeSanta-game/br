
def extract_tile_data():
    with open('backups/House/House.tscn.backup', 'r') as f:
        backup_content = f.read()
    with open('Levels/House/House.tscn.backup.final', 'r') as f:
        working_content = f.read()
    tilemap_nodes = []
    data_blocks = []
    start_idx = 0
    while True:
        node_start = backup_content.find('[node name="TileMapLayer_', start_idx)
        if node_start == -1:
            break
        node_end = backup_content.find(']', node_start)
        if node_end == -1:
            break
        node_def = backup_content[node_start:node_end+1]
        node_def = node_def.replace('type="TileMapLayer"', 'type="TileMap"')
        tilemap_nodes.append(node_def)
        start_idx = node_end + 1
    start_idx = 0
    while True:
        data_start = backup_content.find('tile_map_data = PackedByteArray("', start_idx)
        if data_start == -1:
            break
        data_end = backup_content.find('")', data_start)
        if data_end == -1:
            break
        data_block = backup_content[data_start:data_end+2]
        data_blocks.append(data_block)
        start_idx = data_end + 2
    print(f"Found {len(tilemap_nodes)} TileMapLayer nodes")
    print(f"Found {len(data_blocks)} tile_map_data blocks")
    if len(tilemap_nodes) != len(data_blocks):
        print("Warning: Number of nodes and data blocks doesn't match")
    maintilemap_pos = working_content.find('[node name="MainTileMap"')
    if maintilemap_pos == -1:
        print("Error: Could not find MainTileMap node")
        return
    next_node_pos = working_content.find('[node name=', maintilemap_pos + 10)
    if next_node_pos == -1:
        print("Error: Could not find node after MainTileMap")
        return
    new_content = working_content[:next_node_pos]
    for i in range(min(len(tilemap_nodes), len(data_blocks))):
        new_content += tilemap_nodes[i] + "\n" + data_blocks[i] + "\n\n"
    new_content += working_content[next_node_pos:]
    with open('Levels/House/House.tscn.tile_fixed', 'w') as f:
        f.write(new_content)
    print("Created new file with tile data at Levels/House/House.tscn.tile_fixed")
if __name__ == "__main__":
    extract_tile_data()