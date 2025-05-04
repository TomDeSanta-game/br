# Breaking Bad Game - Implementation Ideas (Minimal Art Required)

## Reputation System

A numerical system tracking relationships with different factions (Law Enforcement, Cartel, Civilians). Actions affect different factions differently - bribing ****police decreases Law rep but might increase Cartel trust. Implement using a dictionary of faction values in a global singleton. Display as simple text percentages or basic UI bars. This affects dialogue options, pricing, and quest availability without requiring new art.

## Timed Decision System

Critical moments in Walter's story presented as timed choices with significant consequences. When confronted by Tuco or deciding how to handle problematic characters, a simple text prompt appears with a timer. Choices affect story branches and relationship values. Implement using a modal dialog with countdown timer, requiring only basic UI elements and text.

## Dynamic Phone Calls & Messages

Narrative delivery through Walter's phone. Characters call or message with information, threats, or opportunities. Player chooses response options affecting relationships and plot progression. Implement using existing UI framework with text-only content displayed as messages or simple dialogue. This creates immersion without cutscenes or character art.

# Crucial Story-Driven Features

## Cancer Progression System

Track Walter's cancer development as a core narrative mechanic. Implement a hidden timer with periodic health checks that affect gameplay (reduced movement speed or stamina during advanced stages). Tie treatment decisions to the financial system - choosing between expensive treatment or saving money for family affects both health progression and story outcomes.

## Dual Identity Management

Toggle between "Walter White" and "Heisenberg" personas. Each identity has different dialogue options, abilities, and reputation impacts. Implement using a simple state machine that affects dialogue trees, available actions, and character responses. Staying too long in either persona creates consequences (family suspicion as Heisenberg, lost criminal opportunities as Walter).

## Territory Control Mechanic

Visualize cartel territories as a simple color-coded map interface. Players can take control of territories through story missions, increasing income but also raising heat and rival attention. Implement using a grid-based data structure with ownership values and income generation. This creates escalating conflict with Gus Fring and other rivals as the story progresses.

# Essential Story Game Features (Visual Focus)

## Character Portraits System
Create a simple portrait system showing character emotions during dialogue. Rather than complex animations, use 2-3 emotion variants per character (neutral, angry, pleased). Display these static portraits during conversations to add visual impact to dialogue. This requires minimal art while significantly enhancing narrative immersion.

## Time-of-Day Visual Filter
Implement a color grading system that changes the game's visual tone based on time of day and story progression. Early game uses brighter filters, while later game scenes use darker, more saturated tones matching Walter's descent. This creates visual storytelling with no additional art assets - just shader effects applied to existing scenes.

## Visual Quest Tracker
Design a minimalist quest journal with Breaking Bad-themed iconography. Use simple icons representing key themes (money for financial goals, beakers for cooking, etc.) instead of complex art. Include a progress visualization system showing Walter's journey from teacher to kingpin. This provides visual feedback on story progress without requiring extensive new assets.
