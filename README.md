# TVCGAFix Utilities

A small DOS toolset for improving CGA composite video on television sets.  Main purposes:

- Allow adjustment of the picture's horizontal position, for proper centering
- Make color output in 80-column text modes more reliable, by working around a CGA design bug (or is it a feature?)

Includes:

- **TVCGAFIX:** main TSR; allows you to adjust the H-position, improves color output with 80-column text, and makes the changes 'stick' for most programs/games
- **MAKEBOOT:** boot-disk maker; allows you to load the fix at system startup (to support 'booter' games)
- **TVCGACAL:** displays a calibration screen so you can find the optimal H-position
- **TV80**: lets you make further adjustments specific to 80-column text mode

Coincidentally, TVCGAFIX also helps certain *RGB* capture devices get good color from a (converted) CGA signal... at least the Datapath VisionRGB E1s.  Not written for that purpose, but consider it a bonus.

See **README.TXT** for detailed documentation.
