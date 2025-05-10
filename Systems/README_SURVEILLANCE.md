# Surveillance Camera System

A flexible and easy-to-use camera system for switching between security cameras during gameplay. This system is ideal for creating tension moments, story sequences, and gameplay mechanics in the Breaking Bad game.

## Setup Instructions

### 1. Basic Setup (Using Autoload)

The system is already set up as an autoload singleton in the project. If you need to manually set it up:

1. Add `SurveillanceCameraSystem="*res://Systems/Scripts/surveillance_camera_system.gd"` to your project.godot file's `[autoload]` section.
2. Make sure `SignalBus` is also properly set up in the autoloads.

### 2. Adding Cameras to Your Level

In your level's main script, register the player camera:

```gdscript
func _ready():
    # Get the player's camera
    var player = get_node("Player")  # Adjust path as needed
    var player_camera = player.get_node("Camera2D")  # Adjust path as needed
    
    # Register with surveillance system
    SurveillanceCameraSystem.register_player_camera(player_camera)
```

### 3. Creating Camera Instances

There are two ways to create surveillance cameras:

#### A. Script-Based Approach

```gdscript
# Create a camera node
var camera_node = Node2D.new()
camera_node.name = "SecurityCamera1"

# Add a visual for the camera
var sprite = Sprite2D.new()
sprite.texture = load("res://assets/security_camera.png")
camera_node.add_child(sprite)

# Add the actual camera
var camera = Camera2D.new()
camera.name = "Camera2D"
camera.enabled = false  # Important: Start disabled
camera_node.add_child(camera)

# Register with the system
SurveillanceCameraSystem.register_camera(camera, "security_cam_1")
```

#### B. Using Scene Instances

1. Create a Node2D with a Camera2D child
2. Register this camera with the system

```gdscript
func _ready():
    var camera = $SecurityCamera/Camera2D
    SurveillanceCameraSystem.register_camera(camera, "security_cam_1")
```

### 4. Triggering Camera Activation

#### A. Via Code

```gdscript
# Activate a specific camera
SurveillanceCameraSystem.activate_camera("security_cam_1")

# Switch to a different camera
SurveillanceCameraSystem.switch_camera("security_cam_2")

# Return to player view
SurveillanceCameraSystem.deactivate_current_camera()
```

#### B. Via Player Interaction

Add interaction areas that trigger the camera activation:

```gdscript
func _on_interaction_area_entered(_area):
    if Input.is_action_just_pressed("interact"):
        SurveillanceCameraSystem.activate_camera("security_cam_1")
```

## Features

- Smooth camera transitions
- Player state preservation (freezes player during surveillance mode)
- Quick camera switching using number keys (1-9)
- UI integration for interaction prompts
- Signal support for connecting surveillance events to other game systems

## Testing

We've included a standalone test scene to verify the system works:

1. The test scene is located at `Systems/Scenes/StandaloneCamera.tscn`
2. It creates a player with a camera and three test cameras
3. Press keys 1-3 to switch between cameras
4. Press ESC to return to player view

## Example Implementation

See `standalone_camera_test.gd` for a complete example of how to:
- Set up cameras dynamically
- Register cameras with the system
- Handle camera switching
- Create UI prompts for player guidance

## Story Integration Ideas

- Security office monitoring in Gus's lab
- Police surveillance during high-tension moments
- Traffic camera footage during car chases
- Hidden cameras in the White residence during investigations
- DEA surveillance footage during operations

## Troubleshooting

If cameras aren't working:
1. Ensure the player camera is properly registered
2. Verify camera IDs are unique
3. Check console output for any registration errors
4. Make sure cameras are disabled by default (only one active at a time) 