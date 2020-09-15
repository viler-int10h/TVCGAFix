           _ ƒ --- ƒ                  _ ƒ --- ƒ
        .˘"    ,¬,   ~=“_    .˘.   .˘"          ~=“_
      .    . .OZZZO∏    ^g,      .    .˛¯~¯˛.      ^%∑   .s%ZOø
          `  ¿¶qZp¶' ¯˘  `Z,         `        _.,˙  `gZø  ˘:ZZ|
      _¬g%%oc,  ~ _.,  `  ‘Z;         _.,¬©y%Z=-:˙ .s%Z%L, `OZZYi%g¬_
     jOZZòòZZOL˙ jOZZò™,  `Zb  _.¬©y%ZZZZZZZZ%=:˘ jZZZZZZZb `ZZZZòZZZb
    ˘ZZ?~ ~\ZZZ| |õZZZZO\ ˙?Z.˘%òZZZZZZ¶* ¸^¯"`' /ZZ¶"~"¶ZZ\ ˘T   ~!ZZ¥
     Z6f   ˘ZZZO˘˙|ZZZ^ZZi ]Z1˙:-":ZZZ'      _. ˘OZ/     \ZZL :    |6Z'
 .   `ZZ™._ ~"^Z| ˘ZZZ;\ZZ ∆Zµ   ˙õZZZ˙  _¬%ZZ˙ l%! .oZo, ]ZZ˙˘  _“ZZ'   .
  ,    ~^ * ^~.Zõ˙˙ZZZl ZZ¬ZZ1 ˙ ˘ZZZZ˘  ^¶!ZZ˘ :=l dZZZb ˘ZZ|  ~^"~
   ˘        g%ZZZ˙˙ZZZZ `ùZZZ¯ : ˙ZZZZ:   ˘lZZ| ˘;˘ :ZZZF ˙ZZ|         .'
    ~ƒ_    ˙ZZZZ| ˘ZZZZ  ¿ZZò' ˘  ?ZZZ!    :ZZ≥˙ ˙˘  "¶"  dZg˙      _ƒ~
       ~"^ :ZZZO˘˘|ZZZ!   `^'  '  `ùZZZ    ˙¶ZZ:  ˙     ./ZZf ˙ƒ--`~
           OZZZ˘ jZ¶ ~  `. _ _. .   ~^¶L, YZZZZOzz¬¬ ˙˘:=CO/
     -V!  j¶ ^~     .     ~-∫˘-~    .     `^ ¶ZùòZF'˙˘:%CG' . O R G
                     ~ƒ_    T    _ƒ~             ~'  '^"~
                        ~"Õ=|=Õ"~
                            ˘        p r e s e n t s
                            ˙
                     .--------------------------------˙  ˙
                     :  T V + C G A   F I X   T O O L S  :
                     ˙  ˙--------------------------------'
                               (v1.00 / 2018-08)



                              ---  CONTENTS  ---


            * ABOUT / QUICK FAQ
            * SYSTEM REQUIREMENTS
            * H-POSITION VALUES AND WHAT THEY MEAN
            * TVCGACAL: CALIBRATING AN OPTIMAL H-POSITION FOR YOUR TV
            * USING TVCGAFIX
            * MAKEBOOT: CREATING A FIX DISK FOR USE WITH BOOTERS
            * TV80: MORE TWEAKS IN 80-COLUMN TEXT MODE
            * KNOWN ISSUES / TO-DO
            * VERSION HISTORY
            * THANKS
            * CONTACT



                          ---  ABOUT / QUICK FAQ  ---


Q: What's this?

A: A set of tools for adjusting/optimizing CGA video output for TV.  You can
   use them to find/set an optimal H-position for your TV set, fix various
   issues related to 80-column text display, and make the adjustments "stick"
   while running programs and games (even booters).


Q: What's inside?

A: TVCGAFIX.COM: the main TSR; sets the H-position and fixes up 80-col text
   TVCGACAL.COM: displays a calibration screen to find the optimal H-position
   MAKEBOOT.COM: boot-disk maker; load the fix at system startup for booters
   TV80.COM:     make various adjustments to optimize 80-column text output


Q: Why is this needed?

A: To make life easier for users of PC compatibles who happen to have a Color/
   Graphics Adapter (or clone) hooked up to a composite display, especially to
   a television set, and most especially to an older CRT television set.

   The CGA's composite video output doesn't horizontally center the active
   picture with respect to the the total raster area.  Some composite monitors
   can compensate for this; so do more modern TV sets, which can mitigate this
   by displaying the full overscan area and/or adjusting the horizontal
   position on the TV side.  For old-school CRT televisions however this can
   be a problem - and on the software side, you don't always get those
   convenient "shift screen left/right" controls, like some games used to
   provide for this very situation.

   On top of that, the CGA design has a bug (or is it a feature?) which causes
   the width of the hsync pulse to be halved in 80-column text mode.  The
   usual effect is that the color goes completely missing.  Of course, colored
   80-column text isn't very readable on composite displays anyway, which is
   why this may actually be a "feature"; but sometimes it is desired,
   especially in games that use it for pseudo-graphics.


Q: Can't I just use the MODE command in DOS to fix this stuff?

A: MODE.COM does take a couple of parameters (",l" and ",r") to control the
   screen's horizontal positioning, and make it persist through mode changes.
   However:

   * MODE doesn't do anything about those 80-column text mode quirks.
   * Obviously, it doesn't work with self-booting software which knows nothing
     about DOS.
   * In some DOS versions (e.g. MS-DOS 6.22), MODE.COM is buggy and enjoys
     corrupting the pointers to its own parameter tables; when a new mode is
     set, the CRTC receives complete garbage and the TV promptly loses sync.
   * TVCGAFIX takes up even less RAM than MODE.COM's resident module. ;-)



                        ---  SYSTEM REQUIREMENTS  ---


-- IBM PC or compatible
-- DOS 2.0+
-- Color/Graphics Adapter, or 100% register-compatible video board
-- Composite output and display/TV (otherwise you don't need this)
-- Functional floppy drive (for MAKEBOOT only)

DON'T try to run these utilities on non-CGA hardware.  While I'm reasonably
sure they won't break anything, there's no point so don't risk it.



                ---  H-POSITION VALUES AND WHAT THEY MEAN  ---


For the purpose of these tools, the horizontal position of your screen image
is an integer value ranging from 0 to 9.

It's enough to know that 0 is the leftmost position, 9 is the rightmost, and 1
is the default value set in IBM's BIOS (yep, it's THAT close to the leftmost
valid position - that's why it causes a left-shifted picture on most TV sets).
You can feel free to skip the rest of this section, but for the curious here's
what these values actually mean under the hood.

The single-digit H-position values are mapped to a set of "raw" values sent to
register 02 (horizontal sync position) of the MC6845 CRT Controller.  This
register determines how many character clocks elapse between the beginning
(left edge) of the active area and the start of the hsync pulse.  You can
think of the hsync pulse as being at a fixed location somewhere beyond the
right edge of the screen, "anchoring" the image horizontally.  So, a larger
value in this register will shift the image to the LEFT, and vice versa; but
to make things a little more intuitive, our single-digit position values go in
reverse - smaller values shift left, larger ones shift right.

As the unit is character clocks, the image can be pushed around in increments
of 8 low-res pixels (or 16 hi-res ones).  In 80-column text mode the CGA's
character clock rate is doubled, so the raw register value must also be
doubled.  TVCGAFIX takes care of that, so that your chosen value of 0 to 9
behaves consistently across video modes.  For more fine-grained control in 80-
column modes, refer to the section on TV80.COM.

The mapping of H-position values to raw register contents:

               H-POS  RAW VAL  (IN 80C)
               -----  -------  --------
               0      2Eh      5Ch
               1*     2Dh      5Ah       *IBM's default for CGA
               2      2Ch      58h
               3      2Bh      56h
               4      2Ah      54h
               5      29h      52h
               6      28h      50h
               7      27h      4Eh
               8      26h      4Ch
               9      25h      4Ah

There's a rationale behind this specific range of raw values.  Going above
2Eh/5Ch makes the TV lose sync, and going below 25h/4Ah simply pushes the
image so far to the right that it starts wrapping right around to the left
edge and gets split in half; vaguely comical for the easily-amused perhaps,
but hardly useful.



      ---  TVCGACAL: CALIBRATING AN OPTIMAL H-POSITION FOR YOUR TV  ---


To help you come up with an optimal H-position setting, run TVCGACAL.COM.
You'll be presented with a calibration screen, complete with incredibly low-
res ANSI art for you to enjoy (or barf at) and a red border (to indicate the
actual edges of the active area).

The current H-position value will be indicated at the bottom.  Use the left/
right cursor keys to shift the image in the respective direction until it's
horizontally centered, with both the left and right edges visible. Hitting ESC
will drop you back to DOS, and helpfully display the command line needed to
install TVCGAFIX with the chosen value.



                           ---  USING TVCGAFIX  ---


Once you have determined a decent value to use, installing TVCGAFIX is pretty
easy - simply run:

TVCGAFIX #

...Where # specifies your desired horizontal screen position (0..9).  This
will install the TSR.  Should you want to change this value later, just launch
TVCGAFIX again with a new parameter, and the already-installed TSR will accept
the new value.

Once the TSR has been loaded, it will detect any attempt to set a CGA video
mode through the BIOS, and make the necessary H-position adjustment.  Since it
takes up less than half a kilobyte of RAM, I sincerely doubt that memory use
would be a problem.

Besides adjusting the screen's position, TVCGAFIX will also try to compensate
for CGA's shortcomings in color 80-column text mode, and ensure that it
actually shows in color <gasp!>.  One known method to do this was to set the
overscan color to #6: this causes the border to double as a color-burst signal
of the right hue.  However the *amplitude* of this fake burst is still
incorrect (too high), which makes the picture entirely too dark.  TVCGAFIX
uses another approach instead and increases the *width* of the hsync pulse to
the maximum compatible value (0Fh).  This seems to be enough for most TV sets
to detect the actual color burst generated by the adapter (or most of it), so
no border color is required as a substitute, and the image brightness should
be more or less correct.



         ---  MAKEBOOT: CREATING A FIX DISK FOR USE WITH BOOTERS  ---


Quite a few games from the CGA era are self-booting: you start them up without
DOS being involved at any point, so (obviously) they'll be blissfully unaware
of any DOS-based TSR such as TVCGAFIX.  Quite a few of these booters do have
conversions or loaders that let you run them from DOS, but others don't; some
of those solutions don't always work right anyway (I've seen several DOS
loaders/conversions that aren't even 8088-compatible).

In these cases, you'll have to load any display-related fixups BEFORE the
booter starts up.  The included MAKEBOOT.COM program lets you create a
bootable diskette to do just that.

The only thing you'll need is a formatted, UNUSED diskette in drive A.  The
MAKEBOOT program will overwrite the diskette's boot sector, so at the risk of
being obvious:

    DO NOT USE YOUR BOOTER GAME DISK ITSELF, OR ANY OTHER DISK
    CONTAINING DATA THAT YOU NEED!

With that out of the way... to create the boot disk, type:

MAKEBOOT #

...Where # specifies the horizontal screen position (0..9) which the bootable
program will set.  You'll be prompted to insert your disk in drive A:.  If all
goes well, a new boot sector will be written.  You'll want to boot the machine
with this new disk first - it will install a boot-time version of TVCGAFIX
using the H-position value you chose, then let you change disks and enjoy your
self-booting CGA game.

For now, the bootable version doesn't use the same method as the DOS TSR (it
modifies the Video Parameter Table instead of hooking INT 10), but the results
should be the same.  I might change this in the future for the sake of
consistency or some new feature.



              ---  TV80: MORE TWEAKS IN 80-COLUMN TEXT MODE  ---


For various reasons, 80-column text mode is the "special-needs child" of the
CGA family.  TVCGAFIX already takes care of the biggest issue (the truncated
hsync width making the color burst 'invisible'), so generally it should be
enough to just run that.  However in some circumstances you might want a
little more fine-grained control, and that's where TV80.COM comes in.

In 80-column mode the character clock rate is doubled; consequently you can
reposition the display in smaller increments.  You can think of those as
"half-steps" in between the 0..9 integer values that TVCGAFIX provides, but
it's not exactly as simple as that.

For starters, in addition to the position of hsync pulse, its *width* also
affects the visible horizontal shift (as mentioned before, TVCGAFIX increases
this width for 80-column modes).  Then there's the interplay between the hsync
position and color burst signal: with burst enabled - i.e. in color mode -
shifting the position by a single hi-res char may alter the length of the
detected burst period, and instead of moving the display it'll change the
saturation!  To top it off, in 80-column mode the CGA and CRTC clocks may be
in one of two phases relative to each other, and in 80-column mode this will
also affect the horizontal position.

TV80.COM provides some parameters to control these factors.  While in 80-
column text mode, run it as follows:

TV80 command

where "command" is a single character {+|-|=|p|c|b}.
Position/phase finetuning commands:

  +   Take the currently selected H-position value and offset it by 1 CRTC
      cycle (a "half-step") to the RIGHT

  -   Take the currently selected H-position value and offset it by 1 CRTC
      cycle (a "half-step") to the LEFT

      Note that + and - are non-cumulative; to shift the display by more than
      a "half-step" in either direction, set a new integer value w/ TVCGAFIX.

  =   Restore the currently selected H-position value (remove any modifier
      applied with "+" or "-")

  p   Flip the relative phase of the CGA and CRTC clocks

As mentioned above, the visible effects of these commands may not be exactly
what you'd expect, but experiment with a few of them and you should get a good
result.  In B&W mode, the "half-steps" don't appear to be exactly half-steps,
at least on my setup; in color mode, if a "half-step" modifies the saturation
instead of shifting the picture, go for the whatever gives you the LOWER
saturation as that seems to be more correct.  Flipping the phase with "p"
should then result in a visible half-step shift.

Color burst commands:

  c   Color picture (enable the color burst without switching modes)

  b   B&W picture (disable the color burst without switching modes)

These may come in handy sometimes, e.g. to befuddle 80-column programs that
display differently between color and B&W modes, or if you're stuck with a
piece of text that's infamously difficult to read with color enabled.  Note
that these will also modify the width of the hsync pulse to get the desired
result, which will in turn shift the display as well and may require some of
the other commands to compensate.  In short, experiment.



                        ---  KNOWN ISSUES / TO-DO  ---


* TVCGAFIX won't work with games that don't bother with the BIOS (INT 10h) and
  talk directly to the CRTC to set their video modes.  Since there's no way to
  trap direct hardware access in real mode, not much can be done about that,
  other than patching the game itself.

* Once loaded, TVCGAFIX cannot be removed from memory.  A new position value
  can always be specified, but if you find yourself sorely missing those 336
  bytes of RAM, let me know and I'll see what I can do.

* In B&W modes (color burst disabled), a noisy CGA signal may still fail to
  trigger the TV's color-killer mechanism: this can turn your monochromatic
  picture into a psychedelic neon smear of over-amplified chroma.  That's a
  CGA hardware issue, not a TVCGAFIX problem.  Shortening the hsync pulse
  seems to fix this in most cases, but I haven't included such a feature due
  to... well, indifference.  That may change in a future version however.

* No PCjr/Tandy 1000 support.  These machines could also benefit, since they
  do output composite video, but I don't own the hardware.  If anyone who does
  feels like helping out with testing, let me know.



                           ---  VERSION HISTORY  ---


2018-02:         * Lame version for personal use, fixed-value TSR only

2018-03:         + Added adjustment tool for 80-column text mode

2018-07:         + Added boot-time version

v0.9a (2018-07): + TSR accepts H-position as command line argument
                 * Boot version: don't use INT 19h (doesn't play nice with
                   some versions of the XTIDE Universal BIOS)
                 + Added MAKEBOOT to customize and write the boot disk

v0.9b (2018-07): + Allow changing H-position value if TVCGAFIX already loaded
                 * Improved TVCGAFIX installation check
                 * Resident portion even smaller; save 16 whole bytes of RAM!

v1.0 (2018-08):  * Lots more testing
                 * Bugfix: no more interrupt handler code corruption issues
                 + Added TVCGACAL calibration tool to determine best position
                 + Enhanced TV80 for tweaking 80-column text mode settings
                 * Polished up for release



                               ---  THANKS  ---


reenigne:    General CGA kung-fu
ripsaw8080:  General DOS ninjitsu
Tomi Tilli:  Assistance w/XTIDE Universal BIOS issues



                              ---  CONTACT  ---


Email: viler -AT- int10h -DOT- org
WWW:   http://int10h.org


  -- VileR, 2018-08
