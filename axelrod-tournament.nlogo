turtles-own
[ my-name
  ; strategy
  c-on-first
  c-after-cc
  c-after-cd
  c-after-dc
  c-after-dd
  ; statistics
  rounds-played
  rounds-cooperated
  total-score
  avg-coop
  avg-score
]


to presets
  reset-same-players
  add-2016w
  add-common
  ; zero-determinant strategies
  add-extortionist
  add-equalizer
  add-generous
end


to add-2016w
  ;            Name      1st  CC  CD  DC  DD
  add-preset "*2016W*"   100 100  50  25  80
  add-preset "Al"        100 100  50 100   0
  add-preset "An1"       100 100   0   0   0
  add-preset "An2"        97 100  10  60  30
  add-preset "Br"        100 100  30 100  35
  add-preset "Ca1"        28 100  45  45  78
  add-preset "Ca2"       100 100   0   0 100
  add-preset "Ca3"       100 100   0 100  30
  add-preset "Ch1"       100 100   0 100  30
  add-preset "Ch2"       100 100   0   0 100
  add-preset "Da"        100 100   0   0 100
  add-preset "Do"        100   0  50  50   0
  add-preset "Ed"        100 100   0 100   0
  add-preset "Em"        100 100   0 100   0
  add-preset "Eu"        100 100   0   0   0
  add-preset "Ev"        100 100   0   0 100
  add-preset "Ha"        100 100   0   0   0
  add-preset "He"        100 100  50   0 100
  add-preset "Hu"        100 100   0 100   0
  add-preset "Ja1"       100 100   0   0  80
  add-preset "Ja2"       100 100   0   0   0
  add-preset "Je"        100 100   0   0   0
  add-preset "Ju"         50  65  35   0   0
  add-preset "Ka"        100   0   0   0   0
  add-preset "Ke1"        60  80   0   0  80
  add-preset "Ke2"       100 100   0 100   0
  add-preset "Le"        100 100   0 100  25
  add-preset "Mi"        100 100   0   0   0
  add-preset "Ne"        100 100   0 100   0
  add-preset "Ra"        100 100   0 100   0
  add-preset "Sa"        100 100   0   0   2
  add-preset "Sh1"       100 100   0 100   0
  add-preset "Sh2"       100 100   0   0  50
  add-preset "Su"        100 100   0 100  20
  add-preset "Ta1"       100 100   0   0  50
  add-preset "Ta2"       100 100  15  75  30
  add-preset "Ti"        100 100   0   0 100
end


to add-common
; common strategies
  add-preset "*AllD*"      0   0   0   0   0
  add-preset "*AllC*"    100 100 100 100 100
  add-preset "*TFT*"     100 100   0 100   0
  add-preset "*Pavlov*"  100 100   0   0 100
  add-preset "*Grim*"    100 100   0   0   0
end


to add-extortionist
; requests 25% more than opponent
  add-preset "*Extortionist*"  90 90  5 85  0
end


to add-equalizer
; sets the opponents payoff to c, i.e. 1 in our case
  add-preset "*Equalizer*"  75 75 50 50 25
end


to add-generous
; ensures that difference to the social optimum R is 20% smaller for opponent
; (tft is the limiting case, requesting that the differences to R are the same for both players)
  add-preset "*Generous*" 100 100 15 95 10
end


to startup
  reset-new-players
end


to reset-new-players
  clear-all
  set-default-shape turtles "circle"
  print date-and-time
end


to add-preset [ pre-name pre-c-on-first pre-c-after-cc pre-c-after-cd pre-c-after-dc pre-c-after-dd ]
; create a new player with preset strategy
  set name pre-name
  set C_on_1st   pre-c-on-first
  set C_after_CC pre-c-after-cc
  set C_after_CD pre-c-after-cd
  set C_after_DC pre-c-after-dc
  set C_after_DD pre-c-after-dd
  add-player
  ; erase values
  set name ""
  set C_on_1st   random 100
  set C_after_CC random 100
  set C_after_CD random 100
  set C_after_DC random 100
  set C_after_DD random 100
end


to random-player
; create a new player with randomly-chosen strategy
  set C_on_1st   random 100
  set C_after_CC random 100
  set C_after_CD random 100
  set C_after_DC random 100
  set C_after_DD random 100
  add-player
end


to add-player
; create a new player with strategy chosen by user
  create-turtles 1
  [ set my-name name
    ; turn percents into numbers (0=defect, 1=cooperate)
    set c-on-first C_on_1st / 100
    set c-after-cc C_after_CC / 100
    set c-after-cd C_after_CD / 100
    set c-after-dc C_after_DC / 100
    set c-after-dd C_after_DD / 100
    if my-name = "" ; if no name build name from strategy
    [ set my-name
      ( word coop-to-letter c-on-first
             coop-to-letter c-after-cc
             coop-to-letter c-after-cd
             coop-to-letter c-after-dc
             coop-to-letter c-after-dd
      )
    ]
    setxy random-xcor random-ycor
    set label-color yellow
    draw-node
    while [xcor < -10] [ set xcor random-xcor ] ; shift to the right to make label visible
    create-links-with other turtles [ hide-link ]
  ]
  ; nudge turtles to fit new one in
  repeat 50 [ layout-spring turtles links 0.2 17 1 ]
  ask turtles [ set label-color white ]
end


to draw-node
; update node: size indicates score and color indicates level of cooperation
  if-else rounds-played > 0
  [ set color hsb ( 120 * avg-coop ) 75 75 ; green = cooperate, red = defect
  ][
    set color gray
  ]
  ; size: -c => minimum, b => b + c + minimum
  set size avg-score + cost-to-self + 0.05
  set label (word my-name " (" precision avg-score 2 ")  ")
end


to reset-same-players
; reset tournament but keep same players
  ask links [ die ]
  ask turtles
  [ create-links-with other turtles [ hide-link ]
    set rounds-played     0
    set rounds-cooperated 0
    set total-score       0
    set avg-coop          0
    set avg-score         0
    draw-node
  ]
  ; space nodes out to make easier to see
  repeat 50 [ layout-spring turtles links 0.2 17 1 ]
  print date-and-time
end


to go
; the main loop.  Play pairs of strategies against each other.
; This loop is repeated for all possible pairs.
; When no more pairs left, tournament ends.
  if not any? links
  [ ; end of tournament
    if play-self
    [ ask turtles [ play-against-self ]
    ]
    print "Player\tCoop\tScore"
    foreach sort-on [avg-score] turtles
    [ ask ? [ print (word my-name "\t" precision avg-coop 2 "\t" precision avg-score 2) ]
    ]
    print "Player\tCoop\tScore"
    stop
  ]
  if not any? links with [hidden? = false] [match-partners]
  ; just do one link per go loop so that web version updates graphics in-between
  ask one-of links with [hidden? = false] [ play die ]
end


to match-partners
; try to find a partner for every player
  ask turtles
  [
    ; if I don't have a partner
    if not-partnered-yet?
    [ let potential-partners link-neighbors with [ not-partnered-yet? ]
      ; and neither do you
      if any? potential-partners
      [ ask link-with one-of potential-partners [ show-link ]
      ]
    ]
  ]
end


to-report not-partnered-yet?
; reports whether player has found a partner yet
  report all? my-links [hidden? = true ]
end


to play
; play two players against each other
  let players both-ends
  print [my-name] of players
  let player1 one-of players ; one end of the link
  let player2 nobody ; pre-define variable player2
  ask player1 [ set player2 one-of other players ] ; the other end of the link
  ;print (word ([my-name] of player1) " vs. " ([my-name] of player2))

  ; first round
  let player1-last choose [c-on-first] of player1
  let player2-last choose [c-on-first] of player2
  update-stats player1 player1-last player2-last
  update-stats player2 player2-last player1-last

  ; remaining rounds
  let player1-next 0
  let player2-next 0
  repeat number-of-rounds - 1
  [ if-else player1-last > 0
    [ if-else player2-last > 0
      [ ; CC
        set player1-next choose [c-after-cc] of player1
        set player2-next choose [c-after-cc] of player2
      ][; CD
        set player1-next choose [c-after-cd] of player1
        set player2-next choose [c-after-dc] of player2
      ]
    ][
      if-else player2-last > 0
      [ ; DC
        set player1-next choose [c-after-dc] of player1
        set player2-next choose [c-after-cd] of player2
      ][; DD
        set player1-next choose [c-after-dd] of player1
        set player2-next choose [c-after-dd] of player2
      ]
    ]
    set player1-last player1-next
    set player2-last player2-next
    update-stats player1 player1-last player2-last
    update-stats player2 player2-last player1-last
  ]
end


to play-against-self
; play strategy against itself.
; The user can choose whether to allow this.
; Note: player is playing against a mirror.  If they make an error, so does the mirror image.
  print my-name
  ; first round
  let player1-last choose c-on-first
  update-stats self player1-last player1-last

  ; remaining rounds
  let player1-next 0
  repeat number-of-rounds - 1
  [ if-else player1-last > 0
    [ ; CC
      set player1-next choose c-after-cc
    ][
      ; DD
      set player1-next choose c-after-dd
    ]
    set player1-last player1-next
    update-stats self player1-last player1-last
  ]
end


to update-stats [ player my-choice your-choice ]
; given latest round of play, update a player's statistics
  ask player
  [ set rounds-played     rounds-played     + 1
    set rounds-cooperated rounds-cooperated + my-choice
    set total-score       total-score       + benefit-to-other * your-choice - cost-to-self * my-choice
    set avg-score         total-score / rounds-played
    set avg-coop          rounds-cooperated / rounds-played
    draw-node
  ]
end


to-report choose [ coop ]
; choose a strategy, either 1=cooperate or 0=defect, depending on mixed strategy, coop.
; Includes chance of implementation error.
  let intended ifelse-value (random-float 1 < coop) [1][0]
  ; implementation error?
  report ifelse-value (random-float 100 < errors) [ 1 - intended ][ intended ]
end


to-report coop-to-letter [ coop ]
; returns a letter to indicate the degree of cooperation
; D=0..20%, d=20-40%, ~=40-60%, c=60-80%, C=80..100%
  if coop <  0.20 [ report "D"]
  if coop <  0.40 [ report "d"]
  if coop <  0.60 [ report "~"]
  if coop <  0.80 [ report "c"]
  ; else
  report "C"
end


to remove-worst
; removes lowest-scoring turtle
  let worst-score min [ avg-score ] of turtles
  ask one-of turtles with [ avg-score = worst-score ] [ die ]
end


to decimate
; removes lowest-scoring 10% of turtles
  let number-to-remove round ( ( count turtles ) / 10 )
  repeat number-to-remove [ remove-worst ]
end
@#$#@#$#@
GRAPHICS-WINDOW
249
10
721
503
16
16
14.0
1
16
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

TEXTBOX
14
10
164
28
New player:
11
0.0
1

INPUTBOX
9
24
145
84
Name
NIL
1
0
String

BUTTON
149
24
234
57
NIL
add-player
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
90
471
162
504
new-players
reset-new-players
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
349
147
382
benefit-to-other
benefit-to-other
0
4
3
0.5
1
NIL
HORIZONTAL

CHOOSER
9
273
147
318
number-of-rounds
number-of-rounds
2 5 10 20 50 100 200 500 1000 2000 5000 10000
8

TEXTBOX
9
259
159
277
Tournament:
11
0.0
1

SLIDER
9
317
147
350
cost-to-self
cost-to-self
0
2
1
0.5
1
NIL
HORIZONTAL

MONITOR
151
273
206
318
players
count turtles
17
1
11

MONITOR
151
317
206
362
games
count links
17
1
11

BUTTON
151
366
206
446
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

BUTTON
10
471
86
504
same-players
reset-same-players
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
150
62
234
95
random-player
random-player
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
11
457
161
475
Restart:
11
0.0
1

SWITCH
9
381
147
414
play-self
play-self
0
1
-1000

SLIDER
9
413
147
446
errors
errors
0
50
2
1
1
%
HORIZONTAL

SLIDER
9
83
145
116
C_on_1st
C_on_1st
0
100
100
1
1
%
HORIZONTAL

SLIDER
9
115
145
148
C_after_CC
C_after_CC
0
100
100
1
1
%
HORIZONTAL

SLIDER
9
147
145
180
C_after_CD
C_after_CD
0
100
100
1
1
%
HORIZONTAL

SLIDER
9
179
145
212
C_after_DC
C_after_DC
0
100
100
1
1
%
HORIZONTAL

SLIDER
9
211
145
244
C_after_DD
C_after_DD
0
100
100
1
1
%
HORIZONTAL

BUTTON
166
471
221
504
NIL
presets
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
150
100
234
133
NIL
remove-worst
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
150
138
234
171
NIL
decimate
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

  * Axelrod's tournament with restrictions
  * fixed number of rounds
  * only pure, memory-one strategies

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

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
