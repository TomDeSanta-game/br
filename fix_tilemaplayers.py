#!/usr/bin/env python3

def fix_tilemaps():
    # Read the original backup with TileMapLayer data
    with open('temp_fix/original.tscn', 'r') as f:
        original = f.read()
    
    # Read the current working file
    with open('temp_fix/current.tscn', 'r') as f:
        current = f.read()
    
    # Fix format if needed (ensure format=3)
    if 'format=4' in current:
        current = current.replace('format=4', 'format=3')
        print("Fixed format version from 4 to 3")
    
    # Find all TileMapLayer nodes in the original file
    tilemaplayers = []
    start_idx = 0
    
    while True:
        # Look for the TileMapLayer node pattern
        node_start = original.find('[node name="TileMapLayer_', start_idx)
        if node_start == -1:
            break
            
        # Find the end of this node definition (next node or end of file)
        next_node = original.find('[node name=', node_start + 1)
        if next_node == -1:
            # Last node in file
            node_data = original[node_start:]
        else:
            node_data = original[node_start:next_node]
            
        # Collect this TileMapLayer node data
        tilemaplayers.append(node_data)
        start_idx = next_node if next_node != -1 else len(original)
    
    print(f"Found {len(tilemaplayers)} TileMapLayer nodes in original file")
    
    # Now find where to insert these in the current file
    # Look for MainTileMap which should be followed by our TileMapLayers
    maintilemap_end = current.find('[node name="MainTileMap"')
    if maintilemap_end == -1:
        print("Could not find MainTileMap in current file")
        return
    
    # Find the end of MainTileMap definition
    next_node_after_main = current.find('[node name=', maintilemap_end + 1)
    if next_node_after_main == -1:
        print("Could not find end of MainTileMap node")
        return
    
    # Insert our TileMapLayer nodes right after MainTileMap
    new_content = current[:next_node_after_main]
    
    # Add all our TileMapLayer nodes
    for layer in tilemaplayers:
        # Replace type="TileMapLayer" with type="TileMap" for compatibility
        layer = layer.replace('type="TileMapLayer"', 'type="TileMap"')
        new_content += layer
    
    # Add the rest of the file
    new_content += current[next_node_after_main:]
    
    # Write the new file
    with open('Levels/House/House.tscn.tilemaplayer', 'w') as f:
        f.write(new_content)
    
    print("Fixed file written to Levels/House/House.tscn.tilemaplayer")

if __name__ == "__main__":
    fix_tilemaps() 