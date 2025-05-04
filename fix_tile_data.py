#!/usr/bin/env python3

def extract_tile_data():
    # Read the backup file with tile data
    with open('backups/House/House.tscn.backup', 'r') as f:
        backup_content = f.read()
    
    # Read the file that works but is missing tile data
    with open('Levels/House/House.tscn.backup.final', 'r') as f:
        working_content = f.read()
    
    # Extract all TileMapLayer nodes with their complete data from the backup
    tilemap_nodes = []
    data_blocks = []
    
    # First find all the node definitions
    start_idx = 0
    while True:
        # Find the next TileMapLayer node
        node_start = backup_content.find('[node name="TileMapLayer_', start_idx)
        if node_start == -1:
            break
        
        # Find the end of this node name definition
        node_end = backup_content.find(']', node_start)
        if node_end == -1:
            break
        
        # Extract the node definition
        node_def = backup_content[node_start:node_end+1]
        # Change to TileMap for compatibility
        node_def = node_def.replace('type="TileMapLayer"', 'type="TileMap"')
        tilemap_nodes.append(node_def)
        
        # Move to the next node
        start_idx = node_end + 1
    
    # Now extract all tile_map_data blocks
    start_idx = 0
    while True:
        # Find the next tile_map_data definition
        data_start = backup_content.find('tile_map_data = PackedByteArray("', start_idx)
        if data_start == -1:
            break
        
        # Find the end of this data block
        data_end = backup_content.find('")', data_start)
        if data_end == -1:
            break
        
        # Extract the data block
        data_block = backup_content[data_start:data_end+2]
        data_blocks.append(data_block)
        
        # Move to the next data block
        start_idx = data_end + 2
    
    print(f"Found {len(tilemap_nodes)} TileMapLayer nodes")
    print(f"Found {len(data_blocks)} tile_map_data blocks")
    
    # Make sure we have the same number of nodes and data blocks
    if len(tilemap_nodes) != len(data_blocks):
        print("Warning: Number of nodes and data blocks doesn't match")
    
    # Find where to insert the new TileMap nodes in the working file
    # Look for the MainTileMap node, which should be followed by the TileMapLayers
    maintilemap_pos = working_content.find('[node name="MainTileMap"')
    if maintilemap_pos == -1:
        print("Error: Could not find MainTileMap node")
        return
    
    # Find the node that follows MainTileMap
    next_node_pos = working_content.find('[node name=', maintilemap_pos + 10)
    if next_node_pos == -1:
        print("Error: Could not find node after MainTileMap")
        return
    
    # Create the new content with TileMapLayer nodes inserted
    new_content = working_content[:next_node_pos]
    
    # Insert each TileMapLayer node with its data
    for i in range(min(len(tilemap_nodes), len(data_blocks))):
        new_content += tilemap_nodes[i] + "\n" + data_blocks[i] + "\n\n"
    
    # Add the rest of the working file
    new_content += working_content[next_node_pos:]
    
    # Write the new combined file
    with open('Levels/House/House.tscn.tile_fixed', 'w') as f:
        f.write(new_content)
    
    print("Created new file with tile data at Levels/House/House.tscn.tile_fixed")

if __name__ == "__main__":
    extract_tile_data() 