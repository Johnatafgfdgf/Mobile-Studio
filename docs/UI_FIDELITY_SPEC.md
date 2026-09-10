# Mobile Studio — UI Fidelity Specification

## Product direction

Mobile Studio must feel like **Roblox Studio adapted to touch**, not a generic dashboard, game HUD, SaaS panel, or random dark UI.

The desktop Roblox Studio interface is the primary structural and visual reference. Mobile adaptations are allowed only when needed for touch ergonomics, safe areas, limited screen space, or technical limitations of running inside Studio Lite.

## Fidelity target

The implementation should preserve as much as possible of the current Roblox Studio mental model:

- top mezzanine / command area;
- standard tool tabs: Home, Model, Avatar, UI, Script, Plugins;
- contextual toolbar directly below the tabs;
- central 3D viewport as the dominant workspace;
- Explorer hierarchy;
- Properties inspector with collapsible categories;
- Output;
- Command Bar;
- Toolbox;
- Asset Manager;
- Script Editor with document tabs;
- test/play controls;
- undo / redo;
- selection synchronization between viewport, Explorer and Properties;
- familiar naming and interaction order.

## Visual rules

### Do

- Use compact Studio-like density.
- Use thin separators instead of large floating cards.
- Use restrained corner radii.
- Use consistent monochrome / class-specific icons.
- Use clear selected, hovered and focused states.
- Use grouped toolbar controls instead of identical pill buttons.
- Keep typography compact and utilitarian.
- Preserve Studio hierarchy and spacing wherever screen size allows.
- Let users collapse the toolbar, similar to desktop Studio.

### Do not

- Do not use emoji as permanent UI icons.
- Do not make every element a rounded card.
- Do not use oversized mobile-game buttons for editor commands.
- Do not permanently consume large viewport areas with panels that can be docked or temporarily overlaid.
- Do not label decorative areas such as `VIEWPORT 3D` if the desktop Studio does not need such decoration.
- Do not invent arbitrary page navigation when Studio uses windows / tabs / panels.
- Do not imitate a generic admin dashboard.

## Desktop-derived structure

### Mezzanine

The top region includes:

- play/test controls;
- standard tabs;
- project / collaboration / utility controls;
- compact global actions.

On mobile, respect Roblox CoreGui safe areas and never overlap system / Roblox buttons.

### Tool tabs

Primary tabs:

1. Home
2. Model
3. Avatar
4. UI
5. Script
6. Plugins

Tabs change the contextual toolbar below them.

### Home toolbar

Prioritize:

- Select
- Move
- Scale
- Rotate
- transform snapping
- Part insertion
- Color
- Material
- Group / Ungroup
- Lock
- Anchor
- Terrain

### Model toolbar

Prioritize:

- transform controls;
- pivot tools;
- align tools;
- constraints;
- effects;
- solid modeling;
- model organization tools.

### Avatar toolbar

Prioritize:

- rig creation;
- avatar configuration;
- animation tools;
- accessory fitting / editing.

### UI toolbar

Prioritize:

- ScreenGui / SurfaceGui / BillboardGui creation;
- Frame / CanvasGroup;
- text / image / button controls;
- layout objects;
- UI constraints;
- style-related tools.

### Script toolbar

Prioritize:

- Script / LocalScript / ModuleScript creation;
- find / replace;
- Output;
- Command Bar;
- script analysis and diagnostics;
- document navigation.

## Core windows

### Explorer

Explorer is a true hierarchical tree, not a flat service list.

Requirements:

- parent / child indentation;
- expand / collapse affordances;
- class-specific icons;
- selection state;
- multi-selection architecture;
- search;
- rename;
- insert object;
- duplicate;
- delete;
- cut/copy/paste architecture;
- drag/reparent architecture;
- context menu;
- selection synchronized with viewport and Properties;
- incremental refresh instead of rebuilding the entire tree every frame.

### Properties

Requirements:

- selected object's name and class in header;
- search;
- categories and subcategories;
- collapsed state persistence by class / category;
- editable string, number, boolean, enum, Color3, Vector3, UDim, UDim2 and object-reference controls where feasible;
- attributes section;
- tags section architecture;
- validation and revert on invalid input;
- multi-selection architecture.

### Output

Requirements:

- errors;
- warnings;
- prints;
- timestamps option;
- context/source architecture;
- search/filter;
- clear;
- collapsible bottom docking.

### Command Bar

Requirements:

- multiline-ready architecture;
- history;
- saved commands architecture;
- execute action;
- future completion / lint integration.

### Script Editor

Must be a document workspace, not a plain TextBox floating in a panel.

Requirements:

- document tabs;
- unsaved state marker;
- line numbers;
- syntax highlighting architecture;
- indentation;
- selection / copy / paste;
- search / replace;
- autocomplete architecture;
- diagnostics architecture;
- go-to-line;
- multiple open scripts;
- horizontal / vertical scrolling;
- mobile accessory row for Tab, arrows, symbols and common Luau characters;
- optional full-screen editing mode.

## Mobile layout strategy

### Large landscape

- viewport center;
- Explorer docked or pin-able;
- Properties docked or pin-able;
- bottom Output tray;
- full contextual toolbar when space permits.

### Compact landscape

- viewport remains dominant;
- Explorer and Properties become temporary drawers unless pinned;
- toolbar can collapse to compact icons;
- bottom tray starts collapsed.

### Portrait

- viewport remains available;
- Explorer / Properties use bottom-sheet or full-height overlay modes;
- script editor can switch to full-screen;
- toolbar becomes horizontally scrollable but keeps the same tool grouping and order.

## Touch interaction

Desktop behavior should be preserved conceptually while translated to touch:

- tap = primary click / select;
- long press = context menu;
- drag = manipulate / scroll depending on active tool and target;
- two-finger pan / pinch reserved for viewport navigation where compatible;
- larger invisible hit targets may surround visually compact controls;
- visual control sizes should remain Studio-like even when touch targets are larger internally.

## Safe-area policy

Never hardcode around one device.

The shell must account for:

- Roblox CoreGui inset;
- device safe area;
- orientation;
- viewport size changes;
- keyboard visibility where detectable;
- display scaling.

## Implementation principle

Visual fidelity and functional fidelity are separate targets.

1. Preserve Studio's structure and interaction vocabulary.
2. Implement real behavior behind each exposed control.
3. Hide unfinished features or mark them clearly as unavailable instead of presenting dead buttons.
4. Prefer fewer real tools over many fake controls.
5. Expand toward feature parity incrementally without redesigning the shell every milestone.

## Current priority order

1. Responsive Studio-like shell
2. Real Explorer
3. Real selection
4. Real Properties
5. Move / Scale / Rotate
6. Create / duplicate / delete / reparent
7. Undo / redo
8. Script workspace
9. Output / diagnostics
10. UI editor
11. Asset / toolbox workflows
12. project serialization
13. publishing pipeline
14. collaboration / plugin architecture
