; everything after a semicolon is a 'comment' and ignored by NetLogo
;---------------------------------------------------------

globals            ; variables common to whole model
[ num-platforms      ; number of platforms
  patches-on-path    ; all platforms and bridge patches
  start-patch        ; patch where dwarves start
  finish-patch       ; patch dwarves are trying to get to
  num-dwarves        ; number of dwarves at start
  num-living-dwarves ; number of dwarves not killed by nasty goblins
]
patches-own              ; variables held by each patch
[ platform-index           ; each platform is numbered.  Used to connect platforms via bridges
  dwarf-sounds             ; how loud the dwarves sound here.  Can be used to chase/evade dwarves
  goblin-sounds            ; how loud the goblins sound here.  Can be used to chase/evade goblins
  on-path?                 ; true if patch is part of path (platform or bridge), otherwise false
  diffuse-on-path-var      ; used to spread sounds around
  escape-light             ; how bright light from escape is here.  Used to find escape
  neighbours-on-path       ; set of all neighbouring patches also on path.  Improves simulation speed
  count-neighbours-on-path ; count of neighbours also on path.  Improves simulation speed
  diffuse-fraction         ; controls how much scent is spread to neighbours
]
; define goblin and dwarf breeds
breed [ dwarves dwarf  ]
breed [ goblins goblin ]

; both dwarves and goblins have some health, dwarves also have names
dwarves-own [health name]
goblins-own [health]

;---------------------------------------------------------

to turn-dwarf
  ;;;;;; YOUR CODE GOES HERE!
   face-towards-escape
end

;---------------------------------------------------------

to turn-goblin
  ;;;;;; YOUR CODE GOES HERE!
  face-random-direction
end

;---------------------------------------------------------

; a bunch of one-liner face-... procedures
to face-towards-escape          face max-one-of neighbors [escape-light]               end
to face-away-from-escape        face-towards-escape                       right 180 end
to face-towards-dwarf-sounds    face max-one-of neighbors [dwarf-sounds]            end
to face-away-from-dwarf-sounds  face-towards-dwarf-sounds                 right 180 end
to face-towards-goblin-sounds   face max-one-of neighbors [goblin-sounds]           end
to face-away-from-goblin-sounds face-towards-goblin-sounds                right 180 end
to face-random-direction        right random 360                                    end

;---------------------------------------------------------

to face-towards-nearby-dwarf
  ; will only change direction if there is a neighboring dwarf
  let dwarf-nbrs dwarves-on neighbours-on-path
  if any? dwarf-nbrs [ face one-of dwarf-nbrs ]
end

;---------------------------------------------------------

to face-away-from-nearby-goblin
  ; will only change direction if there is a neighboring goblin
  let goblin-nbrs goblins-on neighbours-on-path
  if any? goblin-nbrs [ face one-of goblin-nbrs  right 180 ]
end

;---------------------------------------------------------

to face-towards-leading-dwarf
  if not any? dwarves [ stop ] ; stop when last dwarf gone
  ; will only change direction if not leading dwarf
  let leading-dwarf-escape-light max [ escape-light ] of dwarves
  if escape-light = leading-dwarf-escape-light [ stop ] ; this dwarf *is* a leading dwarf
  face one-of dwarves with [ escape-light = leading-dwarf-escape-light ]
end

;---------------------------------------------------------

to face-towards-trailing-dwarf
  if not any? dwarves [ stop ] ; stop when last dwarf gone
  ; will only change direction if not trailing dwarf
  let trailing-dwarf-escape-light min [ escape-light ] of dwarves
  if escape-light = trailing-dwarf-escape-light [ stop ] ; this dwarf *is* a trailing dwarf
  face one-of dwarves with [ escape-light = trailing-dwarf-escape-light ]
end

;---------------------------------------------------------

; 'startup' procedure is run when model first loaded
to startup
  output-print "Escape from Goblin-town!"
  output-print "Press 'setup' to begin."
end

;---------------------------------------------------------

; 'setup' procedure is run when user presses 'setup' button
to setup
  clear-all
  setup-platforms
  setup-bridges
  setup-dwarves 13
  setup-goblins
  setup-sounds
  reset-ticks
  output-print "Press 'go' to play."
end

;---------------------------------------------------------

; 'go' is the main loop.  It is called repeatedly while the 'go' button is held down
to go
  dwarves-fight-goblins
  move-dwarves
  move-goblins
  draw-patches
  tick
  if not any? dwarves
  [ output-print "" ; blank line
    ifelse num-living-dwarves = num-dwarves
    [ output-print "All the dwarves escaped!"
    ]
    [ output-print (word num-living-dwarves " of " num-dwarves " dwarves escaped!")
      output-print "Sadly, the others were"
      output-print "murdered by goblins :'("
    ]
    output-print (word "in " ticks " ticks.")
    output-print ""
    output-print "Press 'setup' to try again."
    stop
  ]
end

;---------------------------------------------------------

to setup-platforms
  output-type "Setting up platforms ... "
  ; divide space into square grid of platforms
  let grid-size maze-complexity + 1
  set num-platforms grid-size ^ 2
  ; create a shuffled list of numbers [2 ... num-platforms - 1]
  let platform-list shuffle n-values (num-platforms - 2) [? + 2]
  ; add leading 1 and trailing num-platforms
  set platform-list fput 1 lput num-platforms platform-list
  ; place platforms on grid
  let grid-x-spacing world-width  / grid-size
  let grid-y-spacing world-height / grid-size
  let platform-y-cor world-height - grid-y-spacing / 2 ; start at top
  ; outer loop: iterate down
  repeat grid-size
  [ let platform-x-cor grid-x-spacing / 2 ; start at left
    ; inner loop: iterate right
    repeat grid-size
    [ ; nudge platform so it's not in exact center of grid point
      let nudge-x random-float grid-x-spacing / 1.5 - grid-x-spacing / 3
      let nudge-y random-float grid-y-spacing / 1.5 - grid-y-spacing / 3
      ask patch (platform-x-cor + nudge-x) (platform-y-cor + nudge-y)
      [ set platform-index first platform-list
        set pcolor white
      ]
      set platform-list but-first platform-list
      set platform-x-cor platform-x-cor + grid-x-spacing
    ]
    set platform-y-cor platform-y-cor - grid-y-spacing
  ]
  ; grow platforms
  ask patches with [pcolor = white]
  [ let platform-radius 0.25 * random-float min list grid-x-spacing grid-y-spacing
    ask patches in-radius platform-radius [ set pcolor white ]
  ]
  ; define start and finish patches
  set start-patch  one-of patches with [platform-index = 1]
  set finish-patch one-of patches with [platform-index = num-platforms]
  output-print "done."
end

;---------------------------------------------------------

to setup-bridges
  output-type "Setting up bridges ... "
  ; run a turtle from one platform to next
  ask patches with [platform-index > 1]
  [ let goal-platform platform-index - 1
    sprout 1
    [ set color white
      face one-of patches with [platform-index = goal-platform]
      while [platform-index != goal-platform]
      [ forward 1
        set pcolor white
      ]
      die
    ]
  ]
  ; grow bridges & platforms
  ask patches with [pcolor = white]
  [ ask patches in-radius 1 [ set pcolor white ]
  ]
  ; define patches-on-path agentset
  set patches-on-path patches with [pcolor = white]
  ; mark all patches as not on-path
  ask patches [ set on-path? false ]
  ; then correct the ones that are on-path
  ask patches-on-path [ set on-path? true ]
  ; define neighbours-on-path
  ask patches-on-path
  [ set neighbours-on-path neighbors with [ on-path? ]
    set count-neighbours-on-path count neighbours-on-path
    set diffuse-fraction 1 / ( 1 + count-neighbours-on-path )
  ]
  output-print "done."
end

;---------------------------------------------------------

to setup-sounds
  output-type "Setting up sounds ... "
  ; setup escape-light on path
  ask finish-patch [ set escape-light count patches ] ; a big positive number
  while [ any? patches-on-path with [escape-light = 0] ]
  [ ask patches-on-path with [ escape-light = 0 ]
    [ let neighbours-escape-light neighbours-on-path with [escape-light > 0]
      if any? neighbours-escape-light
      [ set escape-light (max [escape-light] of neighbours-escape-light) - 1
      ]
    ]
    diffuse-dwarf-sounds-on-path
    diffuse-goblin-sounds-on-path
  ]
  draw-patches
  ; highlight finish patch
  ask finish-patch
  [ set pcolor sky
    set plabel-color sky
    set plabel "Escape! "
  ]
  output-print "done."
end

;---------------------------------------------------------

to setup-dwarves [ num-dwarves-param ]
  output-print (word "Setting up " num-dwarves-param " dwarves ... ")
  set num-dwarves num-dwarves-param
  set num-living-dwarves num-dwarves
  let names
  [ "Dwalin" "Balin" "Kili" "Fili" "Dori" "Nori" "Ori"
    "Oin" "Gloin" "Bifur" "Bofur" "Bombur" "Thorin"
  ]
  set-default-shape dwarves "person"
  create-dwarves num-dwarves
  [ set color brown
    move-to start-patch
    forward random-float 1
    ; make dwarves stronger than goblins.
    ; match total health for all dwarves = goblins
    set health round ( 2 * num-goblins / num-dwarves )
    set size 5
    set name first names
    set label word name "   "
    set label-color brown
    set names but-first names
    output-print word " ... " name
  ]
  output-print " ... done."
end

;---------------------------------------------------------

to setup-goblins
  output-type "Setting up goblins ... "
  set-default-shape goblins "person"
  create-goblins num-goblins
  [ set color green
    move-to one-of patches-on-path
    set size 4
    set health 2
  ]
  output-print "done."
end

;---------------------------------------------------------

to diffuse-dwarf-sounds-on-path
; Same as diffuse but only over patches on path.
  ask dwarves [ set dwarf-sounds 100 ]
  ask patches-on-path
  [ ; change = incoming - outgoing
    set diffuse-on-path-var diffuse-fraction
                               * ( sum [ dwarf-sounds ] of neighbours-on-path
                                   - count-neighbours-on-path * dwarf-sounds
                                 )
  ]
  ask patches-on-path
  [ set dwarf-sounds dwarf-sounds + diffuse-on-path-var
  ]
  ask dwarves [ set dwarf-sounds 100 ]
  ask patches-on-path [ set dwarf-sounds 0.5 * dwarf-sounds ]
end

;---------------------------------------------------------

to diffuse-goblin-sounds-on-path
; Same as diffuse but only over patches on path.
  ask goblins [ set goblin-sounds 100 ]
  ask patches-on-path
  [ ; change = incoming - outgoing
    set diffuse-on-path-var diffuse-fraction
                               * ( sum [ goblin-sounds ] of neighbours-on-path
                                   - count-neighbours-on-path * goblin-sounds
                                 )
  ]
  ask patches-on-path
  [ set goblin-sounds goblin-sounds + diffuse-on-path-var
  ]
  ask goblins [ set goblin-sounds 100 ]
  ask patches-on-path [ set goblin-sounds 0.5 * goblin-sounds ]
end

;---------------------------------------------------------

to dwarves-fight-goblins
  ask dwarves
  [ ; dwarf fights off a goblin
    if any? goblins-here
    [ ;;output-print (word name "fighting goblin!")
      ; goblin wounded
      ask one-of goblins-here
      [ set health health - 1
        if health <= 0 [ die ]
      ]
      ; dwarf wounded
      set health health - 1
      if health <= 0
      [ output-print (word name " killed by goblin!")
        set num-living-dwarves num-living-dwarves - 1
        die
      ]
    ]
  ]
end

;---------------------------------------------------------

to move-dwarves
  ask dwarves
  [ if any? goblins-here [ stop ] ; don't move if fighting with goblins
    turn-dwarf
    wiggle 30
    forward-on-path 1
    if patch-here = finish-patch
    [ output-print (word name " escaped!")
      ; remove dwarf
      die
    ]
  ]
  repeat 3 [ diffuse-dwarf-sounds-on-path ]
end

;---------------------------------------------------------

to move-goblins
  ask goblins
  [ if any? dwarves-here [ stop ] ; don't move if fighting with dwarves
    turn-goblin
    wiggle 30
    forward-on-path 1.1 ; goblins are a bit faster than dwarves
  ]
  repeat 3 [ diffuse-goblin-sounds-on-path ]
end

;---------------------------------------------------------

to forward-on-path [ speed ]
  ; make sure goblin stays on path
  let lastx xcor let lasty ycor
  jump speed
  while [not on-path?]
  [ setxy lastx lasty
    wiggle 30
    jump speed
  ]
end

;---------------------------------------------------------

to wiggle [ angle ]
  right random angle
  left  random angle
end

;---------------------------------------------------------

to loop-go
  loop
  [ go
    if not any? dwarves [ stop ]
  ]
end

;---------------------------------------------------------

to experiment
  ; only allow to run natively.  May crash browser.
  if netlogo-web?
  [ output-print ""
    output-print "Sorry, experiment not available in web browser."
    output-print ""
    stop
  ]
  ; else, if running natively, do experiment
  type (word trials " trials @ " date-and-time ".  Dwarves escaped: ")
  repeat trials
  [ setup
    loop-go
    type (word num-living-dwarves " ")
  ]
  print "...done!"
end

;---------------------------------------------------------

to draw-patches
  ; colour patches by proximity to escape
  if draw = "escape-light"
  [ let min-escape-light (min [escape-light] of patches-on-path)
    ask patches-on-path
    [ set pcolor scale-color white escape-light min-escape-light [escape-light] of finish-patch
    ]
  ]
  ; colour patches by proximity to dwarf
  if draw = "dwarf-sounds"
  [ ask patches-on-path
    [ set pcolor scale-color blue sqrt sqrt sqrt sqrt sqrt dwarf-sounds -0.2 1
    ]
  ]
  ; colour patches by proximity to goblin
  if draw = "goblin-sounds"
  [ ask patches-on-path
    [  set pcolor scale-color red sqrt sqrt sqrt sqrt sqrt goblin-sounds -0.2 1
    ]
  ]
end

;---------------------------------------------------------
@#$#@#$#@
GRAPHICS-WINDOW
263
10
713
401
-1
-1
4.0
1
20
1
1
1
0
0
0
1
0
109
0
89
0
0
1
ticks
30.0

BUTTON
180
10
253
75
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

SLIDER
9
10
181
43
maze-complexity
maze-complexity
1
5
3
1
1
NIL
HORIZONTAL

BUTTON
179
80
253
125
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
9
42
181
75
num-goblins
num-goblins
20
180
180
20
1
NIL
HORIZONTAL

OUTPUT
10
180
253
363
10

MONITOR
9
80
180
125
NIL
num-living-dwarves
0
1
11

SLIDER
10
368
171
401
trials
trials
1
21
7
2
1
NIL
HORIZONTAL

BUTTON
170
368
254
401
NIL
experiment
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
9
131
253
176
draw
draw
"escape-light" "dwarf-sounds" "goblin-sounds"
2

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

* start with both dwarves & goblins moving randomly
* as a group, think about and write code for dwarves, see results
* as a group, think about and write code for goblins, see results
* challenge 1: write better code for dwarves
* submit code.  Test on main screen, award prizes
* use winning code
* challenge 2: write better code for goblins
* submit code.  Test on main screen, award prizes



(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
NetLogo 5.3.1
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
