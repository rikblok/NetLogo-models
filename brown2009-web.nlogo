; Revisions:
; 2013-08-02
;   - accuracy now reports ( 100% - per-capita-mean-error )
;   - diffuse-individual moved into .nls file
;   - output-wrap moved into .nls file
;   - sigfigs moved into .nls file
; 2013-07-29
;   - line-breaking procedure to replace output-prints
;   - moved some generic code into includes file
;   - events are defined at beginning and applied behind the scenes (in included file)

; design choices:
; * the (full) model is agent-based
; * bacteria (wilds and cheaters) are mobile (Brownian)
; * their products (food, toxin, and bacteriocide) are stationary
; * interactions are local (per patch)
; * time steps forward in increments large enough for multiple events to occur
; * the full model fixes the fast (food, toxin, & bacteriocide) production rates
; * the System Dynamics Modeler contains a numeric approximation
; * the numeric model applies the QSSA to reduce the system, removing the products
; * the numeric model approximates the equations in Brown et al., 2009


; the possible "breeds" of turtles
breed [wilds wild]
breed [cheaters cheater]


; turtles own event rates
patches-own [
  food
  toxin
  bacteriocide
]


globals [
  count-patches  ; assign to variable to improve speed; used in setup and plots
  beta-food
  delta-toxin
  gamma-bacteriocide
  fast-rate      ; = beta = delta = gamma (fast consumption rates for food, toxin, & bacteriocide)
  wild-virulence
  ; from output-wrap.nls
  output-wrap-at  ; column to wrap at.  Set directly or call 'output-wrap _column_' to set.
  ; from per-capita-tau-leaping.nls
  per-capita-events                ; list of all events
  per-capita-count-events          ; list of counters: # times each event has fired
  per-capita-tau-err               ; last per-capita-err used when calculating tau-leap
  per-capita-max-rates             ; latest max-rate for each event
  per-capita-highest-max-rate      ; fastest rate so far in current run
  ; Error estimates, from max probability of event;
  ; perfect SSA would approach limit max-rate --> 0.
  per-capita-last-error            ; error in last iteration
  per-capita-worst-error           ; worst error so far in current run
  per-capita-mean-error-num        ; sum of errors over past iterations (numerator)
  per-capita-mean-error-den        ; count number of timesteps iterated (denominator)
  ;; System dynamics model globals
  ;; stock values
  C-num
  W-num
  ;; size of each step, see SYSTEM-DYNAMICS-GO
  dt
]


to startup
  setup
end


to setup
  clear-all
  set fast-rate 5 ; TO DO: how big does this need to be to satisfy QSSA?
  set wild-virulence 2 ; assume wild type twice as virulent as cheaters (as per Brown et al.)
  set beta-food fast-rate
  set delta-toxin fast-rate
  set gamma-bacteriocide fast-rate
  set count-patches count patches
  _system-dynamics-setup ; setup system-dynamics-modeler for numeric comparison
  ; set breed shapes
  set-default-shape turtles "circle"
  ; create numbers of each breed to get the desired average density (per patch)
  create-wilds       ( W-num * count-patches ) [ set color green ]
  create-cheaters    ( C-num * count-patches ) [ set color red   ]
  ; shuffle them
  ask turtles [ setxy random-xcor random-ycor ]
  ask patches [
    ; start with QSSA densities of food, toxin, & bacteriocide
    let count-turtles-here  count turtles-here
    let count-cheaters-here count cheaters-here
    if ( count-turtles-here > 0 ) [
      ; Poisson-distributed random variates
      set food _random-poisson ( b-shared-benefit * count wilds-here / ( beta-food * count-turtles-here ) )
      set toxin _random-poisson ( a-toxin-production * count-cheaters-here / ( delta-toxin * count-turtles-here ) )
      set bacteriocide _random-poisson ( e-bacteriocinogen * count-cheaters-here / ( gamma-bacteriocide * count-turtles-here ) )
    ]
  ]
  reset-ticks
  ; hint
  output-wrap 26 ; set wrapping column
  output-wrap "An agent-based model of 'Social evolution in micro-organisms and a Trojan horse approach to medical intervention strategies' by Brown et al. (2009)."
  output-wrap "Press go to get started.\n"

  ; merge all events into one master list [2013-07-29]
  add-per-capita-event turtles                  ; N -> 2 N @ rate 1
    [ [] ->  1 ]
    [ [] ->  hatch 1 ]
  add-per-capita-event turtles                  ; N + N -> N @ rate 1
    [ [] ->  count other turtles-here ]
    [ [] ->  die ]
  add-per-capita-event turtles                  ; N + F -> 2 N @ rate beta
    [ [] ->  beta-food * food ]
    [ [] ->  set food food - 1
           hatch 1           ]
  add-per-capita-event turtles                  ; N + T -> 0 @ rate delta
    [ [] ->  delta-toxin * toxin ]
    [ [] ->  set toxin toxin - 1
           die                 ]
  add-per-capita-event wilds                    ; W -> 0 @ rate x
    [ [] ->  x-wild-cost ]
    [ [] ->  die ]
  add-per-capita-event wilds                    ; W -> W + F @ rate b
    [ [] ->  b-shared-benefit ]
    [ [] ->  set food food + 1 ]
  add-per-capita-event wilds                    ; W + B -> 0 @ rate gamma
    [ [] ->  gamma-bacteriocide * bacteriocide ]
    [ [] ->  set bacteriocide bacteriocide - 1
           die                               ]
  add-per-capita-event cheaters                 ; C -> 0 @ rate q
    [ [] ->  q-cheater-cost ]
    [ [] ->  die ]
  add-per-capita-event cheaters                 ; C -> C + T @ rate a
    [ [] ->  a-toxin-production ]
    [ [] ->  set toxin toxin + 1 ]
  add-per-capita-event cheaters                 ; C -> C + B @ rate e
    [ [] ->  e-bacteriocinogen ]
    [ [] ->  set bacteriocide bacteriocide + 1 ]
  add-per-capita-event cheaters                 ; C + B -> C @ rate gamma
    [ [] ->  gamma-bacteriocide * bacteriocide ]
    [ [] ->  set bacteriocide bacteriocide - 1 ]
end


to go
  if ticks = 0 [
    reset-timer
    output-wrap "You may adjust all parameters while the simulation runs."
    output-wrap "Compare the numeric, non-spatial (faint) vs. agent-based (bold) dynamics in the graphs."
    output-wrap ( word "It is assumed that the wild type is " wild-virulence " times as virulent as the cheater.\n" )
  ]
  _system-dynamics-go ; numeric model
  set dt per-capita-tau-leap inaccuracy dt
  diffuse-individual turtles diffusion-const dt
  do-plots
  if (dt = 0) [  ; simulation over
    output-wrap (word "Finished in " timer " seconds.")
    stop
  ]
end


to do-plots
  set-current-plot "dynamics"
  _system-dynamics-do-plot
  update-plots ; update other plots ("Edit" the plots to see code)
end


to-report diffusion-const
  report ifelse-value well-mixed [ 0 ][ 10 ^ log-diffusion ]
end


to-report inaccuracy
; complement of accuracy, depends on err-tolerance
  report 10 ^ ( err-tolerance )
end

;==================== begin diffuse-individual.nls =============================
; diffuse-individual - random walk for individuals.  Respects non-wrapping
; world boundaries.
;
; By Rik Blok, 2013 <http://www.zoology.ubc.ca/~rikblok/wiki/doku.php>
;
; This is free and unencumbered software released into the public domain.
;
; Anyone is free to copy, modify, publish, use, compile, sell, or
; distribute this software, either in source code form or as a compiled
; binary, for any purpose, commercial or non-commercial, and by any
; means.
;
; Usage:
;
;   diffuse-individual _agents_ _distance_ _time-step_
;
; Example:
;
;   globals [ dt ]
;   to setup
;     set dt 0.1
;   end
;   to go
;     ifelse (well-mixed-switch?) [
;       ; turtles are well-mixed, can move anywhere
;       diffuse-individual turtles 0 dt
;     ][
;       ; move random direction, variance proportional to diffusion-const-slider * dt
;       diffuse-individual turtles diffusion-const-slider dt
;   end
;
; Known limitations:
;
;   2013-08-02 - doesn't consider spatial boundaries/restrictions
;
; Revisions:
;
;   2013-08-02 - initial release by Rik Blok
;-------------------------------------------------------------------------------


to diffuse-individual [
    diffuse-individual-agents
    diffuse-individual-diff-const
    diffuse-individual-dt
]
  if-else (diffuse-individual-diff-const = 0)
  [
    ; well-mixed, anybody could be anywhere
    ask diffuse-individual-agents [ setxy random-xcor random-ycor ]
  ][
    ; not well-mixed, do random walk
    ; see http://en.wikipedia.org/wiki/Random_walk#Relation_to_Wiener_process
    ; TODO: check, is this exactly the diffusion constant?
    let jump-size sqrt ( 4 * diffuse-individual-diff-const * diffuse-individual-dt )
    ask diffuse-individual-agents
    [
      set heading random 360
      jump jump-size
    ]
  ]
end
;==================== end diffuse-individual.nls ===============================

;==================== begin output-wrap.nls ====================================
; output-wrap - Same as output-print but wraps printed output.
;
; By Rik Blok, 2013 <http://www.zoology.ubc.ca/~rikblok/wiki/doku.php>
;
; This is free and unencumbered software released into the public domain.
;
; Anyone is free to copy, modify, publish, use, compile, sell, or
; distribute this software, either in source code form or as a compiled
; binary, for any purpose, commercial or non-commercial, and by any
; means.
;
; Usage:
;
;   ; two ways to instruct output-wrap to wrap lines at _column_
;   set output-wrap-at _column_
;   output-wrap _column_
;
;   ; write _string_ to output, wrapping at/before indicated column
;   output-wrap _string_
;
; Example:
;
;   to setup
;     output-wrap 26
;     reset-timer
;   end
;   to go
;     output-wrap ( word timer " seconds elapsed." )
;   end
;
; Known limitations:
;
;   2013-07-31 - doesn't recognize "\n" line breaks
;
; Revisions:
;
;   2013-07-31 - initial release by Rik Blok
;-------------------------------------------------------------------------------


; To discover the number of characters that will fit on one line (the best
; column to wrap at), in Command Center enter something like
;   output-print "123456789a123456789b123456789c123456789d123456789e123456789"
; and count the number of characters before the output box first breaks the line.

to output-wrap [ string ]
; wrap string into lines that fit at specified column

  ; set column to wrap at?
  if (is-number? string and string > 0) [
    set output-wrap-at string
    stop
  ]
  ; error trap
  if (output-wrap-at = 0) [
    output-print "Error: first call 'output-wrap _column_' to set wrapping column."
    stop
  ]

  ; if string too long, break into separate lines
  while [length string > output-wrap-at] [
    ; TODO: detect and handle "\n" line breaks
    ; find last space character
    let cut-at position " " reverse substring string 0 ( output-wrap-at - 1 )
    ; if no spaces, fill whole line
    if cut-at = false [ set cut-at -1 ]
    set cut-at output-wrap-at - cut-at - 1
    ; print this line
    output-print substring string 0 cut-at
    ; remove from string
    set string substring string cut-at ( length string )
    ; trim leading spaces
    while [first string = " "] [ set string but-first string ]
  ]
  while [first string = " "] [ set string but-first string ]
  output-print string
end
;==================== end output-wrap.nls ======================================

;==================== begin per-capita-tau-leaping.nls =========================
; per-capita-tau-leaping - A variant tau-leaping algorithm to approximate
; Gillespie's Stochastic Simulation Algorithm (SSA).
;
; This "per-capita" tau leaping algorithm is different than the standard
; method [Cao2007]: it is not yet known if it contains any flaws or biases that
; would invalidate it as an approximation of Gillespie's SSA.  The performance
; of this method as compared to [Cao2007] is also unknown -- it is entirely
; possible that it is slow *and* wrong.
;
; In this method, events are agent-based, with a focal agent (one of the
; reactants.  The focal agent determines the propensity (per capita) of the
; reaction and the actions to take.  The leap condition is that it should be
; rare for each reaction to occur (where "rare" is defined by an error
; tolerance).
;
; [Cao2007] Cao, Yang, Daniel T. Gillespie, and Linda R. Petzold. 2007.
;   "Adaptive Explicit-implicit Tau-leaping Method with Automatic Tau
;   Selection." The Journal of Chemical Physics 126 (22): 224101.
;   doi:10.1063/1.2745299.
;   http://link.aip.org/link/JCPSA6/v126/i22/p224101/s1&Agg=doi.
;
; By Rik Blok, 2013 <http://www.zoology.ubc.ca/~rikblok/wiki/doku.php>
;
; This is free and unencumbered software released into the public domain.
;
; Anyone is free to copy, modify, publish, use, compile, sell, or
; distribute this software, either in source code form or as a compiled
; binary, for any purpose, commercial or non-commercial, and by any
; means.
;
; Usage:
;
;   ; add an event for _breed_ with per-capita _rate_ and _actions_ to the list
;   add-per-capita-event _breed_ task [ _rate_ ] task [ _actions_ ]
;
;   ; one iteration of per-capita tau leaping algorithm (faster, less accurate)
;   set dt per-capita-tau-leap _error_ dt
;
;   ; or split iteration into two stages (slower, more accurate)
;   set dt per-capita-tau _error_ ; first set leap size
;   per-capita-leap dt            ; then execute leap
;
;   ; print average error over entire simulation so far
;   print per-capita-mean-error
;
;   ; or just over last iteration
;   print per-capita-last-error
;
; Example:
;
;   globals [ dt ]
;   to setup
;     ask patches [ sprout 1 ]
;     ; N --> 2 N at rate birth-rate-slider
;     ; rate = dN/dt = birth-rate-slider * N
;     ; per-capita rate = (1/N) dN/dt = birth-rate-slider
;     ; action = birth of a child
;     add-per-capita-event turtles
;       task [ birth-rate-slider ]
;       task [ hatch 1 ]
;     ; 2 N --> N at rate death-rate-slider
;     ; rate = dN/dt = death-rate-slider * N ^ 2
;     ; per-capita rate = (1/N) dN/dt = death-rate-slider * N
;     ; action = death of focal agent
;     add-per-capita-event turtles
;       task [ death-rate-slider * count other turtles-here ]
;       task [ die ]
;     ; It is also possible to represent processes without a focal
;     ; agent by acting on the underlying patch.  For example...
;     ; 0 --> N at rate creation-rate-slider
;     ; rate = dN/dt = creation-rate-slider (per patch)
;     ; action = creation of new agent
;     add-per-capita-event patches
;       task [ creation-rate-slider ]
;       task [ sprout 1 ]
;   end
;   to go-fast
;     ; faster, less accurate method
;     set dt per-capita-tau-leap 0.1 dt ; 10% error tolerance
;   end
;   ; or
;   to go-accurate
;     ; slower, more accurate method
;     set dt per-capita-tau 0.1 ; % 10% error tolerance
;     per-capita-leap dt
;   end
;
; Known limitations:
;
;   2013-12-12
;     * only supports breeds, not agentsets. TODO: replace breed with agentset task.
;   2013-07-31
;     * This "per-capita" tau-leaping algorithm has not been studied.  It may
;       contain flaws or biases.
;
; Revisions:
;
;   2013-12-13
;     * added per-capita-max-rates list
;     * removed unfinished add-per-patch-event procedure
;     * changed error reporters: now use maximum probability of an event.  Had
;       been using actual vs possible event counts but it gives too rosy a
;       measure of simulation accuracy.
;     * changed: per-capita-tau and per-capita-tau-leap now always return a small
;       positive dt.  Guessed from historically highest max-rate.
;   2013-11-22
;     * added reaction counts to assist profiling
;     * fix: corrections to event counting for error estimates
;     * shuffles event list on each timestep to reduce deterministic artefacts
;     * fix: run action last, after all book-keeping in per-capita-tau-leap
;       in case action is 'die'
;   2013-10-24
;     * fix: can't trust dt passed to per-capita-tau-leap to be zero on
;       first call.  For instance, if system-dynamics-setup is called.
;       Now recalculates dt every time error tolerance changes
;       (including first call).
;   2013-08-02
;     * added event counts and error reporters
;   2013-07-31
;     * initial release by Rik Blok
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
to add-per-capita-event
; Add a per-capita event/reaction to the list.  Reactions are represented in
; terms of a focal reactant.
; Parameters:
[ event-breed   ; breed of focal reactant
  event-rate    ; reporter task: reaction rate per focal reactant
  event-action  ; task: actions to take when event fires
]
  if per-capita-events = 0
  [ ; create empty lists if necessary
    set per-capita-events []
    set per-capita-count-events []
    set per-capita-max-rates []
  ]
  ; append event to per-capita-events list
  set per-capita-events
  ( lput
    ( list        ; per-capita-events is list of reactions.  Each reaction contains four items:
      event-breed                   ; item 0 = breed of focal reactant
      event-rate                    ; item 1 = reaction rate per focal reactant (reporter task)
      event-action                  ; item 2 = actions to take when event fires (command task)
      ( length per-capita-events )  ; item 3 = index of event in list
    ) per-capita-events
  )
  set per-capita-count-events lput 0 per-capita-count-events
  set per-capita-max-rates lput 0 per-capita-max-rates
  ; reset last error tolerance (to force refresh of dt)
  set per-capita-tau-err -1 ; set to nonsense value
  ; reset error estimates
  set per-capita-last-error       0
  set per-capita-mean-error-num   0
  set per-capita-mean-error-den   0
  set per-capita-worst-error      0
  set per-capita-highest-max-rate 0
end


;-------------------------------------------------------------------------------
to-report per-capita-tau
; Report dt that will give desired error tolerance.
; Parameters:
[ per-capita-err ; desired error tolerance
]
  foreach per-capita-events
  [ ?1 -> let event-breed  item 0 ?1
    let event-rate   item 1 ?1
    let event-index  item 3 ?1
    let max-rate     0        ; don't read from per-capita-max-rates, reset to zero
    ask event-breed
    [ let this-rate runresult event-rate
      if this-rate > max-rate [ set max-rate this-rate ]
    ]
    ; store max-rate for this event
    set per-capita-max-rates
    ( replace-item event-index per-capita-max-rates max-rate
    )
  ]
  ; remember current per-capita-err
  set per-capita-tau-err per-capita-err
  ; max-rate for this iteration now known so can set dt to achieve desired error tolerance
  let max-rate max per-capita-max-rates
  ; if no events anticipated guess minimum safe dt from highest max-rate so far
  if max-rate = 0 [ set max-rate per-capita-highest-max-rate ]
  ; report best guess of next timestep, dt
  report ifelse-value (max-rate > 0) [ per-capita-err / max-rate ] [0]
end


;-------------------------------------------------------------------------------
to per-capita-leap
; Same as per-capita-tau-leap but throw away reported dt.
; Use per-capita-tau to get dt separately.
; Parameters:
[ per-capita-dt ; timestep to use.  Should come from call to per-capita-tau
]
  ; pass per-capita-tau-err in per-capita-tau-leap to avoid call to per-capita-tau
  let local-dt per-capita-tau-leap per-capita-tau-err per-capita-dt
end


;-------------------------------------------------------------------------------
to-report per-capita-tau-leap
; Process all events, and make "best guess" for next dt.
; Probably a little faster but less accurate than calling per-capita-leap and
; per-capita-tau separately.
; Parameters:
[ per-capita-err ; desired error tolerance
  per-capita-dt  ; current timestep to use
]
  ; If error tolerance changed then don't use timestep per-capita-dt.  Recalculate.
  ; Also happens after add-per-capita-event.
  if per-capita-err != per-capita-tau-err  [ set per-capita-dt per-capita-tau per-capita-err ]
  ; shuffle event list and run through all events
  ; foreach shuffle per-capita-events ;; shuffle unknown on web
  foreach per-capita-events
  [ ?1 -> let event-breed  item 0 ?1
    let event-rate   item 1 ?1
    let event-action item 2 ?1
    let event-index  item 3 ?1
    let new-max-rate 0        ; don't read from per-capita-max-rates, reset to zero
    let event-count  0
    ask event-breed
    [ let this-rate runresult event-rate
      if this-rate > new-max-rate [ set new-max-rate this-rate ]
      ; check for error
      if this-rate * per-capita-dt > 1
      [ type "ERROR: per-capita-tau-leaping.nls @ tick " print ticks
        type "Timestep too large.  Reduce error tolerance (currently "
          type per-capita-tau-err print ")."
      ]
      ; do event?
      if random-float 1 < (this-rate * per-capita-dt)
      [ set event-count event-count + 1
        ; run action.  Must be last command in this block (in case of 'die').
        run event-action
      ]
    ]
    ; update per-capita-count-events list
    if event-count > 0
    [ set per-capita-count-events
      ( replace-item
        event-index
        per-capita-count-events
        ( event-count + item event-index per-capita-count-events )
      )
    ]
    ; store max-rate for this event
    set per-capita-max-rates
    ( replace-item event-index per-capita-max-rates new-max-rate
    )
  ]
  ; update global counts
  ; max-rate for this iteration now known so can set dt to achieve desired error tolerance
  let max-rate max per-capita-max-rates
  ; new highest-max-rate?
  if max-rate > per-capita-highest-max-rate
  [ set per-capita-highest-max-rate max-rate ]
  ; update error estimators
  set per-capita-last-error  max-rate * per-capita-dt
  ; uncomment for debugging
  ; type "per-capita-last-error = " type per-capita-last-error type " = " type max-rate type " * " print per-capita-dt
  set per-capita-mean-error-num   per-capita-mean-error-num + per-capita-last-error
  if per-capita-last-error > 0 ; only increment if really took a step forward
  [ set per-capita-mean-error-den  per-capita-mean-error-den + 1
  ]
  ; new worst max-prob?
  if per-capita-last-error > per-capita-worst-error
  [ set per-capita-worst-error per-capita-last-error
  ]
  ; if no events anticipated guess minimum safe dt from highest max-rate so far
  if max-rate = 0 [ set max-rate per-capita-highest-max-rate ]
  ; report best guess of next timestep, dt
  report ifelse-value (max-rate > 0) [ per-capita-err / max-rate ] [0]
end


;-------------------------------------------------------------------------------
to-report per-capita-mean-error
; Reports mean error over current simulation run.
; Error estimated as last max prob of event; perfect SSA would approach
; limit max-rate --> 0.
  ; if no error information yet, report 0
  if per-capita-mean-error-den = 0 [ report 0 ]
  ; else, if error very large, report 100% error
  if per-capita-mean-error-num > per-capita-mean-error-den [ report 1]
  ; else
  report per-capita-mean-error-num / per-capita-mean-error-den
end


;-------------------------------------------------------------------------------
to print-per-capita-count-events
  foreach per-capita-events
  [ ?1 -> let event-breed  item 0 ?1
    let event-index  item 3 ?1
    let event-count  item event-index per-capita-count-events
    type event-index type " " type event-breed type " " print event-count
  ]
end


;==================== end per-capita-tau-leaping.nls ===========================

;==================== begin sigfigs.nls ========================================
; sigfigs - Like precision but specifies number of significant figures.
;
; By Rik Blok, 2013 <http://www.zoology.ubc.ca/~rikblok/wiki/doku.php>
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
;   ; print pi to 3 sigfigs
;   print sigfigs pi 3
;
;   ; print ticks to same digit as dt
;   print sigfigs dt 2
;   tick-advance dt
;   print sigfigs-other ticks dt 2
;
; Revisions:
;
;   2013-08-03 - initial release by Rik Blok
;-------------------------------------------------------------------------------


to-report sigfigs [ number digits ]
  report precision number (digits - ceiling log number 10)
end


to-report sigfigs-other [ number other-number digits ]
; print _number_ to same decimal as _digits_ sigfigs of _other-number_
  report precision number (digits - ceiling log other-number 10)
end
;==================== end sigfigs.nls ==========================================

;; Initializes the system dynamics model.
;; Call this in your model's SETUP procedure.
to _system-dynamics-setup
  reset-ticks
  set dt 1.0E-8
  ;; initialize stock values
  set C-num initial-C-density
  set W-num initial-W-density
end

;; Step through the system dynamics model by performing next iteration of Euler's method.
;; Call this in your model's GO procedure.
to _system-dynamics-go

  ;; compute variable and flow values once per step
  let local-N-num N-num
  let local-vir-num vir-num
  let local-W-competition W-competition
  let local-wild-cost wild-cost
  let local-W-benefit W-benefit
  let local-w-toxin w-toxin
  let local-bacteriocinogen bacteriocinogen
  let local-C-competition C-competition
  let local-cheater-cost cheater-cost
  let local-C-toxin C-toxin
  let local-C-benefit C-benefit
  let local-W-growth W-growth
  let local-C-growth C-growth

  ;; update stock values
  ;; use temporary variables so order of computation doesn't affect result.
  let new-C-num ( C-num - local-C-competition - local-cheater-cost - local-C-toxin + local-C-benefit + local-C-growth )
  let new-W-num ( W-num - local-W-competition - local-wild-cost + local-W-benefit - local-w-toxin - local-bacteriocinogen + local-W-growth )
  set C-num new-C-num
  set W-num new-W-num

  tick-advance dt
end

;; Report value of flow
to-report W-competition
  report ( W-num * N-num
  ) * dt
end

;; Report value of flow
to-report wild-cost
  report ( W-num * x-wild-cost
  ) * dt
end

;; Report value of flow
to-report W-benefit
  report ( W-num * b-shared-benefit * W-num / N-num
  ) * dt
end

;; Report value of flow
to-report w-toxin
  report ( W-num * a-toxin-production * C-num / N-num
  ) * dt
end

;; Report value of flow
to-report bacteriocinogen
  report ( W-num * e-bacteriocinogen * C-num / N-num
  ) * dt
end

;; Report value of flow
to-report C-competition
  report ( C-num * N-num
  ) * dt
end

;; Report value of flow
to-report cheater-cost
  report ( C-num * q-cheater-cost
  ) * dt
end

;; Report value of flow
to-report C-toxin
  report ( C-num * a-toxin-production * C-num / N-num
  ) * dt
end

;; Report value of flow
to-report C-benefit
  report ( C-num * b-shared-benefit * W-num / N-num
  ) * dt
end

;; Report value of flow
to-report W-growth
  report ( W-num
  ) * dt
end

;; Report value of flow
to-report C-growth
  report ( C-num
  ) * dt
end

;; Report value of variable
to-report N-num
  report W-num + C-num
end

;; Report value of variable
to-report vir-num
  report wild-virulence * W-num + C-num
end

;; Plot the current state of the system dynamics model's stocks
;; Call this procedure in your plot's update commands.
to _system-dynamics-do-plot
  if plot-pen-exists? "C-num" [
    set-current-plot-pen "C-num"
    plotxy ticks C-num
  ]
  if plot-pen-exists? "W-num" [
    set-current-plot-pen "W-num"
    plotxy ticks W-num
  ]
end

;==================== begin random-poisson.nls ========================================
; _random-poisson - reports a Poisson-distributed random integer like random-poisson primitive for versions of
;  NetLogo that don't support it.
;
; Converted from <https://github.com/NetLogo/NetLogo/blob/5.x/src/main/org/nlogo/prim/etc/_randompoisson.java>
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
;  show _random-poisson 3.4
;  ;; prints a Poisson-distributed random integer with a
;  ;; mean of 3.4
;
; Revisions:
;
;   2015-07-17 - initial release by Rik Blok
;-------------------------------------------------------------------------------

to-report _random-poisson [ _mean ]
  let q 0
  let _sum 0 - ln ( 1 - random-float 1 )
  while [ _sum <= _mean ]
  [ set q q + 1
    set _sum _sum - ln (1 - random-float 1)
  ]
  report q
end
;==================== end random-poisson.nls ==========================================
@#$#@#$#@
GRAPHICS-WINDOW
195
264
527
525
-1
-1
12.0
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
26
0
20
0
0
1
ticks
30.0

SLIDER
13
416
185
449
q-cheater-cost
q-cheater-cost
0
5
5.0
0.01
1
NIL
HORIZONTAL

SLIDER
13
449
185
482
b-shared-benefit
b-shared-benefit
0
15
15.0
0.1
1
NIL
HORIZONTAL

SLIDER
13
515
185
548
e-bacteriocinogen
e-bacteriocinogen
0
1
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
13
482
185
515
a-toxin-production
a-toxin-production
-0.5
1
0.0
0.1
1
NIL
HORIZONTAL

BUTTON
27
340
94
373
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
105
340
168
373
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

PLOT
203
15
504
258
dynamics
time
density
0.0
0.0
0.0
0.0
true
true
"" ""
PENS
"wilds" 1.0 2 -10899396 true "" "plotxy ticks ( count wilds / count-patches )"
"W-num" 1.0 0 -4399183 true "" ""
"cheaters" 1.0 2 -2674135 true "" "plotxy ticks ( count cheaters / count-patches )"
"C-num" 1.0 0 -1069655 true "" ""
"virulence" 1.0 2 -16777216 true "" "plotxy ticks ( wild-virulence * count wilds + count cheaters ) / count-patches"
"vir-num" 1.0 0 -3026479 true "" "plotxy ticks vir-num"

PLOT
503
15
672
258
phase
wilds
cheaters
0.0
0.0
0.0
0.0
true
false
"clear-plot" ""
PENS
"agent" 1.0 2 -16777216 true "" "plotxy ( count wilds / count-patches ) ( count cheaters / count-patches )"
"num" 1.0 2 -3026479 true "" "plotxy W-num C-num"

SLIDER
13
265
185
298
initial-W-density
initial-W-density
0
2
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
13
297
185
330
initial-C-density
initial-C-density
0
0.2
0.05
0.01
1
NIL
HORIZONTAL

SWITCH
540
264
665
297
well-mixed
well-mixed
1
1
-1000

SLIDER
540
296
665
329
log-diffusion
log-diffusion
-2
4
0.3
0.1
1
NIL
HORIZONTAL

MONITOR
540
328
665
373
diff-const [patches^2/tick]
diffusion-const
2
1
11

MONITOR
540
505
665
550
ticks
;precision ticks (2 - ceiling log dt 10)\nsigfigs-other ticks dt 2
10
1
11

MONITOR
540
461
665
506
dt
;precision dt (2 - ceiling log dt 10)\nsigfigs dt 2
10
1
11

SLIDER
540
384
665
417
err-tolerance
err-tolerance
-2
0
-1.0
0.2
1
NIL
HORIZONTAL

MONITOR
540
417
665
462
accuracy (%)
;100 * ( 1 - precision per-capita-mean-error (1 - ceiling log per-capita-mean-error 10) )\n100 * ( 1 - sigfigs per-capita-mean-error 1 )
10
1
11

SLIDER
13
384
185
417
x-wild-cost
x-wild-cost
0
10
10.0
0.01
1
NIL
HORIZONTAL

OUTPUT
12
15
204
258
10

@#$#@#$#@
## A Trojan horse approach to medical intervention strategies

A [NetLogo] model by Rik Blok.

[http://www.zoology.ubc.ca/~rikblok/wiki/doku.php?id=science:popmod:brown2009:start](http://www.zoology.ubc.ca/~rikblok/wiki/doku.php?id=science:popmod:brown2009:start)

This agent-based model represents a bacterial infection as described in [[Brown2009]].  It is assumed the wild type (W) produces a public good (F) which benefits all.  To combat the infection the population is innoculated with a "cheater" strain (C).  Changes are simply represented as elementary reactions between (local) agents:

  * N → 2 N    @ rate 1 (growth)
  * W + N → N    @ rate 1 (competition)
    C + N → N    @ rate 1
  * W → W + F    @ rate b (public good)
    W + F → 2 W    @ rate β
  * W → ∅    @ rate x (wild cost)
  * C → ∅    @ rate q (cheater cost)

where N indicates an individual of either type and ∅ indicates an absence of products.

Additionally, the cheater strain has one or more of the following traits:

  * It consumes but does not produce the public good (F),
    C + F → 2 C    @ rate β
  * It produces a toxin (T) that harms all,
    C → C + T    @ rate a
    N + T → ∅    @ rate δ
  * It produces a bacteriocinogen (B) it is immune to but harms the wild type,
    C → C + B    @ rate e
    C + B → C    @ rate γ
    W + B → ∅    @ rate γ.


The target and infected cells are fixed whereas the virions move randomly with diffusion constant diff-const.  If 'well-mixed' is on then they are shuffled randomly in space with each timestep.

Finally, it is assumed that the wild type is more "virulent" (harmful to the host) than the cheater strain.

## How it works

The simulation approximates a Poisson process for each of the above events.  The best known technique would be the Gillespie algorithm [[Gibson2000]] but it isn't well suited to NetLogo's strengths.  Instead, time proceeds in steps with multiple events occurring in each timestep.

The step size is adaptive, chosen to achieve a desired error tolerance, compared with the Gillespie algorithm.  When the error tolerance is near zero the likelihood of each event is small and we may expect just a few events to occur per timestep.  Then we're accurately -- but inefficiently -- mimicking the Gillespie algorithm.  As the tolerance increases we have more simultaneous events, lowering accuracy but increasing performance.

## References

[[Brown2009]] Brown, Sam P., West, Stuart A., Diggle, Stephen P., and Griffin, Ashleigh S. [Social evolution in micro-organisms and a Trojan horse approach to medical intervention strategies](http://rstb.royalsocietypublishing.org/content/364/1533/3157). Philosophical Transactions of the Royal Society B: Biological Sciences, 364: 3157-3168. doi:[10.1098/rstb.2009.0055](http://dx.doi.org/10.1098/rstb.2009.0055). 2009.

[[Gibson2000]] Gibson, Michael A. and Bruck, Jehoshua. [Efficient Exact Stochastic Simulation of Chemical Systems with Many Species and Many Channels](http://dx.doi.org/10.1021/jp993732q). J. Phys. Chem. A, 104(9): 1876-1889. doi:[10.1021/jp993732q](http://dx.doi.org/10.1021/jp993732q). 2000.

[[NetLogo]] Wilensky, U. NetLogo. [http://ccl.northwestern.edu/netlogo/](http://ccl.northwestern.edu/netlogo/). Center for Connected Learning and Computer-Based Modeling, Northwestern University. Evanston, IL. 1999.

[Brown2009]: http://dx.doi.org/10.1098/rstb.2009.0055
[Gibson2000]: http://dx.doi.org/10.1021/jp993732q
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
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.2
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
