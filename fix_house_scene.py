#!/usr/bin/env python3

def process_file(filename):
    with open(filename, 'r') as f:
        content = f.read()
    
    # Get the position of the first TileSet_olv04 declaration
    first_olv04_pos = content.find('[sub_resource type="TileSet" id="TileSet_olv04"]')
    
    # Get the position of the first TileSetAtlasSource_p6oj2 declaration
    first_p6oj2_pos = content.find('[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_p6oj2"]')
    
    # Find the position of the second TileSetAtlasSource_p6oj2 after the TileSet_olv04
    second_p6oj2_pos = content.find('[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_p6oj2"]', first_olv04_pos)
    
    if first_p6oj2_pos >= 0 and second_p6oj2_pos > first_p6oj2_pos:
        print(f"Found duplicate TileSetAtlasSource_p6oj2 declarations")
        
        # Find the next sub_resource after the second occurrence
        next_sub_pos = content.find('[sub_resource type=', second_p6oj2_pos + 10)
        
        if next_sub_pos > 0:
            print(f"Removing the second occurrence and keeping the content up to the next sub_resource")
            # Remove from second_p6oj2_pos to next_sub_pos
            new_content = content[:second_p6oj2_pos] + content[next_sub_pos:]
        else:
            # If no next sub_resource found, just remove to the next node
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
    
    # Write the modified file
    with open(filename + '.fixed2', 'w') as f:
        f.write(new_content)
    
    print(f"Fixed file written to {filename}.fixed2")
    
if __name__ == "__main__":
    process_file("Levels/House/House.tscn") 