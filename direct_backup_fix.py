
def fix_direct_from_backup():
    with open('backups/House/House.tscn.backup', 'r') as f:
        backup_content = f.read()
    backup_content = backup_content.replace('format=4', 'format=3', 1)
    backup_content = backup_content.replace('type="TileMapLayer"', 'type="TileMap"')
    if 'tile_map_data =' in backup_content:
        data_starts = []
        data_ends = []
        pos = 0
        while True:
            data_start = backup_content.find('tile_map_data =', pos)
            if data_start == -1:
                break
            data_ends.append(backup_content.find(')', data_start))
            data_starts.append(data_start)
            pos = data_ends[-1] + 1
        print(f"Found {len(data_starts)} tile_map_data entries")
    with open('Levels/House/House.tscn.backup.final', 'r') as f:
        framework_content = f.read()
    header_end = framework_content.find('[node name="House"')
    if header_end == -1:
        print("Error: Could not find House node in framework file")
        return
    framework_header = framework_content[:header_end]
    house_node_start = backup_content.find('[node name="House"')
    if house_node_start == -1:
        print("Error: Could not find House node in backup file")
        return
    new_content = framework_header + backup_content[house_node_start:]
    with open('Levels/House/House.tscn.direct', 'w') as f:
        f.write(new_content)
    print("Created direct file from backup at Levels/House/House.tscn.direct")
    with open('backups/House.tscn.backup', 'r') as f:
        original_backup = f.read()
    original_backup = original_backup.replace('format=4', 'format=3', 1)
    with open('Levels/House/House.tscn.original', 'w') as f:
        f.write(original_backup)
    print("Created another version from original backup at Levels/House/House.tscn.original")
if __name__ == "__main__":
    fix_direct_from_backup()