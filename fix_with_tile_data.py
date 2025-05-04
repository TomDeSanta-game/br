#!/usr/bin/env python3

def fix_tilemaps_with_data():
    # Read the original backup with full TileMapLayer data
    with open('temp_fix/full_backup.tscn', 'r') as f:
        original = f.read()
    
    # Get a clean working file
    with open('backups/House.tscn.backup', 'r') as f:
        clean_file = f.read()
    
    # Fix format if needed (ensure format=3)
    clean_file = clean_file.replace('format=4', 'format=3')
    
    # Extract all tile_map_data from the original file
    tile_data_entries = []
    pos = 0
    while True:
        # Find the next tile_map_data entry
        tile_data_start = original.find('tile_map_data = PackedByteArray(', pos)
        if tile_data_start == -1:
            break
        
        # Find the closing parenthesis for this data
        tile_data_end = original.find(')', tile_data_start + 30)
        if tile_data_end == -1:
            break
        
        # Extract the complete tile_map_data entry
        tile_data = original[tile_data_start:tile_data_end+1]
        tile_data_entries.append(tile_data)
        
        # Move past this entry
        pos = tile_data_end + 1
    
    print(f"Found {len(tile_data_entries)} tile_map_data entries")
    
    # Now find all TileMapLayer nodes
    tilemaplayers = []
    start_idx = 0
    
    while True:
        # Look for the TileMapLayer node pattern
        node_start = original.find('[node name="TileMapLayer_', start_idx)
        if node_start == -1:
            break
            
        # Find the end of this node definition (next node or the marker for tile data)
        data_marker = original.find('tile_map_data', node_start)
        next_node = original.find('[node name=', node_start + 1)
        
        if next_node == -1:
            # Last node in file
            node_text = original[node_start:]
        else:
            if data_marker != -1 and data_marker < next_node:
                # Include the tile data in this node
                next_data_end = original.find(')', data_marker)
                if next_data_end != -1:
                    node_text = original[node_start:next_data_end+1]
                    next_node = original.find('[node name=', next_data_end)
                else:
                    node_text = original[node_start:next_node]
            else:
                node_text = original[node_start:next_node]
        
        # Fix the node type from TileMapLayer to TileMap for compatibility
        node_text = node_text.replace('type="TileMapLayer"', 'type="TileMap"')
        
        # Collect this complete TileMapLayer node data with its tile data
        tilemaplayers.append(node_text)
        
        start_idx = next_node if next_node != -1 else len(original)
    
    print(f"Found {len(tilemaplayers)} complete TileMapLayer nodes")
    
    # Find where to insert the TileMapLayer nodes in the clean file
    # Look for the end of file since we'll add them at the end
    final_content = clean_file
    
    # First cut out any existing TileMapLayer nodes to avoid duplicates
    existing_start = final_content.find('[node name="TileMapLayer_')
    if existing_start != -1:
        existing_end = final_content.find('[node name=', existing_start + 1)
        if existing_end != -1:
            # Remove the existing TileMapLayer nodes
            final_content = final_content[:existing_start] + final_content[existing_end:]
    
    # Now add our complete TileMapLayer nodes at the end
    for layer in tilemaplayers:
        final_content += layer
    
    # Write the new file
    with open('Levels/House/House.tscn.complete', 'w') as f:
        f.write(final_content)
    
    print("Fixed file with complete tile data written to Levels/House/House.tscn.complete")

if __name__ == "__main__":
    fix_tilemaps_with_data() 