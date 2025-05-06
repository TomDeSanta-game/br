
def fix_tilemaps():
    with open('temp_fix/original.tscn', 'r') as f:
        original = f.read()
    with open('temp_fix/current.tscn', 'r') as f:
        current = f.read()
    if 'format=4' in current:
        current = current.replace('format=4', 'format=3')
        print("Fixed format version from 4 to 3")
    tilemaplayers = []
    start_idx = 0
    while True:
        node_start = original.find('[node name="TileMapLayer_', start_idx)
        if node_start == -1:
            break
        next_node = original.find('[node name=', node_start + 1)
        if next_node == -1:
            node_data = original[node_start:]
        else:
            node_data = original[node_start:next_node]
        tilemaplayers.append(node_data)
        start_idx = next_node if next_node != -1 else len(original)
    print(f"Found {len(tilemaplayers)} TileMapLayer nodes in original file")
    maintilemap_end = current.find('[node name="MainTileMap"')
    if maintilemap_end == -1:
        print("Could not find MainTileMap in current file")
        return
    next_node_after_main = current.find('[node name=', maintilemap_end + 1)
    if next_node_after_main == -1:
        print("Could not find end of MainTileMap node")
        return
    new_content = current[:next_node_after_main]
    for layer in tilemaplayers:
        layer = layer.replace('type="TileMapLayer"', 'type="TileMap"')
        new_content += layer
    new_content += current[next_node_after_main:]
    with open('Levels/House/House.tscn.tilemaplayer', 'w') as f:
        f.write(new_content)
    print("Fixed file written to Levels/House/House.tscn.tilemaplayer")
if __name__ == "__main__":
    fix_tilemaps()