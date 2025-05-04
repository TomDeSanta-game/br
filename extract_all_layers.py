#!/usr/bin/env python3

def extract_all_tilemaps():
    # Read all the versions we have to combine the best parts
    with open('backups/House/House.tscn.backup', 'r') as f:
        house_backup = f.read()
    
    with open('backups/House.tscn.backup', 'r') as f:
        root_backup = f.read()
    
    with open('Levels/House/House.tscn.backup.final', 'r') as f:
        working_file = f.read()
    
    # Get the working header which is compatible with Godot 4
    header_end = working_file.find('[node name="House"')
    working_header = working_file[:header_end]
    
    # Extract all TileMap nodes with their data from both backup sources
    all_tilemaps = []
    
    # First extract from house_backup
    pos = 0
    while True:
        # Find TileMap nodes (both regular TileMaps and TileMapLayers)
        tile_start = house_backup.find('[node name="TileMapLayer_', pos)
        if tile_start == -1:
            tile_start = house_backup.find('[node name="TileMap', pos)
            if tile_start == -1:
                break
        
        # Find the next node
        next_node = house_backup.find('[node name=', tile_start + 10)
        
        # Extract the complete node with data
        if next_node == -1:
            node_data = house_backup[tile_start:]
        else:
            node_data = house_backup[tile_start:next_node]
        
        # Fix the type if needed
        node_data = node_data.replace('type="TileMapLayer"', 'type="TileMap"')
        
        # Add to our collection
        all_tilemaps.append(node_data)
        
        if next_node == -1:
            break
        pos = next_node
    
    # Now extract from root_backup
    pos = 0
    while True:
        # Find TileMap nodes (both regular TileMaps and TileMapLayers)
        tile_start = root_backup.find('[node name="TileMapLayer_', pos)
        if tile_start == -1:
            tile_start = root_backup.find('[node name="TileMap', pos)
            if tile_start == -1:
                break
        
        # Find the next node
        next_node = root_backup.find('[node name=', tile_start + 10)
        
        # Extract the complete node with data
        if next_node == -1:
            node_data = root_backup[tile_start:]
        else:
            node_data = root_backup[tile_start:next_node]
        
        # Fix the type if needed
        node_data = node_data.replace('type="TileMapLayer"', 'type="TileMap"')
        
        # Add if not already in our collection
        node_name_end = node_data.find('"', node_data.find('name="') + 6)
        node_name = node_data[node_data.find('name="') + 6:node_name_end]
        
        # Check if we already have this node
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
    
    # Get all main nodes from working file
    main_nodes = []
    pos = 0
    main_nodes_text = ""
    
    while True:
        # Find node definitions
        node_start = working_file.find('[node name=', pos)
        if node_start == -1:
            break
        
        # Find the next node
        next_node = working_file.find('[node name=', node_start + 10)
        
        # Extract the node
        if next_node == -1:
            node_data = working_file[node_start:]
        else:
            node_data = working_file[node_start:next_node]
        
        # See if it's a TileMap
        if 'type="TileMap"' not in node_data and 'TileMap' not in node_data:
            main_nodes.append(node_data)
            main_nodes_text += node_data
        
        if next_node == -1:
            break
        pos = next_node
    
    # Create a new file with the working header, all tilemap nodes, and main nodes
    complete_content = working_header
    
    # First add House node
    house_node_start = working_file.find('[node name="House"')
    house_node_end = working_file.find('[node name=', house_node_start + 10)
    if house_node_end == -1:
        house_node = working_file[house_node_start:]
    else:
        house_node = working_file[house_node_start:house_node_end]
    
    complete_content += house_node
    
    # Add all TileMap nodes
    for tile in all_tilemaps:
        complete_content += tile
    
    # Add remaining nodes from working file, except House which we already added
    pos = header_end
    while True:
        # Find node
        node_start = working_file.find('[node name=', pos)
        if node_start == -1:
            break
        
        # Skip if it's House
        if working_file[node_start:node_start+16] == '[node name="House"':
            pos = node_start + 10
            continue
        
        # Skip if it's a TileMap
        if 'type="TileMap"' in working_file[node_start:node_start+100] or 'TileMap' in working_file[node_start:node_start+100]:
            pos = node_start + 10
            continue
            
        # Find the next node
        next_node = working_file.find('[node name=', node_start + 10)
        
        # Extract the node
        if next_node == -1:
            node_data = working_file[node_start:]
            complete_content += node_data
            break
        else:
            node_data = working_file[node_start:next_node]
            complete_content += node_data
            pos = next_node
    
    # Write the assembled file
    with open('Levels/House/House.tscn.complete_layers', 'w') as f:
        f.write(complete_content)
    
    print("Created comprehensive file with all layers at Levels/House/House.tscn.complete_layers")

if __name__ == "__main__":
    extract_all_tilemaps() 