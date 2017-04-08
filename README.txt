


Messy work in progress. Be warned!

mazelib.lua - code for generating and colouring mazes
mazetest.lua - code for testing the maze generation

texlib.lua - mostly rendering code for palette swaps
 and tile combining
textest.lua - code to test the rendering
textest.p8 - contains the graphics and test maps

paledit.lua - rudimentary palette editor
paledit.p8 - palette editor plus graphics
 Note! Once you edit the palette, the only way to
 save it is to hit ESC to stop the editor,
 execute "cstore()" and then save the card with
 CMD+S. *Then* you need to copy the gfx section
 from paledit.p8 to textest.p8. It seems very
 hard to make this less painful. :(
