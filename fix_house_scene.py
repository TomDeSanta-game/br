
def process_file(filename):
    with open(filename, 'r') as f:
        content = f.read()
    first_olv04_pos = content.find('[sub_resource type="TileSet" id="TileSet_olv04"]')
    first_p6oj2_pos = content.find('[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_p6oj2"]')
    second_p6oj2_pos = content.find('[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_p6oj2"]', first_olv04_pos)
    if first_p6oj2_pos >= 0 and second_p6oj2_pos > first_p6oj2_pos:
        print(f"Found duplicate TileSetAtlasSource_p6oj2 declarations")
        next_sub_pos = content.find('[sub_resource type=', second_p6oj2_pos + 10)
        if next_sub_pos > 0:
            print(f"Removing the second occurrence and keeping the content up to the next sub_resource")
            new_content = content[:second_p6oj2_pos] + content[next_sub_pos:]
        else:
            next_node_pos = content.find('[node name=', second_p6oj2_pos)
            if next_node_pos > 0:
                print(f"Removing the second occurrence and keeping the content up to the next node")
                new_content = content[:second_p6oj2_pos] + content[next_node_pos:]
            else:
                print(f"No next sub_resource or node found, keeping the original file")
                new_content = content
    else:
        print(f"No duplicate declarations found")
        new_content = content
    with open(filename + '.fixed2', 'w') as f:
        f.write(new_content)
    print(f"Fixed file written to {filename}.fixed2")
if __name__ == "__main__":
    process_file("Levels/House/House.tscn")