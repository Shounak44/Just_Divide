Division Puzzle Game

A number puzzle game where players match or divide adjacent numbers to clear the board and score points.
Approach
The game follows a tile-matching puzzle mechanic with mathematical operations:

Core Loop: Drag and drop tiles onto a 4x4 grid
Merge System: Adjacent tiles with equal values disappear, or tiles that are divisible merge into their quotient
Queue System: Display preview of current and next tiles to enable strategic planning
Progressive Difficulty: Numbers increase in complexity as the player levels up

Key Decisions Made
Game Mechanics

Two merge types: Equal matching (easier) and division (adds depth)
Keep slot: Allows saving one tile for later use, adding strategic planning
Trash system: Limited uses (10 + 2 per level) to discard unwanted tiles
Undo functionality: Up to 10 moves can be undone, reducing frustration

Technical Implementation

State management: Full game state saved for undo (grid, score, queue, kept tile)
Modular functions: Separate functions for merges, tile spawning, and game over detection
Recursive processing: Division results trigger new merge checks automatically
Audio feedback: Different voice clips for regular solves vs level ups

UI/UX

Visual previews: Show current and next tile values
Drag-and-drop: Intuitive tile placement with snap-to-grid
Lose screen: Clear game over state with restart option
Info audio: Tutorial/help accessible via button

Challenges Faced

Merge Logic Complexity: Ensuring equal matches and divisions don't conflict or cause infinite loops

Solution: Process equal matches first, then divisions; recursive calls handle chain reactions


Game Over Detection: Determining when no valid moves remain

Solution: Check all tiles and their neighbors for both equal matches and divisibility after each placement


Queue Management: Keeping preview tiles in sync with actual spawned tile

Solution: Separate preview tiles (non-interactive) from draggable current tile, advance queue only after placement


Undo System: Restoring complete game state including kept tiles and queue

Solution: Store full state snapshots including all tile positions, values, and queue state


Kept Tile Behavior: Preventing kept tiles from being moved back to keep slot

Solution: Different drop handlers for current tiles vs kept tiles



What I Would Improve
Gameplay

Power-ups: Add special tiles (multiply, shuffle, clear row/column)
Combo system: Reward consecutive merges with score multipliers
Multiple difficulty modes: Easy (only matching), Normal (current), Hard (prime numbers)
Daily challenges: Predetermined tile sequences for competitive scoring

Technical

Save system: Persist game state between sessions
Leaderboards: Track high scores locally or online
Animation polish: Smoother tile movements, merge effects, particle systems
