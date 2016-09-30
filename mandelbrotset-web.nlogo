globals [ 
  xmin ymin xmax ymax 
  was-mouse-down? was-mouse-xcor was-mouse-ycor
  was-record-mov was-record-png 
  png-file-prefix png-file-index
  was-multibrot-exp was-generalization
  was-going
  tick-last-change
  max-detectable-period
  was-zoom-power
]

patches-own [ x y real imag was-real was-imag]

to startup
  clear-all
  ; defaults
  set record-mov false set was-record-mov false
  set record-png false set was-record-png false
  set was-mouse-down? false
  set was-going false
  set jump-size 25
  set mouse-zooms-in true
  set max-detectable-period 3
  set was-zoom-power 0
  reset
  ; hint
  output-print "Explore the Mandelbrot set\nand related fractals.\nPress go to get started."
end

to reset
  ; range
  set xmin -2
  set xmax  2
  set ymin -2
  set ymax  2
  zoom
end

to zoom
  ;if not netlogo-web? [if (movie-status != "No movie.") [ movie-grab-view ]]
  if (record-png) [
    ;if not netlogo-web? [export-view ( word png-file-prefix " " was-zoom-power " " png-file-index ".png" ) ]
    set png-file-index png-file-index + 1
    set was-zoom-power zoom-power
  ]
  reset-ticks
  set tick-last-change 20 * ticks-per-zoom ; don't auto-zoom for at least 20 ticks-per-zoom if all black
  set was-multibrot-exp d-multibrot-exp
;  set was-conjugate conjugate
  set was-generalization generalization
  let xslope width  / ( max-pxcor - min-pxcor )
  let yslope height / ( max-pycor - min-pycor )
  ask patches [
    set pcolor black 
    set x (pxcor - min-pxcor) * xslope + xmin
    set y (pycor - min-pycor) * yslope + ymin
    set real 0
    set imag 0
    set was-real []
    set was-imag []
  ]
  ask patch max-pxcor 4 [ set plabel zoom-power ]
end

to go
  ; check for changed parameters
  if (not was-going) [
    output-print "\nDrag the mouse to move or\npress the W/A/S/D keys."
    output-print "Click to zoom or\npress the +/- keys."
    set was-going true
  ]
  if (d-multibrot-exp     != was-multibrot-exp    ) [ 
    zoom 
    output-print "\nChange the multibrot\nexponent d, z->z^d+c."
  ]
  if (generalization != was-generalization) [ 
    zoom 
    output-print "\nChoose a generalization\nof the Mandelbrot set."
  ]
  ; check for changed record switches
  if (record-png and not was-record-png) [
    ; start recording to png
    ;ifelse (netlogo-web?) [
      output-print "\nSorry, can't record from applet."
      output-print "Download the .nlogo file to allow recording."
      set png-file-prefix false
    ;][
    ;  set png-file-prefix user-new-file
    ;]
    ifelse (png-file-prefix != false) [
      ; strip file extension
      set png-file-prefix remove ".PNG" png-file-prefix
      set png-file-prefix remove ".png" png-file-prefix
      set was-record-png true
      set was-zoom-power zoom-power
      output-print "\nStarted recording to png files."
    ][
      ; cancelled
      set record-png false
    ]
  ]
  if (record-mov and not was-record-mov) [
    let mov-file false
    ;ifelse (netlogo-web?) [
      output-print "\nSorry, can't record from applet."
      output-print "Download the .nlogo file to allow recording."
    ;][
    ;  set mov-file user-new-file
    ;]
    ifelse (mov-file != false) [
      ; strip file extension
      set mov-file remove ".MOV" mov-file
      set mov-file remove ".mov" mov-file
      ; add extension
      set mov-file word mov-file ".mov"
      ; start recording to mov
      ;if not netlogo-web? [movie-start mov-file]
      set was-record-mov true
      output-print "\nStarted recording to mov file."
    ][
      ; cancelled
      set record-mov false
    ]
  ]
  if (was-record-mov and not record-mov) [
    ; stop recording mov
    ;if not netlogo-web? [if (movie-status != "No movie.") [ movie-close ]]
    output-print "\nStopped recording to mov file."
  ]
  ; check for mouse activity
  if (mouse-down? and not was-mouse-down?) [
    ; mouse press
    set was-mouse-down? true
    set was-mouse-xcor mouse-xcor
    set was-mouse-ycor mouse-ycor
  ]
  ; check for auto-zoom
  if (was-mouse-down? and not mouse-down?) [
    ; mouse release
    let xslope width  / ( max-pxcor - min-pxcor )
    let yslope height / ( max-pycor - min-pycor )
    if-else (mouse-xcor = was-mouse-xcor and mouse-ycor = was-mouse-ycor) [
      ; click, zoom centered on mouse
      output-type "\nMouse click: zoom "
      let xc (mouse-xcor - min-pxcor) * xslope + xmin
      let yc (mouse-ycor - min-pycor) * yslope + ymin
      let xrad 0
      let yrad 0
      ifelse mouse-zooms-in [
        set xrad  width  * (1 - jump-size / 100) / 2
        set yrad  height * (1 - jump-size / 100) / 2
        output-type "in "
      ][
        set xrad  width  / (1 - jump-size / 100) / 2
        set yrad  height / (1 - jump-size / 100) / 2
        output-type "out "
      ]
      output-type jump-size output-print "%"
      set xmin xc - xrad
      set xmax xc + xrad
      set ymin yc - yrad
      set ymax yc + yrad
    ][
      ; drag
      output-print "\nMouse drag: move"
      let xshift (was-mouse-xcor - mouse-xcor) * xslope
      let yshift (was-mouse-ycor - mouse-ycor) * yslope
      set xmin xmin + xshift
      set xmax xmax + xshift
      set ymin ymin + yshift
      set ymax ymax + yshift
    ]
    set was-mouse-down? false
    zoom
  ]
  
;  let hue ticks mod 256
;  let sat 255 - 20 * int ( ticks / 256 )
  let slow-ticks 1.25 * ticks ^ 0.8 ; increases slower than ticks for large ticks
  let hue slow-ticks mod 360
  let sat 100 - int ( slow-ticks / 33 )
  let conjugate      ( generalization = "Mandelbar, complex conjugate" )
  let absolute-value ( generalization = "Burning ship, absolute value" )
  let changes 0
  ask patches with [pcolor = black] [
    ; iterate z_{n+1} = z_n^2 + (x + i y)
    if (conjugate)      [ set imag ( - imag ) ]
    if (absolute-value) [ set real abs real  set imag abs imag ]
    let oldreal real
    set real x + re-pow real    imag d-multibrot-exp ; Re(z_{n+1}) = x + Re(z_n^multibrot-exp)
    set imag y + im-pow oldreal imag d-multibrot-exp ; Im(z_{n+1}) = x + Im(z_n^multibrot-exp)
    ifelse (real * real + imag * imag) > 4 [ 
      ; diverges
      set pcolor _hsb hue sat 100
      set changes changes + 1
    ][
      ; hasn't diverged.  Check if periodic
      let period position real was-real
      ifelse (period != false and period = position imag was-imag) [
        set period period + 1 ; so not zero
        set pcolor period / 10 ; periodic. Set pcolor to off-black so skipped on next loop
        ; don't track changes here...makes run too long
        ; set changes changes + 1
      ][
        ; not periodic.  Add new (real, imag) to history
        set was-real fput real was-real
        set was-imag fput imag was-imag
        while [length was-real > max-detectable-period] [
          ; trim
          set was-real but-last was-real
          set was-imag but-last was-imag
        ]
      ]
    ]
  ]
  if (changes > 0) [ 
;    if (ticks > tick-last-change + 1) [ print ticks ]
    set tick-last-change ticks
  ]
  tick
end

to zoom-in
  ; zoom in by factor 1 - jump-size
  let newwidth  width  * (1 - jump-size / 100)
  let newheight height * (1 - jump-size / 100)
  let xcrop ( width  - newwidth  ) / 2
  let ycrop ( height - newheight ) / 2
  set xmin xmin + xcrop
  set xmax xmax - xcrop
  set ymin ymin + ycrop
  set ymax ymax - ycrop
  output-type "\nZoom in " output-type jump-size output-print "%"
  zoom
end

to zoom-out
  ; zoom in by factor 1 - jump-size
  let newwidth  width  / (1 - jump-size / 100)
  let newheight height / (1 - jump-size / 100)
  let xcrop ( newwidth  - width  ) / 2
  let ycrop ( newheight - height ) / 2
  set xmin xmin - xcrop
  set xmax xmax + xcrop
  set ymin ymin - ycrop
  set ymax ymax + ycrop
  output-type "\nZoom out " output-type jump-size output-print "%"
  zoom
end

to move-up
  ; shift by jump-size
  let move jump-size / 100 * height
  set ymin ymin + move
  set ymax ymax + move
  output-type "\nMove up " output-type jump-size output-print "%"
  zoom
end

to move-left
  ; shift by jump-size
  let move jump-size / 100 * width
  set xmin xmin - move
  set xmax xmax - move
  output-type "\nMove left " output-type jump-size output-print "%"
  zoom
end

to move-down
  ; shift by jump-size
  let move jump-size / 100 * height
  set ymin ymin - move
  set ymax ymax - move
  output-type "\nMove down " output-type jump-size output-print "%"
  zoom
end

to move-right
  ; shift by jump-size
  let move jump-size / 100 * width
  set xmin xmin + move
  set xmax xmax + move
  output-type "\nMove right " output-type jump-size output-print "%"
  zoom
end

to-report width
  report xmax - xmin
end

to-report height
  report ymax - ymin
end

to toggle-mouse-zoom
  set mouse-zooms-in not mouse-zooms-in
  output-type "\nMouse clicks now zoom " output-print ifelse-value (mouse-zooms-in) [ "in." ][ "out." ]
end

to-report re-pow [ zr zi d ]
; returns Re(z^d) = Re((zr + i zi)^d) via recursion.  Assumes d>=2 is an integer.
  ifelse (d = 2) [
    ; Re(z^2) = zr^2 - zi^2
    report zr * zr - zi * zi
  ][
    ; Re(z^d) = Re(z z^(d-1)) = zr Re(z^(d-1)) - zi Im(z^(d-1))
    report zr * ( re-pow zr zi (d - 1)) - zi * ( im-pow zr zi (d - 1))
  ]
end

to-report im-pow [ zr zi d ]
; returns Im(z^d) = Im((zr + i zi)^d) via recursion.  Assumes d>=2 is an integer
  ifelse (d = 2) [
    ; Im(z^2) = 2 zr zi
    report 2.0 * zr * zi
  ][
    ; Im(z^d) = Im(z z^(d-1)) = zi Re(z^(d-1)) + zr Im(d^(n-1))
    report zi * ( re-pow zr zi (d - 1)) + zr * ( im-pow zr zi (d - 1))
  ]
end

to coords
  ; report coordinates
  output-print "center:"
  output-type  "x = " output-print ( xmin + xmax ) / 2
  output-type  "y = " output-print ( ymin + ymax ) / 2
  let scale xmax - xmin
  output-type  "scale = " output-print ifelse-value (scale <= 0) [ 0 ][ rel-precision scale 2 ]
end

to-report rel-precision [ number places ]
  ; like precision but only for mantissa
  let pow floor log number 10
;  report ( 10 ^ pow ) * precision ( number / 10 ^ pow ) places
  report ( word precision ( number / 10 ^ pow ) places "E" pow )
end


to zoom-every
  if (ticks > ( tick-last-change + ticks-per-zoom ) ) [ 
    ifelse mouse-zooms-in [ 
      zoom-in
      output-print "\nAutomatically zoomed in"
    ][
      zoom-out 
      output-print "\nAutomatically zoomed out"
    ]
    output-type "after " output-type ticks-per-zoom output-print " unchanged ticks."
  ]
end

to-report zoom-power
  report precision ( 0 - log width 10 ) 2
end

;==================== begin hsb.nls ========================================
; _hsb - Reports a RGB list when given three numbers describing an HSB color. Hue, saturation, 
;  and brightness are integers in the range 0-360, 0-100, 0-100 respectively. The RGB list 
;  contains three integers in the range of 0-255.  Like hsb primitive for versions of
;  NetLogo that don't support it.
;
; Converted from <https://github.com/NetLogo/NetLogo/blob/5.x/src/main/org/nlogo/prim/etc/_hsb.scala> 
; and <http://grepcode.com/file/repository.grepcode.com/java/root/jdk/openjdk/6-b14/java/awt/Color.java>
; By Rik Blok, 2015 <http://www.zoology.ubc.ca/~rikblok/wiki/doku.php>
;
; This is free and unencumbered software released into the public domain.
;
; Anyone is free to copy, modify, publish, use, compile, sell, or
; distribute this software, either in source code form or as a compiled
; binary, for any purpose, commercial or non-commercial, and by any
; means.
;
; Example:
;
;  ask patches [ set pcolor _hsb random 360 100 100 ]
;  ;; sets all patches to a random bright color
;
; Revisions:
;
;   2015-07-19 - initial release by Rik Blok
;-------------------------------------------------------------------------------


to-report _hsb [ _hue _saturation _brightness ]
  report hsb_toList 360 100 100 _hue _saturation _brightness
end


to-report _hsbold [ _hue _saturation _brightness ]
  report hsb_toList 255 255 255 _hue _saturation _brightness
end


to-report hsb_toList [ hMax sMax bMax h s b ]
  set h ifelse-value ( h > 0 ) [ h / hMax ][ 0 ]
  set s ifelse-value ( s > 0 ) [ s / sMax ][ 0 ]
  set b ifelse-value ( b > 0 ) [ b / bMax ][ 0 ]
  report HSBtoRGB h s b
end


to-report HSBtoRGB [ _hue _saturation _brightness ]
; Converts the components of a color, as specified by the HSB
; model, to an equivalent set of values for the default RGB model.
; The saturation and brightness components
; should be floating-point values between zero and one
; (numbers in the range 0.0-1.0).  The hue component
; can be any floating-point number.  The floor of this number is
; subtracted from it to create a fraction between 0 and 1.  This
; fractional number is then multiplied by 360 to produce the hue
; angle in the HSB color model.
  let r 0
  let g 0
  let b 0
  if-else _saturation = 0
  [ set r int ( _brightness * 255 + 0.5 )
    set g r
  set b r
  ] ; else
  [ let h ( _hue - floor _hue ) * 6
    let f h - floor h
  let p _brightness * ( 1 - _saturation )
    let q _brightness * ( 1 - _saturation * f )
  let t _brightness * ( 1 - ( _saturation * ( 1 - f ) ) )
  let inth int h
  if inth = 0
  [ set r int ( _brightness * 255 + 0.5 )
    set g int ( t * 255 + 0.5 )
      set b int ( p * 255 + 0.5 )
  ]
  if inth = 1
  [ set r int ( q * 255 + 0.5 )
      set g int ( _brightness * 255 + 0.5 )
      set b int ( p * 255 + 0.5 )
  ]
  if inth = 2
  [ set r int ( p * 255 + 0.5 )
      set g int ( _brightness * 255 + 0.5 )
      set b int ( t * 255 + 0.5 )
  ]
  if inth = 3
  [ set r int ( p * 255 + 0.5 )
    set g int ( q * 255 + 0.5 )
      set b int ( _brightness * 255 + 0.5 )
  ]
  if inth = 4
    [ set r int ( t * 255 + 0.5 )
      set g int ( p * 255 + 0.5 )
      set b int ( _brightness * 255 + 0.5 )
  ]
  if inth = 5
  [ set r int ( _brightness * 255 + 0.5 )
      set g int ( p * 255 + 0.5 )
      set b int ( q * 255 + 0.5 )
  ]
  ]
  report ( list r g b )
end  
;==================== end hsb.nls ========================================
@#$#@#$#@
GRAPHICS-WINDOW
287
42
598
374
-1
-1
1.0
1
12
1
1
1
0
1
1
1
0
300
0
300
1
1
1
ticks
30.0

BUTTON
6
128
227
161
NIL
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

BUTTON
233
42
288
374
<
move-left
NIL
1
T
OBSERVER
NIL
A
NIL
NIL
1

BUTTON
287
10
598
43
/\
move-up
NIL
1
T
OBSERVER
NIL
W
NIL
NIL
1

BUTTON
597
42
652
374
>
move-right
NIL
1
T
OBSERVER
NIL
D
NIL
NIL
1

BUTTON
287
373
598
406
\/
move-down
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
4
220
60
253
NIL
reset
NIL
1
T
OBSERVER
NIL
0
NIL
NIL
1

BUTTON
59
220
143
253
NIL
zoom-in
NIL
1
T
OBSERVER
NIL
+
NIL
NIL
1

BUTTON
143
220
227
253
NIL
zoom-out
NIL
1
T
OBSERVER
NIL
-
NIL
NIL
1

SWITCH
4
292
173
325
mouse-zooms-in
mouse-zooms-in
0
1
-1000

BUTTON
172
292
227
325
toggle
toggle-mouse-zoom
NIL
1
T
OBSERVER
NIL
Z
NIL
NIL
1

SLIDER
59
252
226
285
jump-size
jump-size
1
50
25
1
1
%
HORIZONTAL

SWITCH
4
373
117
406
record-mov
record-mov
1
1
-1000

SLIDER
99
332
228
365
ticks-per-zoom
ticks-per-zoom
5
500
300
5
1
NIL
HORIZONTAL

SWITCH
116
373
228
406
record-png
record-png
1
1
-1000

SLIDER
4
175
111
208
d-multibrot-exp
d-multibrot-exp
2
6
2
1
1
NIL
HORIZONTAL

CHOOSER
110
169
227
214
generalization
generalization
"Mandelbrot, multibrot" "Mandelbar, complex conjugate" "Burning ship, absolute value"
0

OUTPUT
7
10
227
120
11

BUTTON
4
252
60
285
NIL
coords
NIL
1
T
OBSERVER
NIL
C
NIL
NIL
1

BUTTON
4
332
100
365
NIL
zoom-every
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## The Mandelbrot Set

A [NetLogo] model by Rik Blok.

[http://www.zoology.ubc.ca/~rikblok/wiki/doku.php?id=science:popmod:mandelbrot_set:start](http://www.zoology.ubc.ca/~rikblok/wiki/doku.php?id=science:popmod:mandelbrot_set:start)

Explore the [Mandelbrot Set](https://en.wikipedia.org/wiki/Mandelbrot_set) and these related fractals:

  * [Multibrot set](https://en.wikipedia.org/wiki/Multibrot_set)
  * [Mandelbar set](https://en.wikipedia.org/wiki/Tricorn_%28mathematics%29)
  * [Burning ship](https://en.wikipedia.org/wiki/Burning_Ship_fractal)

## Mappings

Each fractal is defined by a [function](https://en.wikipedia.org/wiki/Function_%28mathematics%29) in the [complex plane](https://en.wikipedia.org/wiki/Complex_plane).  Starting with an initial value z=0, each point c in the plane is repeatedly iterated through the map, z &rarr; f(z,c).  The mapping function is characterized by an exponent, d (**d-multibrot-exp** slider in the simulation), as follows:

  * Mandelbrot: f(z,c) = z<sup>2</sup> + c (same as Multibrot with d=2)
  * Multibrot: f(z,c) = z<sup>d</sup> + c
  * Mandelbar: f(z,c) = [Conj](https://en.wikipedia.org/wiki/Complex_conjugate)(z)<sup>d</sup> + c
  * Burning ship: f(z,c) = (|[Re](https://en.wikipedia.org/wiki/Real_part)(z)| + [i](https://en.wikipedia.org/wiki/Imaginary_unit) |[Im](https://en.wikipedia.org/wiki/Imaginary_part)(z)|)<sup>d</sup> + c

A point c is excluded from the set if the value z diverges after repeated iteration.  In the simulation, excluded points are painted a color indicating how many iterations were required to decide they have diverged.  Black points indicate undecided candidates that may belong to the set.  


## Other implementations and examples

This implementation of the Mandelbrot set is neither fast nor beautiful -- it's just a proof of concept and a demonstration of how to code in [NetLogo].  If you're interested in the Mandelbrot set or similar fractals, check out these excellent pages:

  * [Google's Julia Map](http://juliamap.googlelabs.com)
  * [Last Lights On](http://vimeo.com/12185093) - video of Mandelbrot zoom to 10<sup>228</sup>

[NetLogo]: http://ccl.northwestern.edu/netlogo/
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
