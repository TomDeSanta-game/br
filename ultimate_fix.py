#!/usr/bin/env python3

def fix_house_completely():
    # Read the most complete backup with all tile data
    with open('backups/House/House.tscn.current', 'r') as f:
        complete_backup = f.read()
    
    # Get a base working file format for Godot 4.x compatibility
    with open('Levels/House/House.tscn.backup.final', 'r') as f:
        base_file = f.read()
    
    # First line format fix from format=4 to format=3
    if 'format=4' in complete_backup:
        complete_backup = complete_backup.replace('format=4', 'format=3', 1)  # Only replace the first occurrence
    
    # Make sure all TileMapLayer types are replaced with TileMap
    complete_backup = complete_backup.replace('type="TileMapLayer"', 'type="TileMap"')
    
    # Extract the full correct node structure from the backup but with fixed TileMap types
    # Find MainTileMap definition in base file to get correct structure
    main_start = base_file.find('[node name="MainTileMap"')
    if main_start == -1:
        print("Error: Could not find MainTileMap in base file")
        return
    
    # Find the headers (ext_resources, etc.) from base_file to preserve compatibility
    header_end = base_file.find('[node name="House"')
    if header_end == -1:
        print("Error: Could not find House node in base file")
        return
    
    # Get the header from the base file
    base_header = base_file[:header_end]
    
    # Get the house node start from the complete backup
    house_start = complete_backup.find('[node name="House"')
    if house_start == -1:
        print("Error: Could not find House node in complete backup")
        return
    
    # Create a new file that combines the base header with the complete backup content
    new_content = base_header + complete_backup[house_start:]
    
    # Write the new combined file
    with open('Levels/House/House.tscn.ultimate', 'w') as f:
        f.write(new_content)
    
    print("Created ultimate fixed file at Levels/House/House.tscn.ultimate")

if __name__ == "__main__":
    fix_house_completely() 