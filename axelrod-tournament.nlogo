;==================== begin axelrod-tournament.nlogo ========================
; axelrod-tournament - This NetLogo model allows you to try Axelrod's
; tournaments yourself by creating some strategies and testing them in an
; iterated Prisoner's Dilemma.
;
; By Rik Blok, 2016 <http://www.zoology.ubc.ca/~rikblok/wiki/doku.php>
;
; This is free and unencumbered software released into the public domain.
;
; Anyone is free to copy, modify, publish, use, compile, sell, or
; distribute this software, either in source code form or as a compiled
; binary, for any purpose, commercial or non-commercial, and by any
; means.
;
; See <https://github.com/rikblok/NetLogo-models/commits/master/axelrod-tournament.nlogo>
; for change history.
;-------------------------------------------------------------------------------
globals
[ generation ; count of generations, used by evolve
  last-inspect-output
]
;-------------------------------------------------------------------------------
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
  ; evolution
  my-generation
  fitness
  ancestor
]
;-------------------------------------------------------------------------------
to startup
  output-print "This NetLogo model allows you to try Axelrod's"
  output-print "tournaments yourself by creating some strategies and"
  output-print "testing them in an iterated Prisoner's Dilemma."
  reset-new-players
end
;-------------------------------------------------------------------------------
to reset-new-players
  ; clear all except output
  set generation 0 ; NetLogo web: unimplemented primitive: clear-globals
  clear-ticks clear-turtles clear-patches clear-drawing ; clear-all
  set-default-shape turtles "circle"
  output-print ""
  output-print date-and-time
  output-print "Tournament reset.  Now add some players with\n[add-players], [random-players], or [preset]."
end
;-------------------------------------------------------------------------------
to presets
  reset-same-players
  add-2016w
  add-common
  ; zero-determinant strategies
  add-extortionist
  add-equalizer
  add-generous
  output-print "Preset players added."
end
;-------------------------------------------------------------------------------
to add-2016w
  ;            Name      1st  CC  CD  DC  DD
  add-preset "2016W"     100 100  50  25  80
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
  output-print "Strategies from UBC ISCI 344 2016W class added."
end
;-------------------------------------------------------------------------------
to add-common
; common strategies
  add-preset "AllD"        0   0   0   0   0
  add-preset "AllC"      100 100 100 100 100
  add-preset "TFT"       100 100   0 100   0
  add-preset "Pavlov"    100 100   0   0 100
  add-preset "Grim"      100 100   0   0   0
  output-print "Common strategies (AllD, AllC, TFT, Pavlov, & Grim) added."
end
;-------------------------------------------------------------------------------
to add-extortionist
; requests 25% more than opponent
  add-preset "Extortionist"  90 90  5 85  0
  output-print "Zero-determinant strategy 'Extortionist' added."
end
;-------------------------------------------------------------------------------
to add-equalizer
; sets the opponents payoff to c, i.e. 1 in our case
  add-preset "Equalizer"  75 75 50 50 25
  output-print "Zero-determinant strategy 'Equalizer' added."
end
;-------------------------------------------------------------------------------
to add-generous
; ensures that difference to the social optimum R is 20% smaller for opponent
; (tft is the limiting case, requesting that the differences to R are the same for both players)
  add-preset "Generous" 100 100 15 95 10
  output-print "Zero-determinant strategy 'Generous' added."
end
;-------------------------------------------------------------------------------
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
;-------------------------------------------------------------------------------
to add-players
  repeat how-many [add-player]
  output-print (word how-many " strategies added.")
end
;-------------------------------------------------------------------------------
to random-players
; create new players with randomly-chosen strategy
  repeat how-many
  [ set C_on_1st   random 100
    set C_after_CC random 100
    set C_after_CD random 100
    set C_after_DC random 100
    set C_after_DD random 100
    add-player
  ]
  output-print (word how-many " random strategies added.")
end
;-------------------------------------------------------------------------------
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
    if my-name = "" [ generate-name ] ; if no name build name from strategy
    setxy random-xcor random-ycor
    set label-color yellow
    draw-node
    ;while [xcor < -10] [ set xcor random-xcor ] ; shift to the right to make label visible
    create-links-with other turtles [ hide-link ]
  ]
  layout ; nudge turtles to fit new one in
  ask turtles [ set label-color white ]
end
;-------------------------------------------------------------------------------
to draw-node
; update node: size indicates score and color indicates level of cooperation
  if-else rounds-played > 0
  [ set color hsb ( 120 * avg-coop ) 75 75 ; green = cooperate, red = defect
  ][
    set color gray
  ]
  ; size: -c => minimum, b => b + c + minimum
  set size avg-score + cost-to-self + 0.05
  set label ( word my-name " (" precision avg-score 2 ")  " )
end
;-------------------------------------------------------------------------------
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
  layout ; space nodes out to make easier to see
end
;-------------------------------------------------------------------------------
to go
; the main loop.  Play pairs of strategies against each other.
; This loop is repeated for all possible pairs.
; When no more pairs left, tournament ends.
  if not any? links
  [ ; end of tournament
    if play-self
    [ ask turtles [ play-against-self ]
    ]
    output-print-score
    stop
  ]
  if not any? links with [hidden? = false] [match-partners]
  ; just do one link per go loop so that web version updates graphics in-between
  ask one-of links with [hidden? = false] [ play die ]
end
;-------------------------------------------------------------------------------
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
;-------------------------------------------------------------------------------
to-report not-partnered-yet?
; reports whether player has found a partner yet
  report all? my-links [hidden? = true ]
end
;-------------------------------------------------------------------------------
to play
; play two players against each other
  let players both-ends
  ; output-print [my-name] of players
  let player1 one-of players ; one end of the link
  let player2 nobody ; pre-define variable player2
  ask player1 [ set player2 one-of other players ] ; the other end of the link
  ;output-print (word ([my-name] of player1) " vs. " ([my-name] of player2))

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
;-------------------------------------------------------------------------------
to play-against-self
; play strategy against itself.
; The user can choose whether to allow this.
; Note: player is playing against a mirror.  If they make an error, so does the mirror image.
  ; output-print my-name
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
;-------------------------------------------------------------------------------
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
;-------------------------------------------------------------------------------
to-report choose [ coop ]
; choose a strategy, either 1=cooperate or 0=defect, depending on mixed strategy, coop.
; Includes chance of implementation error.
  let intended ifelse-value (random-float 1 < coop) [1][0]
  ; implementation error?
  report ifelse-value (random-float 100 < errors) [ 1 - intended ][ intended ]
end
;-------------------------------------------------------------------------------
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
;-------------------------------------------------------------------------------
to remove-worst
; removes lowest-scoring turtle
  let worst-score min [ avg-score ] of turtles
  ask one-of turtles with [ avg-score = worst-score ]
  [ output-print (word "Strategy with lowest avg-score (" precision avg-score 2 ") removed.")
    die
  ]
end
;-------------------------------------------------------------------------------
to remove-name
; removes turtle(s) matching user-specified name
  if-else name = ""
  [ output-print "Enter a name and click [remove-name] to remove that strategy."
  ] ; else
  [ let count-to-die count turtles with [ my-name = name ]
    ask turtles with [ my-name = name ] [ die ]
    output-print (word count-to-die " copies of strategy '" name "' removed.")
  ]
end
;-------------------------------------------------------------------------------
to evolve
  if not any? turtles
  [ output-print "Add some players before clicking [evolve]."
    stop
  ]
  if not any? links [ reset-same-players ]
  go
  if not any? links
  [ ; check if any variation in scores
    let max-score max [avg-score] of turtles
    let mean-score mean [avg-score] of turtles
    let min-score min [avg-score] of turtles
    output-print
    ( word "Generation " generation ": Scores = "
      precision min-score 2  " .. "
      precision mean-score 2 " .. "
      precision max-score 2 " ("
      [my-name] of one-of turtles with [ avg-score = max-score] " best)"
    )
    if max-score = min-score
    [ ; no selection possible, stop
      output-print "No variation in score.  Evolve stopping..."
      stop
    ]

    ; define fitness
    ask turtles
    [ set my-generation generation
      set fitness (avg-score + min-score)
    ]

    ; make next generation
    set generation generation + 1
    ; bug: NetLogo web has changing turtle-set [Rik, 2016-11-13]
    ; let last-generation turtle-set turtles ; use turtle-set to make non-changing agent set
    let last-sum sum [fitness] of turtles
    let last-count count turtles
    repeat last-count
    [ ; roulette wheel sampling on fitness
      ask one-of-weighted-by-fitness turtles with [my-generation < generation] last-sum
      [ hatch 1
        [ set xcor xcor + random-float 0.01
          set ycor ycor + random-float 0.01
          set my-generation generation
          if random 100 < errors [ mutate ] ; use errors as mutation rate (per individual)
        ]
      ]
    ]
    ; remove last generation
    ask turtles with [ my-generation < generation ]
    [ let last-name my-name
      if not any? other turtles with [my-name = last-name]
      [ print
        ( word last-name
          " eliminated (score = "
          precision avg-score 2
          ")."
        )
      ]
      die
    ]
  ]
end
;-------------------------------------------------------------------------------
to output-print-score
  output-print "Player\tCoop\tScore"
  foreach sort-on [avg-score] turtles
  [ ask ?
    [ output-print
      ( word my-name "\t"
        precision (100 * avg-coop) 0 "%\t"
        precision avg-score 2
      )
    ]
  ]
  output-print "Player\tCoop\tScore"
end
;-------------------------------------------------------------------------------
to-report one-of-weighted-by-fitness [ agents sum-fitness ]
; uses fitness to choose one of agents.  Used to reproduce next generation
  let rand-fitness random-float sum-fitness
  let result nobody
  ask agents
  [ set rand-fitness rand-fitness - fitness
    if result = nobody and rand-fitness <= 0 [ set result self ]
  ]
  report result
end
;-------------------------------------------------------------------------------
to layout
; layout positions of turtles
  ; create a temporary turtle to pull other turtles towards center
  let center-turtle nobody
  create-turtles 1
  [ set hidden? true
    set center-turtle self
    create-links-with other turtles [ set hidden? true ]
  ]
  repeat 50
  [ ask center-turtle [ setxy max-pxcor 1 ] ; pull network to right (to fit labels in)
    layout-spring turtles links 2 (world-height / 2 + 1) 10
  ]
  ask center-turtle [ die ]
end
;-------------------------------------------------------------------------------
to mutate
  if ancestor = 0 [set ancestor my-name]
  let which random 5 ; pick one of the 5 strategies to mutate
  if  which = 0 [ set c-on-first random-float 1 ]
  if  which = 1 [ set c-after-cc random-float 1 ]
  if  which = 2 [ set c-after-cd random-float 1 ]
  if  which = 3 [ set c-after-dc random-float 1 ]
  if  which = 4 [ set c-after-dd random-float 1 ]
  generate-name
end
;-------------------------------------------------------------------------------
to generate-name
  set my-name
  ( word coop-to-letter c-on-first
    coop-to-letter c-after-cc
    coop-to-letter c-after-cd
    coop-to-letter c-after-dc
    coop-to-letter c-after-dd
  )
end
;-------------------------------------------------------------------------------
to-report full-name
  report word my-name ifelse-value (ancestor = 0) [""][word " " ancestor]
end
;-------------------------------------------------------------------------------
to inspect-players
  let do-stop? false ; set to true below to stop the inspect-players button
  let inspect-output ""
  if-else any? turtles
  [ ; find nearest turtle
    let nearest min-one-of turtles [distancexy mouse-xcor mouse-ycor]
    ask nearest
    [ if distancexy mouse-xcor mouse-ycor < 0.5
      [ set inspect-output
        ( word
          "Inspecting " my-name " ("
          precision (100 * c-on-first) 0 "%,"
          precision (100 * c-after-cc) 0 "%,"
          precision (100 * c-after-cd) 0 "%,"
          precision (100 * c-after-dc) 0 "%,"
          precision (100 * c-after-dd) 0 "%): "
          "Coop=" precision (100 * avg-coop) 0 "%, "
          "Score=" precision avg-score 2
          ifelse-value (ancestor = 0) [""][word ", Ancestor=" ancestor ]
        )
        ; populate user interface
        set name my-name
        set C_on_1st   precision (100 * c-on-first) 0
        set C_after_CC precision (100 * c-after-cc) 0
        set C_after_CD precision (100 * c-after-cd) 0
        set C_after_DC precision (100 * c-after-dc) 0
        set C_after_DD precision (100 * c-after-dd) 0
        ; stop this routine if user clicks on player
        set do-stop? mouse-down?
      ]
    ]
    if inspect-output != last-inspect-output
    [ set last-inspect-output inspect-output
      output-print last-inspect-output
    ]
  ] ; else
  [ output-print "No players.  Add some with\n[add-players], [random-players], or [preset]."
    stop
  ]
  ; if user clicked on player then stop inspect-players
  if do-stop? [ stop ]
end
;====================== end axelrod-tournament.nlogo ========================
@#$#@#$#@
GRAPHICS-WINDOW
249
10
714
340
17
11
13.0
1
17
1
1
1
0
0
0
1
-17
17
-11
11
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
Players:
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
62
241
95
NIL
add-players
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
221
318
players
count turtles
17
1
11

MONITOR
151
317
221
362
games
count links
17
1
11

BUTTON
151
366
221
399
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
100
241
133
NIL
random-players
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
0
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
0
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
138
241
171
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
151
403
221
436
NIL
evolve
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
149
24
241
57
how-many
how-many
1
50
1
1
1
NIL
HORIZONTAL

BUTTON
150
176
241
209
NIL
remove-name
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

OUTPUT
249
345
715
504
11

BUTTON
150
213
241
246
NIL
inspect-players
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
# Axelrod's tournament

A [NetLogo] model by Rik Blok.

[http://www.zoology.ubc.ca/~rikblok/wiki/doku.php?id=science:popmod:axelrod_s_tournament:start](http://www.zoology.ubc.ca/~rikblok/wiki/doku.php?id=science:popmod:axelrod_s_tournament:start)

How can cooperation arise and persist when there is a temptation to "defect" from cooperation for personal gain?  [Cooperation](https://en.wikipedia.org/wiki/Cooperation) is a well-studied problem in economics, social sciences, and evolution.

Let's construct a simple scenario to highlight the problem.  Consider an interaction between two individuals where each player can, at a cost _c>0_ to themselves, confer a benefit _b>c_ to the other player:

* If I cooperate I pay a cost _c_ and
* If you cooperate I receive a benefit _b_.

If you and I are playing this [Prisoner's Dilemma](https://en.wikipedia.org/wiki/Prisoner%27s_dilemma) game what should we choose?  Clearly it would be best for both of us if we could **cooperate** so we each earn a net amount of _b-c>0_.  But it would be better yet if we didn't pay the cost _c_.  If we both try to gain the highest payoff by avoiding the cost then we will get nothing (because nobody generated the benefit).  Cooperation is undermined because _no matter what you choose_, _I_ always feel the temptation to **defect** and avoid paying the cost -- it is difficult for cooperation to arise and persist in this game.

Repetition was proposed as a solution to this dilemma: perhaps if the players repeated the interaction many times, the prospect of reciprocal cooperation in the future would encourage players to cooperate now.

In each round a player can choose to **cooperate** or **defect** but their choice may depend on many details, such as what they and/or the other player did in the past.  For example, I would like to receive the benefit _b_ from you in every round.  If I received it last round I might repeat the same choice (don't make any changes if things are going well, or "win-stay") but if I didn't I might choose the other option (switch if things are going poorly, or "lose-switch").  This well-known strategy is called Pavlov, or [win-stay, lose-switch](https://en.wikipedia.org/wiki/Win%E2%80%93stay,_lose%E2%80%93switch).  If both players use the Pavlov strategy and cooperate in the first round, they will continue to cooperate for all rounds, doing much better than strategies that mutually fall for the temptation to defect.  (But Pavlov is not guaranteed to perform well when playing against these strategies.)

In the early 1980s [Robert Axelrod](https://en.wikipedia.org/wiki/Robert_Axelrod) invited colleagues to submit strategies to a series of round-robin tournaments [[Axelrod & Hamilton, 1981]] to see which strategies would do well playing an [iterated Prisoner's Dilemma](https://en.wikipedia.org/wiki/Prisoner%27s_dilemma#The_iterated_prisoner.27s_dilemma).  This [NetLogo] model allows you to try [Axelrod's tournaments](https://en.wikipedia.org/wiki/The_Evolution_of_Cooperation#Axelrod.27s_tournaments) yourself by creating some strategies and testing them in an iterated Prisoner's Dilemma.


# How it works


## go

The [go] button starts a [round-robin tournament](https://en.wikipedia.org/wiki/Round-robin_tournament) where all strategies are paired with each other to play the Prisoner's Dilemma for a specified number of rounds.  The average score for each player is shown beside their name.  At the end of the tournament all players' average scores are shown in the output window.


## Memory-one strategies

In Axelrod's tournament game theorists were invited to submit any strategies that could be encoded as computer programs.  The programs had as input the entire history of the interaction so far and would respond with a choice to **cooperate** or **defect** in the next round [[Axelrod, 1980]].  That's far beyond the scope of this simulation.

Instead, each strategy consists of a set of five numbers, representing the probability of cooperating in the next round given what occured only in the previous round:

* **C_on_1st** = probability that I **cooperate** in the first round.
* **C_after_CC** = probability that I **cooperate** after _we both cooperated_ in the previous round.
* **C_after_CD** = probability that I **cooperate** after _I cooperated_ and _you defected_ in the previous round.
* **C_after_CD** = probability that I **cooperate** after _I defected_ and _you cooperated_ in the previous round.
* **C_after_CC** = probability that I **cooperate** after _we both defected_ in the previous round.

Even though this severely limits the available strategies, it is still possible to create some well-known strategies:

* AllC = (100%, 100%, 100%, 100%, 100%).  Always cooperates.
* AllD = ( 0%, 0%, 0%, 0%, 0%).  Always defects.
* [Tit-for-tat](https://en.wikipedia.org/wiki/Tit_for_tat#In_game_theory) = (100%, 100%, 0%, 100%, 0%).  Cooperates on first round.  After that, repeats other player's last choice.
* [Pavlov](https://en.wikipedia.org/wiki/Win%E2%80%93stay,_lose%E2%80%93switch) = (100%, 100%, 0%, 0%, 100%).  Cooperates on first round.  After that, repeats last move if received _b_, otherwise switches.
* [Grim](https://en.wikipedia.org/wiki/Grim_trigger) = (100%, 100%, 0%, 0%, 0%).  Cooperates on first round.  After that, keeps cooperating until anybody defects.  Then defects for rest of game.

Click [presets] to explore other interesting strategies.


## evolve

The [evolve] button allows the user to explore how the population of strategies evolves over many tournaments.  Between each tournament a new generation of strategies is created by sampling the current generation.  The probability of each strategy reproducing into the next generation is proportional to its average score plus **cost-to-self** (to guarantee a non-negative probability).


# How to use it

## Adding players

To run a tournament you first need to add some players (also called strategies).  You can add your own by choosing slider values and (optionally) giving the strategy a name, then clicking the [add-players] button.  (You can add duplicates of a strategy by adjusting the [how-many] slider before clicking [add-players].)

Alternatively, you can click the [random-players] button to add one (or [how-many]) randomly-chosen strategies.

You can also click the [presets] button at the bottom to add a bunch of pre-defined strategies.  Most of these were submitted by students in the UBC course [ISCI 344 Game Theory](https://intsci.ubc.ca/courses/isci344).

## Running a tournament

### go

Once you've got a pool of players you can run a round-robin tournament between them by clicking the [go] button.  Choose the following parameters:

* **number-of-rounds**: The number of repetitions (rounds) of the game played between each pair of players.
* **cost-to-self**: The cost each player pays for choosing to cooperate.
* **benefit-to-other**: The benefit received if the other player chooses to cooperate.  When the benefit is more than the cost there is an incentive to choose mutual cooperation, but a temptation to defect -- a Prisoner's Dilemma.
* **play-self**: Toggle on to have each player also play against themselves in the tournament.  They are actually playing against a mirror image -- their opponent makes exactly the same choices as they do (even duplicating any errors).
* **errors**: The chance of making an implementation error with any choice.  With implementation errors players perceive the conditions (eg. what happened in the last round) correctly and determine their response correctly according to their strategy, but they accidentally select the option opposite to what they intended.  Set this to zero for perfect fidelity (players always successfully make the choice they intended).  **errors** also sets the mutation rate under [evolve] (see the next section).

At the end of the tournament all the player scores and level of cooperation (fraction of times they cooperated) are shown.


### inspect-players

You can view the score and other details of any of the players.  Press the [inspect-players] button to enable this functionality.  Then hover over any player to see their attributes including their name, strategy (five percentages), average frequency of cooperation, and average score so far.

Inspecting a player also populates the "Players:" view (name and strategy sliders) so you can easily remove this player or add more of the same.  (Hint: You can stop [inspect-players] so that the current player remains in the view by clicking on the player.)


### evolve

In addition to running the tournament once and seeing the scores, it is possible to run it repeatedly, and select for the highest scoring strategies.  Each generation, the players are selected to form the next generation with likelihood [proportional to their fitness](https://en.wikipedia.org/wiki/Fitness_proportionate_selection) where
> _fitness = average-score + cost-to-self_

so that the minimum probability of selection is never negative.

The population size is conserved across generations.  Since lower-fitness strategies are less likely to be copied into the next generation this evolutionary process selects for higher fitness strategies.

As strategies are copied into the next generation, replication errors (_mutations_) are possible.  The [errors] slider gives the likelihood that a child will have a mutation from its parent.  If a mutation occurs, one of the five probabilities is replaced with a random value.


## Removing players

You can remove players at any time by entering their name in the [Name] box and clicking [remove-name].  Note that this removes _all_ players with that name.

You can also remove the player with the lowest average score with the [remove-worst] button.


# Things to notice


## Errors

Notice that it is possible to introduce _implementation errors_ into the game: a strategy may intend to **cooperate** or **defect** but erroneously choose the other option.  The error rate (per choice) is given by the **errors** slider.

The **errors** slider also allows reproduction errors, or mutations.  In this case the value gives the mutation rate per child.  If a mutation occurs one of the five variables representing the strategy is replaced with a random value.


## Fixed number of rounds

Axelrod set up his tournament so each game between two players had an uncertain duration [[Axelrod, 1980]].  That prevented strategies from being conditioned on how many rounds remained.  (It's always best to **defect** in the last round.  But if I know that, I should also **defect** in the second-to-last round...)  That's not an issue in this simulation because memory-one strategies aren't sophisticated enough to condition their response on the number of remaining rounds.  So this tournament allows a certain, fixed number of rounds.


## Fitness landscape

You may be surprised to see the average score (or _fitness_) drop as the population evolves.  Evolution is often thought of as climbing a [fitness landscape](https://en.wikipedia.org/wiki/Fitness_landscape).  That makes sense when the fitness is unchanging.  But in this model the fitness of each strategy depends strictly on the other strategies in the population.  As the population composition changes the fitness of the population may decline.  Nevertheless, the most successful within that population will tend to reproduce more frequently.  Counterintuitively, in this way it is possible for the system to evolve to low fitness.  It is akin to climbing a hill that collapses as it is being climbed.


# Things to try

What do you expect to happen if the error rate is set to 50%?  (Hint: For each of the five memory-one conditions, what is the probability any player will choose erroneously?)  Check if you're right!


# References

**[[Axelrod, 1980]]** Axelrod, Robert. 1980. “More Effective Choice in the Prisoner’s Dilemma.” _Journal of Conflict Resolution_ 24 (3): 379–403. doi:[10.1177/002200278002400301](http://dx.doi.org/10.1177%2F002200278002400301).

**[[Axelrod & Hamilton, 1981]]** Axelrod, R., and W. D. Hamilton. 1981. “The Evolution of Cooperation.” _Science_ 211 (4489): 1390–96. doi:[10.1126/science.7466396](https://doi.org/10.1126/science.7466396).

**[[NetLogo]]** Wilensky, U. 1999. “NetLogo.” [http://ccl.northwestern.edu/netlogo/](http://ccl.northwestern.edu/netlogo/). Center for Connected Learning and Computer-Based Modeling, Northwestern University. Evanston, IL. 1999.


[Axelrod, 1980]: https://www.zotero.org/rikblok/items/itemKey/I8SMT8KB
[Axelrod & Hamilton, 1981]: https://www.zotero.org/rikblok/items/itemKey/EBG8XDKU
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
