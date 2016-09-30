globals [
  last-mouse-x last-mouse-y
  count-alive
  count-patches
  time-elapsed
]
patches-own [
  nbrs
  new-nbrs
]

to startup
  setup
end

to setup
  if (world-size = " 64x64 ") [ resize-world 0  63 0  63 ]
  if (world-size = "128x128") [ resize-world 0 127 0 127 ]
  if (world-size = "256x256") [ resize-world 0 255 0 255 ]
  if (world-size = "512x512") [ resize-world 0 511 0 511 ]
  ;if not netlogo-web? [ set-patch-size (512 / world-width) ]
  clear-all
  ask patches [
    if (random 100 < initial-density) [set pcolor yellow]
  ]
  set count-alive  count patches with [pcolor = yellow]
  set count-patches count patches
  ask patches [
;    set new-nbrs nbr-count
    set new-nbrs count neighbors with [pcolor = yellow]
  ]
  reset-ticks
end

to go
  reset-timer
  ask patches [set nbrs new-nbrs]
  if-else (synchronicity = 100) [
    ; shortcut for perfect synchrony
    ask patches with [pcolor != black or nbrs > 1] [ update ]
  ][
    ; might be faster to select binomial subset of patches for small synchronicity
    ask patches with [pcolor != black or nbrs > 1] [
      if random 100 < synchronicity [ update ]
    ]
  ]
  tick-advance synchronicity / 100
  plotxy ticks  count-alive * 100 / count-patches
  set time-elapsed time-elapsed + timer
end

to update
  ifelse (nbrs = 3) or ((nbrs = 2) and (pcolor = yellow)) [
    turn-on
  ][
    turn-off
  ]
end

to draw
  if mouse-down? [
    ask patch mouse-xcor mouse-ycor [
      if not ((pxcor = last-mouse-x) and (pycor = last-mouse-y)) [ toggle ]
      set last-mouse-x pxcor
      set last-mouse-y pycor
      display
    ]
  ]
end

to turn-on
  if (pcolor != yellow) [ 
    set count-alive  count-alive + 1 
    ask neighbors [
      set new-nbrs  new-nbrs + 1
    ]
  ]
  set pcolor yellow
end

to turn-off
  if (pcolor = yellow) [
    set count-alive  count-alive - 1 
    ask neighbors [
      set new-nbrs  new-nbrs - 1
    ]
  ]
  ; note: color 40=black, 45=yellow
  set pcolor ifelse-value (fade and pcolor > 40) [pcolor - 1] [black]
end

to toggle
  ifelse (pcolor = yellow) [ turn-off ][ turn-on ]
end

to bump
  ask one-of patches with [new-nbrs > 0] [ toggle ]
end
@#$#@#$#@
GRAPHICS-WINDOW
199
10
721
553
-1
-1
4.0
1
10
1
1
1
0
1
1
1
0
127
0
127
1
1
1
ticks
100.0

BUTTON
10
101
188
134
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
10
184
188
217
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
10
143
188
176
synchronicity
synchronicity
1
100
100
1
1
%
HORIZONTAL

SWITCH
10
304
188
337
fade
fade
0
1
-1000

PLOT
11
344
186
494
density
ticks
density (%)
0.0
0.0
0.0
0.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

SLIDER
10
61
188
94
initial-density
initial-density
0
100
10
5
1
%
HORIZONTAL

BUTTON
10
224
188
257
NIL
draw
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
10
264
188
297
NIL
bump
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
10
10
188
55
world-size
world-size
" 64x64 " "128x128" "256x256" "512x512"
1

MONITOR
11
500
186
553
speed (ticks/s)
ticks / time-elapsed
2
1
13

@#$#@#$#@
## Conway's Game of Life

A [NetLogo] model by Rik Blok.

[http://www.zoology.ubc.ca/~rikblok/wiki/doku.php?id=science:conway_s_game_of_life:start](http://www.zoology.ubc.ca/~rikblok/wiki/doku.php?id=science:conway_s_game_of_life:start)

This [NetLogo] model implements [Conway's Game of Life](http://en.wikipedia.org/wiki/Conway%27s%20Game%20of%20Life) a [cellular automaton](http://en.wikipedia.org/wiki/cellular%20automata) [John Horton Conway](http://en.wikipedia.org/wiki/John%20Horton%20Conway) designed to be difficult to anticipate the dynamics of starting patterns.  This implementation incorporates some ideas I focused on in my research: finite-size effects  [[Blok97]] and asynchronous updating [[Blok99]].

## How it works

Each site on the square 2-dimensional lattice can be in one of two states (_alive_ or _dead_).  All sites are updated in parallel according to the following rules: 

  * Loneliness: An _alive_ site with less than two of its 8 nearest neighbours also _alive_ becomes _dead_;
  * Overcrowding: An _alive_ site with more than three _alive_ neighbours becomes _dead_; and
  * Birth: A _dead_ site with exactly three _alive_ neighbours becomes _alive_.

Otherwise, sites remain in the same state.

In this implementation, _alive_ sites are shown in bright yellow.  _Dead_ sites fade to black.

## How to use it

Choose **world-size** and **initial-density** of _alive_ sites and press **setup** to create a random starting configuration.  You may also press **draw** to draw your own starting configuration with the mouse.

Press **go** to repeatedly apply the rules and watch the configuration evolve.  Adjust the **speed slider** at the top as desired.  You may also **draw** while the simulation is going.

You may adjust the **synchronicity** of the simulation -- the fraction of sites that are updated on each iteration.  When **synchronicity**=100% we have Conway's original Game of Life.  As **synchronicity** is reduced some sites are skipped in each step, so the dynamics start to deviate from Conway's.  As **synchronicity** approaches 0% most sites are not updated in any one iteration, and the simulation approaches asynchrony -- almost the same as one site updating at a time.  Notice how the patterns differ as **synchronicity** varies.

To perturb a configuration -- by toggling one site -- press **bump**.  You may want to do this once the dynamics have settled to a stable (or simply repeating) pattern.  Some bumps will have little effect but occasionally they will cascade through the whole space, changing the entire system.  It is difficult to predict the size of the cascade.

## Things to notice

Since there are a fixed, finite number _N_ of sites there are only a finite number of possible configurations (2^_N_) and the configuration must necessarily repeat as it evolves.  In principle the period between repeating configurations could be anything up to 2^_N_ but in practice it is much shorter: typically 1 or 2.  A notable exception can occur when **synchronicity**=100% and a [glider](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life#Examples_of_patterns) is present -- rarely a glider may travel around the entire length of the space and return to its original position.

## Things to try

### Draw

Try drawing your own starting configuration.  Set the **initial-density**=0% and press **setup** to set all sites to _dead_.  Press the **draw** button to activate drawing mode, then use the mouse to draw a shape, such as the [R-pentomino](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life#Examples_of_patterns).

### Boundary conditions

This implementation defaults to _periodic_ boundary conditions: the left side can be thought of as wrapping around to touch the right and the top touches the bottom.  In the native version of NetLogo (not the applet) you can switch to _cold_ boundaries where any sites outside of the visible area are assumed to be _dead_ -- press **Settings...** at the top-right of the interface and toggle the **World wraps...** checkboxes.  Notice that periodic boundaries reduce edge effects [[Blok97]].

## References

[[Blok97]] Hendrik J. Blok and Birger Bergersen. [Effect of boundary conditions on scaling in the "game of Life"](http://www.zoology.ubc.ca/~rikblok/wiki/lib/exe/fetch.php?media=ref:rik:blok97.pdf). _Phys. Rev. E_, 55:6249-52. doi:[10.1103/PhysRevE.55.6249](http://dx.doi.org/10.1103/PhysRevE.55.6249). 1997. 

[[Blok99]] Hendrik J. Blok and Birger Bergersen. [Synchronous versus asynchronous updating in the "game of life"](http://www.zoology.ubc.ca/~rikblok/wiki/lib/exe/fetch.php?media=ref:rik:blok99.pdf). _Phys. Rev. E_, 59:3876-9. doi:[10.1103/PhysRevE.59.3876](http://dx.doi.org/10.1103/PhysRevE.59.3876). 1999. 

[[NetLogo]] Wilensky, U. NetLogo. [http://ccl.northwestern.edu/netlogo/](http://ccl.northwestern.edu/netlogo/). Center for Connected Learning and Computer-Based Modeling, Northwestern University. Evanston, IL. 1999.

[Blok97]: http://www.zoology.ubc.ca/~rikblok/wiki/lib/exe/fetch.php?media=ref:rik:blok97.pdf
[Blok99]: http://www.zoology.ubc.ca/~rikblok/wiki/lib/exe/fetch.php?media=ref:rik:blok99.pdf
[NetLogo]: http://ccl.northwestern.edu/netlogo/
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

ant
true
0
Polygon -7500403 true true 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -7500403 true true 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -7500403 true true 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -7500403 true true 225 66 230 107 159 122 161 127 234 111 236 106
Polygon -7500403 true true 78 58 99 116 139 123 137 128 95 119
Polygon -7500403 true true 48 103 90 147 129 147 130 151 86 151
Polygon -7500403 true true 65 224 92 171 134 160 135 164 95 175
Polygon -7500403 true true 235 222 210 170 163 162 161 166 208 174
Polygon -7500403 true true 249 107 211 147 168 147 168 150 213 150

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bee
true
0
Polygon -1184463 true false 152 149 77 163 67 195 67 211 74 234 85 252 100 264 116 276 134 286 151 300 167 285 182 278 206 260 220 242 226 218 226 195 222 166
Polygon -16777216 true false 150 149 128 151 114 151 98 145 80 122 80 103 81 83 95 67 117 58 141 54 151 53 177 55 195 66 207 82 211 94 211 116 204 139 189 149 171 152
Polygon -7500403 true true 151 54 119 59 96 60 81 50 78 39 87 25 103 18 115 23 121 13 150 1 180 14 189 23 197 17 210 19 222 30 222 44 212 57 192 58
Polygon -16777216 true false 70 185 74 171 223 172 224 186
Polygon -16777216 true false 67 211 71 226 224 226 225 211 67 211
Polygon -16777216 true false 91 257 106 269 195 269 211 255
Line -1 false 144 100 70 87
Line -1 false 70 87 45 87
Line -1 false 45 86 26 97
Line -1 false 26 96 22 115
Line -1 false 22 115 25 130
Line -1 false 26 131 37 141
Line -1 false 37 141 55 144
Line -1 false 55 143 143 101
Line -1 false 141 100 227 138
Line -1 false 227 138 241 137
Line -1 false 241 137 249 129
Line -1 false 249 129 254 110
Line -1 false 253 108 248 97
Line -1 false 249 95 235 82
Line -1 false 235 82 144 100

bird1
false
0
Polygon -7500403 true true 2 6 2 39 270 298 297 298 299 271 187 160 279 75 276 22 100 67 31 0

bird2
false
0
Polygon -7500403 true true 2 4 33 4 298 270 298 298 272 298 155 184 117 289 61 295 61 105 0 43

boat1
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 33 230 157 182 150 169 151 157 156
Polygon -7500403 true true 149 55 88 143 103 139 111 136 117 139 126 145 130 147 139 147 146 146 149 55

boat2
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 157 54 175 79 174 96 185 102 178 112 194 124 196 131 190 139 192 146 211 151 216 154 157 154
Polygon -7500403 true true 150 74 146 91 139 99 143 114 141 123 137 126 131 129 132 139 142 136 126 142 119 147 148 147

boat3
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 37 172 45 188 59 202 79 217 109 220 130 218 147 204 156 158 156 161 142 170 123 170 102 169 88 165 62
Polygon -7500403 true true 149 66 142 78 139 96 141 111 146 139 148 147 110 147 113 131 118 106 126 71

box
true
0
Polygon -7500403 true true 45 255 255 255 255 45 45 45

butterfly1
true
0
Polygon -16777216 true false 151 76 138 91 138 284 150 296 162 286 162 91
Polygon -7500403 true true 164 106 184 79 205 61 236 48 259 53 279 86 287 119 289 158 278 177 256 182 164 181
Polygon -7500403 true true 136 110 119 82 110 71 85 61 59 48 36 56 17 88 6 115 2 147 15 178 134 178
Polygon -7500403 true true 46 181 28 227 50 255 77 273 112 283 135 274 135 180
Polygon -7500403 true true 165 185 254 184 272 224 255 251 236 267 191 283 164 276
Line -7500403 true 167 47 159 82
Line -7500403 true 136 47 145 81
Circle -7500403 true true 165 45 8
Circle -7500403 true true 134 45 6
Circle -7500403 true true 133 44 7
Circle -7500403 true true 133 43 8

circle
false
0
Circle -7500403 true true 35 35 230

person
false
0
Circle -7500403 true true 155 20 63
Rectangle -7500403 true true 158 79 217 164
Polygon -7500403 true true 158 81 110 129 131 143 158 109 165 110
Polygon -7500403 true true 216 83 267 123 248 143 215 107
Polygon -7500403 true true 167 163 145 234 183 234 183 163
Polygon -7500403 true true 195 163 195 233 227 233 206 159

sheep
false
15
Rectangle -1 true true 90 75 270 225
Circle -1 true true 15 75 150
Rectangle -16777216 true false 81 225 134 286
Rectangle -16777216 true false 180 225 238 285
Circle -16777216 true false 1 88 92

spacecraft
true
0
Polygon -7500403 true true 150 0 180 135 255 255 225 240 150 180 75 240 45 255 120 135

thin-arrow
true
0
Polygon -7500403 true true 150 0 0 150 120 150 120 293 180 293 180 150 300 150

truck-down
false
0
Polygon -7500403 true true 225 30 225 270 120 270 105 210 60 180 45 30 105 60 105 30
Polygon -8630108 true false 195 75 195 120 240 120 240 75
Polygon -8630108 true false 195 225 195 180 240 180 240 225

truck-left
false
0
Polygon -7500403 true true 120 135 225 135 225 210 75 210 75 165 105 165
Polygon -8630108 true false 90 210 105 225 120 210
Polygon -8630108 true false 180 210 195 225 210 210

truck-right
false
0
Polygon -7500403 true true 180 135 75 135 75 210 225 210 225 165 195 165
Polygon -8630108 true false 210 210 195 225 180 210
Polygon -8630108 true false 120 210 105 225 90 210

turtle
true
0
Polygon -7500403 true true 138 75 162 75 165 105 225 105 225 142 195 135 195 187 225 195 225 225 195 217 195 202 105 202 105 217 75 225 75 195 105 187 105 135 75 142 75 105 135 105

wolf
false
0
Rectangle -7500403 true true 15 105 105 165
Rectangle -7500403 true true 45 90 105 105
Polygon -7500403 true true 60 90 83 44 104 90
Polygon -16777216 true false 67 90 82 59 97 89
Rectangle -1 true false 48 93 59 105
Rectangle -16777216 true false 51 96 55 101
Rectangle -16777216 true false 0 121 15 135
Rectangle -16777216 true false 15 136 60 151
Polygon -1 true false 15 136 23 149 31 136
Polygon -1 true false 30 151 37 136 43 151
Rectangle -7500403 true true 105 120 263 195
Rectangle -7500403 true true 108 195 259 201
Rectangle -7500403 true true 114 201 252 210
Rectangle -7500403 true true 120 210 243 214
Rectangle -7500403 true true 115 114 255 120
Rectangle -7500403 true true 128 108 248 114
Rectangle -7500403 true true 150 105 225 108
Rectangle -7500403 true true 132 214 155 270
Rectangle -7500403 true true 110 260 132 270
Rectangle -7500403 true true 210 214 232 270
Rectangle -7500403 true true 189 260 210 270
Line -7500403 true 263 127 281 155
Line -7500403 true 281 155 281 192

wolf-left
false
3
Polygon -6459832 true true 117 97 91 74 66 74 60 85 36 85 38 92 44 97 62 97 81 117 84 134 92 147 109 152 136 144 174 144 174 103 143 103 134 97
Polygon -6459832 true true 87 80 79 55 76 79
Polygon -6459832 true true 81 75 70 58 73 82
Polygon -6459832 true true 99 131 76 152 76 163 96 182 104 182 109 173 102 167 99 173 87 159 104 140
Polygon -6459832 true true 107 138 107 186 98 190 99 196 112 196 115 190
Polygon -6459832 true true 116 140 114 189 105 137
Rectangle -6459832 true true 109 150 114 192
Rectangle -6459832 true true 111 143 116 191
Polygon -6459832 true true 168 106 184 98 205 98 218 115 218 137 186 164 196 176 195 194 178 195 178 183 188 183 169 164 173 144
Polygon -6459832 true true 207 140 200 163 206 175 207 192 193 189 192 177 198 176 185 150
Polygon -6459832 true true 214 134 203 168 192 148
Polygon -6459832 true true 204 151 203 176 193 148
Polygon -6459832 true true 207 103 221 98 236 101 243 115 243 128 256 142 239 143 233 133 225 115 214 114

wolf-right
false
3
Polygon -6459832 true true 170 127 200 93 231 93 237 103 262 103 261 113 253 119 231 119 215 143 213 160 208 173 189 187 169 190 154 190 126 180 106 171 72 171 73 126 122 126 144 123 159 123
Polygon -6459832 true true 201 99 214 69 215 99
Polygon -6459832 true true 207 98 223 71 220 101
Polygon -6459832 true true 184 172 189 234 203 238 203 246 187 247 180 239 171 180
Polygon -6459832 true true 197 174 204 220 218 224 219 234 201 232 195 225 179 179
Polygon -6459832 true true 78 167 95 187 95 208 79 220 92 234 98 235 100 249 81 246 76 241 61 212 65 195 52 170 45 150 44 128 55 121 69 121 81 135
Polygon -6459832 true true 48 143 58 141
Polygon -6459832 true true 46 136 68 137
Polygon -6459832 true true 45 129 35 142 37 159 53 192 47 210 62 238 80 237
Line -16777216 false 74 237 59 213
Line -16777216 false 59 213 59 212
Line -16777216 false 58 211 67 192
Polygon -6459832 true true 38 138 66 149
Polygon -6459832 true true 46 128 33 120 21 118 11 123 3 138 5 160 13 178 9 192 0 199 20 196 25 179 24 161 25 148 45 140
Polygon -6459832 true true 67 122 96 126 63 144

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
