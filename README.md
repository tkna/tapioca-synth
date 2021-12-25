# Tapioca Synth
A simple additive-synthesis synth with tapioca-like UI using SuperCollider

https://user-images.githubusercontent.com/69493688/147385243-c3e20858-ceaa-46b1-b3cc-834f3768f4ed.mp4

## Get started
1. Put class file `Tapioca.sc` into systemExtentionDir or userExtensionDir

  can check them by executing following lines.
  ```
  Platform.systemExtensionDir.postln;
  Platform.userExtensionDir.postln;
  ```

2. Launch SuperCollider and open `tapioca.scd`
1. Execute the server(Synthdef) part
1. Execute the client(GUI) part

## Usage
### Create notes
Click anywhere in the white area at the top to create notes. The horizontal axis corresponds to the frequency and the vertical axis corresponds to the amplitude.

### Select notes
Click on a specific note or drag the mouse to select notes. (Ctrl key is available to add seleted notes in addition to existing selected notes)

### Deselect notes
Click and drag the area without any notes to deselect notes.

### Change amplitudes of selected notes
Click and drag any of the selected notes vertically to change the amplitudes.

### Change frequencies of selected notes
Click and drag any of the selected notes horizontally with Shift key pressed to change the frequencies.

### Remove selected notes 
Hit space key to remove the selected notes.

### EditMode
By clicking icons at the right you can select the "1 note mode", where notes are created one by one, or the "multiple notes mode", where notes are created simulteneously when you hit the space key. 

### ADSR
Adjust the knobs at the bottom left to set attack time, decay time, sustain level, and release time.

### Groups(Colors): beta
Notes can be grouped by colors. When creating a note/notes, the note(s) is grouped as the current color, which is currently selected in the bottom right area. You can change the color which a note belongs to by clicking the colored square in the bottom right area, with the target notes selected. You can also select notes with specific color all at once by clicking the colored square in the bottom right area, with no notes selected.


