
def fix_house_completely():
    with open('backups/House/House.tscn.current', 'r') as f:
        complete_backup = f.read()
    with open('Levels/House/House.tscn.backup.final', 'r') as f:
        base_file = f.read()
    if 'format=4' in complete_backup:
        complete_backup = complete_backup.replace('format=4', 'format=3', 1)
    complete_backup = complete_backup.replace('type="TileMapLayer"', 'type="TileMap"')
    main_start = base_file.find('[node name="MainTileMap"')
    if main_start == -1:
        print("Error: Could not find MainTileMap in base file")
        return
    header_end = base_file.find('[node name="House"')
    if header_end == -1:
        print("Error: Could not find House node in base file")
        return
    base_header = base_file[:header_end]
    house_start = complete_backup.find('[node name="House"')
    if house_start == -1:
        print("Error: Could not find House node in complete backup")
        return
    new_content = base_header + complete_backup[house_start:]
    with open('Levels/House/House.tscn.ultimate', 'w') as f:
        f.write(new_content)
    print("Created ultimate fixed file at Levels/House/House.tscn.ultimate")
if __name__ == "__main__":
    fix_house_completely()