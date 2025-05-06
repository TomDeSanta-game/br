
def process_file(filename):
    with open(filename, 'r') as f:
        content = f.read()
    if 'format=4' in content:
        content = content.replace('format=4', 'format=3')
        print("Fixed format version from 4 to 3")
    search_str = '[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_p6oj2"]'
    positions = []
    pos = content.find(search_str)
    while pos != -1:
        positions.append(pos)
        pos = content.find(search_str, pos + 1)
    if len(positions) > 1:
        print(f"Found {len(positions)} occurrences of TileSetAtlasSource_p6oj2")
        for i in range(1, len(positions)):
            next_pos = content.find('[sub_resource', positions[i] + len(search_str))
            if next_pos == -1:
                next_pos = content.find('[node name=', positions[i] + len(search_str))
            if next_pos != -1:
                print(f"Removing duplicate occurrence {i+1}")
                content = content[:positions[i]] + content[next_pos:]
                for j in range(i+1, len(positions)):
                    positions[j] = content.find(search_str, positions[i-1] + len(search_str))
            else:
                print(f"Could not find next section after occurrence {i+1}")
    with open(filename + '.fixed3', 'w') as f:
        f.write(content)
    print(f"Fixed file written to {filename}.fixed3")
if __name__ == "__main__":
    process_file("Levels/House/House.tscn.original")