#!/usr/bin/env python3

def extract_working_tilemaps():
    # Read the working original version with basic structure
    with open('Levels/House/House.tscn.backup.final', 'r') as f:
        working_file = f.read()
    
    # Read the version with good tile data
    with open('backups/House/House.tscn.current', 'r') as f:
        tile_data_file = f.read()
    
    # Find all the TileMap nodes in the tile_data_file that have layer_0/tile_data
    tilemap_nodes = []
    start_pos = 0
    
    while True:
        # Find the next TileMap node
        node_start = tile_data_file.find('[node name="TileMapLayer_', start_pos)
        if node_start == -1:
            node_start = tile_data_file.find('[node name="TileMap', start_pos)
            if node_start == -1:
                break
        
        # Find the end of this node (next node)
        next_node = tile_data_file.find('[node name=', node_start + 10)
        
        # Extract the node definition
        if next_node == -1:
            node_text = tile_data_file[node_start:]
        else:
            node_text = tile_data_file[node_start:next_node]
        
        # Only include if it has tile data
        if 'layer_0/tile_data' in node_text:
            # Fix the node type
            node_text = node_text.replace('type="TileMapLayer"', 'type="TileMap"')
            tilemap_nodes.append(node_text)
        
        if next_node == -1:
            break
        
        start_pos = next_node
    
    print(f"Found {len(tilemap_nodes)} TileMap nodes with layer_0/tile_data")
    
    # Now locate where we should insert these in the working file
    # We'll add them right after MainTileMap
    main_node = working_file.find('[node name="MainTileMap"')
    if main_node == -1:
        print("Error: Could not find MainTileMap in working file")
        return
    
    # Find the next node after MainTileMap
    next_after_main = working_file.find('[node name=', main_node + 10)
    if next_after_main == -1:
        print("Error: Could not find node after MainTileMap")
        return
    
    # Combine the pieces
    new_content = working_file[:next_after_main]
    
    # Add our TileMap nodes
    for node in tilemap_nodes:
        new_content += node
    
    # Add the rest of the file
    new_content += working_file[next_after_main:]
    
    # Write the new file
    with open('Levels/House/House.tscn.just_tilemaps', 'w') as f:
        f.write(new_content)
    
    print("Created file with just the TileMap nodes at Levels/House/House.tscn.just_tilemaps")

if __name__ == "__main__":
    extract_working_tilemaps() 