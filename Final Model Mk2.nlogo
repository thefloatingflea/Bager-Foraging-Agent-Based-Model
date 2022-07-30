;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------;
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][] AGENT BASED MODEL BADGER [][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][][] Mk 1 [][][][][][][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------;

;REQUIRED MODEL ASPECTS
;      - An environment which has a park/suburban/urban area which can have each by %
;      - food patches which can be found in both urban and suburban areas
;      - A perfect data record which is sampled by a camera record
;      - Badgers with individual memory of food patches
;      - A mechanism of generating and maintaining seeds
;      - Badgers with a correlated random walk model
;      - A mechanism of writing up the data
;      - A mechanims to generate human activity as a urban cost

;SECONDARY MODEL ASPECTS
;      - A mechanism to generate light
;      - A way to categorise habitats as linear

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------;
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][  GLOBAL VARIABLES  ][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------;

;[][][][][][]> Breeds <[][][][][][]

;[][] > objects < [][]

;plants
breed [ trees tree ]
breed [ lonetrees lonetree ]
breed [ tufts tuft ]
breed [ bushes bush ]
breed [ flowers flower ]

;anthroprogenic object
breed [buildings building]

;[][] > agents < [][]

;animals
breed [ setts sett ]
breed [ badgers badger ]

;food
breed [ foodpatches foodpatch ]
breed [ meals meal ]

;anthroprogenic
breed [ cameras camera ]

;functional
breed [ contractors contractor ]
breed [ nodes node ]

;[][][][][][]> Globals <[][][][][][]

globals [

  ;world building globals
  grasspatch
  woodpatch
  scatreepatch
  scrubpatch
  concretepatch
  roadpatch
  builtupatch
  gardenpatch
  vacant
  grasscol
  woodcol
  scatreecol
  scrubcol
  concretecol
  roadcol
  builtupcol
  gardencol
  vacantcol

  ;simulation globals
  buffets
  nightcount
  camerasites

  ;functional globals
  target
  variable
  measure
  currentseed
  errorate

  ;data globals
  night-calories
  total-calories
  total-speed
  current-speed
]

;Variables owned by agents/patch
patches-own [ identity diary? entry cost settdist]
cameras-own [ images record groupvariable]
foodpatches-own [ sites reliability active? first? visited?]
badgers-own [ discovery? sites speed calories smell home? openpoints closedpoints maxspeed mycol vision]
nodes-own [ gcost hcost fcost open? closed? current? start? target? visited? mother father waypoint ]

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------;
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][  HOMEBOX FUNCTIONS  ][[][][][][][][][][][[][][][][][][][][
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------;

;[][][][][][]> Global <[][][][][][]


to setseed
  if randomseed = false [set currentseed seed]
  if randomseed = true [set currentseed random 2147483647]
  random-seed currentseed
end

;[][][][][][]> World Building <[][][][][][]

to render
  clear-all
  reset-ticks
  set nightcount 0
  setseed
  patchgen
  clearvacant
  setpatches
  setpatchcost
  objectgen
end

to multirender
  clear-all
  reset-ticks
  set nightcount 0
  patchgen
  clearvacant
  setpatches
  setpatchcost
  objectgen
end

;[][][][][][]> Running Simulation <[][][][][][]

to simulate
  reset
  setseed
  run-sim
end

to multisim
  render
  reset
  setseed
  set runo 1
  repeat simulations [
    run-sim
    if overwright? = true [show "ERROR DISABLE OVERWRIGHT"]
    export
    set runo runo + 1
    set seed seed + 1
    random-seed seed
    ifelse multi-render = true [multirender][reset]
  ]
  set runo 1
end


;[][][][][][]> Data Writing <[][][][][][]

to export
  ask cameras [die]
  spawncameras
  runcameras
  writedata
  ask cameras [die]
end

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------;
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][  PRIMARY FUNCTIONS  ][[][][][][][][][][][[][][][][][][][][
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------;

;[][][][][][]> World Building <[][][][][][]

to patchgen
  setpixelcounts
  gengrass
  genwoodland
  genscatree
  genscrub
  genconcrete
  genroad
  gengarden
  genbuiltup
end

to objectgen
  spawnbadgers
  genobj
  spawnfoodpatches
end

;[][][][][][]> Running Simulation <[][][][][][]

to run-sim
  ifelse pen? = true [ask badgers [pen-down set pen-size 2]][ask badgers [pen-up]]

  repeat nights
  [


    repeat (nightlength * 60)
    [
      patchdiaries
      ask badgers [badgerun]
      tick
    ]

    reset-night
  ]
end

to reset
  reset-ticks
  ask badgers [move-to home? setbadgers]
  ask patches [set diary? false set entry (list)]
  set nightcount 0
  ask meals [die]
  ask foodpatches [spawnfood]
  ask cameras [die]
  set total-speed 0
  clear-drawing
  clear-all-plots
end

;[][][][][][]> Data Writing <[][][][][][]

to writedata
  file-close
  if overwright? = true [
    if file-exists? "D:\\UNI\\Masters\\Project 2 Term 1 - Agent Based Modelling\\Developtment\\NetLogoR\\Test Models\\netelogotextfiles\\modatmain.csv"[
      show "overwright success"
      file-delete "D:\\UNI\\Masters\\Project 2 Term 1 - Agent Based Modelling\\Developtment\\NetLogoR\\Test Models\\netelogotextfiles\\modatmain.csv"]
    if file-exists? "D:\\UNI\\Masters\\Project 2 Term 1 - Agent Based Modelling\\Developtment\\NetLogoR\\Test Models\\netelogotextfiles\\imagedat.csv"[
      show "overwright success"
      file-delete "D:\\UNI\\Masters\\Project 2 Term 1 - Agent Based Modelling\\Developtment\\NetLogoR\\Test Models\\netelogotextfiles\\imagedat.csv"]
    if file-exists? "D:\\UNI\\Masters\\Project 2 Term 1 - Agent Based Modelling\\Developtment\\NetLogoR\\Test Models\\netelogotextfiles\\modatcam.csv"[
      show "overwright success"
      file-delete "D:\\UNI\\Masters\\Project 2 Term 1 - Agent Based Modelling\\Developtment\\NetLogoR\\Test Models\\netelogotextfiles\\modatcam.csv"]
  ]

  ;writing data
  file-open "D:\\UNI\\Masters\\Project 2 Term 1 - Agent Based Modelling\\Developtment\\NetLogoR\\Test Models\\netelogotextfiles\\modatmain.csv"
  file-print "badgerid,night,ticks, badgerxcor,badgerycor,xcor,ycor,speed,identity,pcolor,setprox,runo"
  file-close
  ask patches with [(length entry) > 0]
    [set variable 0
    loop [
      file-open "D:\\UNI\\Masters\\Project 2 Term 1 - Agent Based Modelling\\Developtment\\NetLogoR\\Test Models\\netelogotextfiles\\modatmain.csv"
      file-print (reduce word (item variable entry))
      file-close
      set variable (variable + 1)
      if variable >= (length entry - 1) [stop]
    ]
  ]

  ;writing camera data
  file-open "D:\\UNI\\Masters\\Project 2 Term 1 - Agent Based Modelling\\Developtment\\NetLogoR\\Test Models\\netelogotextfiles\\modatcam.csv"
  file-print "groupid,camid,badgerid,night,ticks,badgerxcor,badgerycor,xcor,ycor,speed,identity,pcolor,setprox,runo"
  file-close
  ask cameras with [(length record) > 0]
    [set variable 0
    loop [
      file-open "D:\\UNI\\Masters\\Project 2 Term 1 - Agent Based Modelling\\Developtment\\NetLogoR\\Test Models\\netelogotextfiles\\modatcam.csv"
        file-print (reduce word (list [groupvariable] of self "," [who] of self "," reduce word (item variable record)))
      file-close
      set variable (variable + 1)
      if variable = (length record) [stop]
    ]
  ]
  ;writing raster csv
  ;file-open "D:\\UNI\\Masters\\Project 2 Term 1 - Agent Based Modelling\\Developtment\\NetLogoR\\Test Models\\netelogotextfiles\\imagedat.csv"
  ;file-print "X,Y,Z"
  ;file-close
  ;ask patches
  ;[ file-open "D:\\UNI\\Masters\\Project 2 Term 1 - Agent Based Modelling\\Developtment\\NetLogoR\\Test Models\\netelogotextfiles\\imagedat.csv"
  ;  file-print reduce word (list ([pxcor] of self) "," ([pycor] of self) "," ([identity] of self))
  ;  file-close
  ;]
end

to runcameras
  createvoidat
  ask cameras
  [
    camera-sample
  ]
end

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------;
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][  SECONDARY FUNCTIONS  ][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------;

;[][][][][][]> World Building <[][][][][][]

; > park <

to setpixelcounts
  set woodpatch ((count patches) * (woodland / 100))
  set scatreepatch ((count patches) * (scattered-trees / 100))
  set scrubpatch ((count patches) * (scrub / 100))
  set roadpatch ((count patches) * (road / 100))
  set builtupatch ((count patches) * (builtup / 100))
  set gardenpatch ((count patches) * (garden / 100))
  set concretepatch ((count patches) * (concrete / 100)) + builtupatch + roadpatch + gardenpatch
  set grasspatch ((count patches) * (grass / 100)) + woodpatch + scatreepatch + scrubpatch
  set vacant count patches - (woodpatch + scatreepatch + scrubpatch + concretepatch + roadpatch + builtupatch + gardenpatch + grasspatch)

  if colour-map = "realistic" [
    set grasscol 68
    set woodcol 52
    set scatreecol 56
    set scrubcol 57
    set concretecol 8
    set roadcol 2
    set builtupcol 4
    set gardencol 66
    set vacantcol 0]
  if colour-map = "functional" [
    set grasscol 68
    set woodcol 52
    set scatreecol 37
    set scrubcol 46
    set concretecol 8
    set roadcol 1
    set builtupcol blue
    set gardencol green
    set vacantcol 0]


  ask patches [set identity "vacant"]
end

to gengrass
  if grasspatch >= park-number [
    ask n-of park-number patches [set pcolor grasscol]
    repeat grasspatch - park-number
    [
      set target one-of patches with [pcolor = grasscol and any? neighbors with [pcolor != grasscol]]
      ask target [ask one-of neighbors with [pcolor != grasscol] [set pcolor grasscol set identity "grass"]]
    ]
  ]
end

to genwoodland
  if woodpatch >= 1 [
    ask n-of (0.05 * woodpatch) patches with [pcolor = grasscol] [set pcolor woodcol set identity "woodland"]
    repeat woodpatch - (0.05 * woodpatch)
    [
      set target one-of patches with [pcolor = woodcol and any? neighbors with [pcolor = grasscol]]
      ask target [ask one-of neighbors with [pcolor = grasscol] [set pcolor woodcol set identity "woodland"]]
    ]
  ]
end

to genscatree
  if scatreepatch >= 1 [
    ask n-of (0.05 * scatreepatch) patches with [pcolor = grasscol] [set pcolor scatreecol set identity "scattered tree"]
    repeat scatreepatch - (0.05 * scatreepatch)
    [
      set target one-of patches with [pcolor = scatreecol and any? neighbors with [pcolor = grasscol]]
      ask target [ask one-of neighbors with [pcolor = grasscol] [set pcolor scatreecol set identity "scattered tree"]]
    ]
  ]
end



to genscrub
  if scrubpatch >= 1 [
    ask n-of (0.05 * scrubpatch) patches with [pcolor = grasscol] [set pcolor scrubcol set identity "scrub"]
    repeat scrubpatch - (0.05 * scrubpatch)
    [
      set target one-of patches with [pcolor = scrubcol and any? neighbors with [pcolor = grasscol]]
      ask target [ask one-of neighbors with [pcolor = grasscol] [set pcolor scrubcol set identity "scrub"]]
    ]
  ]
end

; > urban <

to genconcrete
  if concretepatch >= 1 [
    ask n-of concretepatch patches with [pcolor = vacantcol] [set pcolor concretecol set identity "concrete"]]
end

to genroad
  set variable 8
  if roadpatch >= 1 [
    repeat roadpatch [ask one-of patches with [int (pxcor / variable) = (pxcor / variable) and int (pycor / variable) = (pycor / variable) and pcolor = concretecol or pcolor = roadcol] [set pcolor roadcol set identity "road"]]

    loop
    [
      set target patches with [int (pycor / variable) = (pycor / variable) and pcolor = concretecol]
      ifelse target != nobody and target != no-patches
      [ask one-of target [set pcolor roadcol set identity "road"]]
      [set variable variable - 2]
      set target patches with [int (pxcor / variable) = (pxcor / variable) and pcolor = concretecol]
      ifelse target != nobody and target != no-patches
      [ask one-of target [set pcolor roadcol set identity "road"]]
      [set variable variable - 2]
      if count patches with [pcolor = roadcol] > roadpatch [stop]
    ]
  ]
end



to gengarden
  if gardenpatch >= 1 [
    repeat gardenpatch
    [
      ifelse any? patches with [pcolor = concretecol and any? neighbors with [pcolor = roadcol]] = true
      [
        set target one-of patches with [pcolor = concretecol and any? neighbors with [pcolor = roadcol]]
        ask target [set pcolor gardencol set identity "garden"]
      ]
      [
        set target one-of patches with [pcolor = concretecol and any? neighbors with [pcolor = gardencol]]
        ask target [set pcolor gardencol set identity "garden"]
      ]
    ]
  ]
end

to genbuiltup
  if builtupatch >= 1 [
    ask n-of (0.5 * builtupatch) patches with [pcolor = concretecol] [set pcolor builtupcol set identity "building"]
    repeat builtupatch - (0.5 * builtupatch)
    [
      set target one-of patches with [pcolor = concretecol and (count neighbors4 with [pcolor = builtupcol] >= 1)]
      if target = nobody or target = no-patches [set target one-of patches with [pcolor = concretecol or identity = "vacant"]]
      ask target [set pcolor builtupcol set identity "building"]
    ]
  ]
end

; > objects <

to genobj
  ;plants
  ask n-of (count grasspatch * 0.3) grasspatch [sprout-tufts 1]
  ask n-of (count scrubpatch * 0.3) scrubpatch [sprout-bushes 1]
  ask n-of (count gardenpatch * 0.3) gardenpatch [sprout-flowers 1]
  ask n-of (count scatreepatch * 0.3) scatreepatch [sprout-lonetrees 1]
  ask n-of (count woodpatch * 0.7) woodpatch [sprout-trees 1]

  ;anth objects
  ask builtupatch [sprout-buildings 1]
  ask trees [set shape "tree" set color 51 set size 1.2 set heading 0 fd 0.5]
  ask lonetrees [set shape "tree" set color 53 set size 1.2 set heading 0 fd 0.5]
  ask bushes [set shape "plant" set color 55 set heading 0 fd 0.5]
  ask tufts [set shape "grass" set color 65 set heading 0 fd 0.5]
  ask flowers [set shape "flower" set color yellow set size 0.8 set heading 0 fd 0.5]
  ask buildings [set shape one-of (list "house bungalow" "house colonial" "house efficiency" "house ranch" "house two story") set color 105 set size 1.4 set heading 0 fd 0.3]

  if objects = false [foreach (list trees lonetrees bushes tufts flowers buildings) [x -> ask x [die]]]

  ;functional

  ask patches with [int (pxcor / 3) = (pxcor / 3) and int (pycor / 3) = (pycor / 3) and identity != "building"] [sprout-nodes 1 [set waypoint false resetnodes]]
  ask setts [ask nodes-here [die]]

end

to spawnbadgers
  setpatches
  let settsites patch-set (list woodpatch scrubpatch)
  ask n-of sett-number settsites [sprout-setts 1 [setsetts] ]
  repeat badger-number [ask one-of setts [hatch-badgers 1  [setbadgers]]]
  ask patches [set settdist distance min-one-of setts [distance myself]]
end


to spawnfoodpatches
  set target patch-set (list woodpatch scatreepatch scrubpatch grasspatch)
  ask n-of natural-food-patches target [sprout-foodpatches 1 [setfoodpatch]]
  set target patch-set (list gardenpatch concretepatch)
  ask n-of anthroprogenic-food-patches target [sprout-foodpatches 1 [setfoodpatch]]
end


to spawncameras
  ifelse nested? = true
  [spawnestedcameras]
  [
  ifelse random-habitat-cameras? = true
  [
    ifelse grid? = false
    [set camerasites patches with [identity != "building"]]
    [set camerasites patches with [int (pxcor / 15) = (pxcor / 15) and int (pycor / 15) = (pycor / 15) and identity != "building"]]
    ifelse number-of-cameras <= count camerasites
    [ask n-of number-of-cameras camerasites [sprout-cameras 1 [setupcamera set groupvariable "NA"]]
    ]
    [show "Error not enough camera sites!"]
  ]

  [set camerasites patches with [int (pxcor / 15) = (pxcor / 15) and int (pycor / 15) = (pycor / 15) and identity != "building"]
    ifelse number-of-cameras <= count camerasites and
    grass-cameras <= count camerasites with [identity = "grass"] and
    woodland-cameras <= count camerasites with [identity = "woodland"] and
    garden-cameras <= count camerasites with [identity = "garden"] and
    road-cameras <= count camerasites with [identity = "road"] and
    concrete-cameras <= count camerasites with [identity = "concrete"]
    [
    ask n-of grass-cameras camerasites [sprout-cameras 1 [setupcamera set groupvariable "NA"]]
    ask n-of woodland-cameras camerasites [sprout-cameras 1 [setupcamera set groupvariable "NA"]]
    ask n-of garden-cameras camerasites [sprout-cameras 1 [setupcamera set groupvariable "NA"]]
    ask n-of road-cameras camerasites [sprout-cameras 1 [setupcamera set groupvariable "NA"]]
    ask n-of concrete-cameras camerasites [sprout-cameras 1 [setupcamera set groupvariable "NA"]]]
    [show "Error not enough camera sites!"]]
  ]
end

to spawnestedcameras
  set variable [nobody]
  ask foodpatches [set variable (patch-set variable ([sites] of self))]
  ask n-of (number-of-cameras / 3) variable [set measure random 9999999 ask n-of 3 patches in-radius 3 [sprout-cameras 1 [setupcamera set groupvariable measure]]]
end


;[][][][][][]> Running Simulation <[][][][][][]

to patchdiaries
  ask badgers [ask patch-here [add-entry]]
end

to reset-night
  reset-ticks
  ask meals [die]
  ask foodpatches [spawnfood]
  ask badgers [pen-up move-to home? if pen? = true [pen-down]]
  if badge-memory = true [badgerdream]
  ask badgers [set discovery? false set calories 0]
  set night-calories 0
  set nightcount nightcount + 1
end

to badgerun
  sniff
  ifelse (count openpoints > 0 and badge-memory = true)
    [
      set pen-size 2
      set color mycol
      waypointmove]
  [set pen-size 0.5
    set color orange
    randomove]
  fd speed
  set total-speed total-speed + speed
  set current-speed speed
  predate
  set maxspeed 34.3
end

to badgerdream
  ask badgers[
    set buffets sites

    ifelse discovery? = true [

      let setthere one-of setts-here

      ask buffets [
        set active? false
        set visited? false
      ]
      ask min-one-of buffets [distance setthere] [set first? true set active? true]

      repeat (count buffets - 1)
      [ask buffets with [active? = true] [
        ask min-one-of nodes [distance myself] [set start? true]
        ask min-one-of other buffets with [visited? = false] [distance myself]
        [
          ask min-one-of nodes [distance myself]
          [
            set target? true
          ]
          set active? true
        ]
        set visited? true
        set active? false
        pathfind
        ask nodes [resetnodes]
      ]]

      ask setthere [ask min-one-of nodes [distance myself] [set start? true]]
      ask one-of buffets with [first? = true] [ask min-one-of nodes [distance myself] [set target? true]]
      pathfind
      ask nodes [resetnodes]
      ask links [die]

      set closedpoints turtle-set nodes with [waypoint = true]
      set openpoints closedpoints
      ask nodes [set waypoint false]
    ]
    [set openpoints closedpoints]
    ask openpoints [set color red]
  ]
end


;[][][][][][]> Data Writing <[][][][][][]

; patches writing diaries

to add-entry
  set diary? true
  set entry insert-item 0 entry (list
    ([who] of myself) ","
    Nightcount ","
    ticks ","
    ([precision(xcor)1] of myself) ","
    ([precision(ycor)1] of myself) ","
    ([precision(pxcor)0] of self) ","
    ([precision(pycor)0] of self) ","
    ([speed] of myself) ","
    ([identity] of self) ","
    ([pcolor] of self) ","
    ([settdist] of self) ","
    (runo)
  )
end


to camera-sample
  set images 1
  set record [entry] of patch-here
end

to createvoidat
  ask patches with [diary? != true][set entry (list (list "na" "," "na" "," "na" "," "na" "," "na" "," ([precision(pxcor)0] of self) "," ([precision(pycor)0] of self) "," "na" "," ([identity] of self) "," ([pcolor] of self) "," ([settdist] of self) "," (runo)))]
end

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------;
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][  TERTIARY FUNCTIONS  ][[][][][][][][][][][[][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------;

;[][][][][][]> World Building <[][][][][][]

to buffer
  ask patches with [identity != "building"] [if any? neighbors with [identity != "building"] [set cost (random-normal (mean ([cost] of neighbors with [identity != "building"])) 0.001)]]
  ;ask patches [set pcolor (cost * 100 - 100)]
  ;ask patches with [identity = "building"] [set pcolor red]
end

to clearvacant
ask patches with [identity = "vacant"] [
let host one-of neighbors
set pcolor ([pcolor] of host)
set identity ([identity] of host)
set cost [cost] of host
if any? meals-here [ask meals-here [die]]
]
end

to setpatchcost
  ask woodpatch [set cost cost-woodland]
  ask scatreepatch [set cost cost-scatree]
  ask scrubpatch [set cost cost-scrub]
  ask grasspatch [set cost cost-grass]
  ask gardenpatch [set cost cost-garden]
  ask concretepatch [set cost cost-concrete]
  ask roadpatch [set cost cost-road]
  ask builtupatch [set cost 9999]
  if buffer? = true [buffer]
end

to setpatches
  set woodpatch patches with [identity = "woodland"]
  set scatreepatch patches with [identity = "scattered tree"]
  set scrubpatch patches with [identity = "scrub"]
  set roadpatch patches with [identity = "road"]
  set builtupatch patches with [identity = "building"]
  set gardenpatch patches with [identity = "garden"]
  set concretepatch patches with [identity = "concrete"]
  set grasspatch patches with [identity = "grass"]
  set vacant patches with [identity = "vacant"]
  ask patches [set entry (list)]
end


to setsetts
  set shape "setts"
  set color 1
  set size 1.2
end

to setbadgers
  set shape "badger"
  set mycol one-of (list red orange yellow green blue magenta violet lime sky)
  set color mycol
  set size 1.3
  set sites turtle-set nobody
  set home? min-one-of setts [distance myself]
  set discovery? false
  set closedpoints turtle-set nobody
  set openpoints turtle-set nobody
end

to setfoodpatch
  set shape "ring"
  set color blue
  set size 3
  set sites patches in-radius 1 with [identity != "building"]
  spawnfood
end

to spawnfood
  ;if random 20 > reliability [
  ;  ask one-of sites [
  ;    sprout-meals 1 [setmeals]
  ;]]
  ask one-of sites [
    sprout-meals 1 [setmeals]
  ]
end

to setmeals
  set shape "apple"
  set color sky
end

to resetnodes
  set closed? false
  set open? false
  set start? false
  set target? false
  set current? false
  set visited? false
  set gcost 0
  set hcost 0
  set fcost 0
  set shape "circle"
  set size 0.5
  set color roadcol
  if show-nodes = false [ht]
end

to setupcamera
  set record (list)
  set color violet
  set shape "camera"
end

;[][][][][][]> Running Simulation <[][][][][][]

to predate
  let prey meals in-radius 1.3
  if count prey > 0 [
    set calories calories + 1
    set night-calories night-calories + 1
    set total-calories total-calories + 1
    ask prey [die]
    if member? (min-one-of foodpatches [distance myself]) sites = false [set sites (turtle-set sites (min-one-of foodpatches [distance myself]))]
    set discovery? true ]
end

to sniff
  set variable (random-normal 2 0.1)
  if variable < 0.1 [set variable 0.1]
  set smell patches in-radius variable
end

to randomove
  set heading random 360
  ifelse any? meals-on smell
  [
    set speed precision (bounded-random-pareto 3.0 0.2 24) 1
    patchline
    set color color - 2
  ]
  [
    set speed precision (bounded-random-pareto 1.0 0.2 24) 1
    patchline
    if movement-cost = true [costeval]
    patchline
  ]
end

to waypointmove
  set heading random 360
  ifelse any? meals-on smell
  [
    set speed precision (bounded-random-pareto 3.0 0.2 24) 1
    patchline
    set color color - 2
  ]
  [
    if distance min-one-of openpoints [distance myself] > 1
    [set heading (towards min-one-of openpoints [distance myself])]
    set speed precision (bounded-random-pareto 1.0 0.2 24) 1
    patchline
    if movement-cost = true [costeval]
    patchline
  ]
  let currentwaypoint min-one-of openpoints [distance myself]
  if distance currentwaypoint < 2
  [
    ;ask currentwaypoint [set color orange]
    set openpoints openpoints with [self != currentwaypoint]
  ]
end


to pathfind
  ask nodes [ set open? false set closed? false set current? false set color 2 set shape "circle" set size 0.5 ]

  let start one-of nodes with [start? = true]
  ask start [set open? true set mother [who] of self]
  let targetnode one-of nodes with [target? = true]
  let open-nodes nodes with [target? = false or start? = false]

  let current start
  let neighbor-nodes turtle-set [other nodes in-radius 4.5] of current
  let old-path 0
  let new-path 0
  let path-link link-set nobody
  let path 0


  loop [
    set current min-one-of (nodes with [open? = true]) [fcost]

    if current = targetnode
    [
      ask nodes with [open? = true and target? = false] [set open? false set color 2 ask my-links [die]]
      ask nodes with [closed? = true or target? = true and start? = false] [ask node mother [create-link-with myself]]
      prune
      ask links [ask both-ends [set waypoint true]]
      stop
    ]

    set neighbor-nodes turtle-set [other nodes in-radius 4.5 with [closed? = false and color != red]] of current

    ask current [
      set current? true
      set open? false
      set closed? true
      set color orange]

    ask neighbor-nodes

    [
      set old-path motherpath [who] of current
      set father [who] of current
      set new-path fatherpath [who] of self
      if old-path > new-path or open? = false

      [
        set mother [who] of current
        set gcost new-path
        set hcost (distance targetnode) * [cost] of patch-here
        set fcost gcost + hcost
        if  open? = false [set open? true set color green ]]

      ask current [
        set current? false]
    ]
  ]
end

to-report motherpath [ id ]
  let start one-of nodes with [start? = true]
  set measure 0
  let pathstart node id
  let pathstep [mother] of pathstart
  let heading-node node pathstep
  ask pathstart [hatch-contractors 1]
  loop [
    ask contractors [
      ht
      set heading-node node pathstep
      set measure measure + distance heading-node
      move-to heading-node
      set pathstep [mother] of heading-node]
    if any? contractors-on start
    [ask contractors [die]
      report measure]

  ]
end

to-report fatherpath [ id ]
  let start one-of nodes with [start? = true]
  set measure 0
  let pathstart node id
  let pathstep [father] of pathstart
  let heading-node node pathstep
  ask pathstart [hatch-contractors 1]
  loop [
    ask contractors [
      ht
      set heading-node node pathstep
      set measure measure + distance heading-node
      move-to heading-node
      set pathstep [father] of heading-node]
    if any? contractors-on start
    [ask contractors [die]
      report measure]

  ]
end

to prune
  while [count (nodes with [closed? = true and count my-links < 2 and start? = false and target? = false]) > 0]
  [ask nodes with [closed? = true and count my-links < 2 and start? = false and target? = false]
    [ask my-links [die]
      resetnodes
  ]]
  ask nodes with [closed? = false and target? = false] [resetnodes]
end

to patchline
  let patch-line (patch-set
    patch-ahead 1
    patch-ahead 2
    patch-ahead 3
    patch-ahead 4
    patch-ahead 5
    patch-ahead 6
    patch-ahead 7
    patch-ahead 8
    patch-ahead 9
    patch-ahead 10
    patch-ahead 11
    patch-ahead 12
    patch-ahead 13
    patch-ahead 14
    patch-ahead 15
    patch-ahead 16
    patch-ahead 17
    patch-ahead 18
    patch-ahead 19
    patch-ahead 20
    patch-ahead 21
    patch-ahead 22
    patch-ahead 23
    patch-ahead 24
    patch-ahead 25
    patch-ahead 26
    patch-ahead 27
    patch-ahead 28
    patch-ahead 29
    patch-ahead 30
    patch-ahead 31
    patch-ahead 32
    patch-ahead 33
    patch-ahead 34
    patch-ahead 34.3)
  with [
    identity = "building"
  ]
  if patch-line != nobody and patch-line != no-patches [
    let barrier min-one-of patch-line [ precision (distance myself) 1 ]
    set maxspeed precision ((distance barrier) - 1) 1
    if maxspeed < 0 [set maxspeed 0]
  ]
  if speed > maxspeed [set speed maxspeed]
end

to costeval
  set variable speed
  ifelse speed > 1
  [set vision patches in-cone speed 240 with [distance myself > variable - 1 and distance myself > 0.2]]
  [set vision patches in-radius 1.5 with [distance myself > 1]]

  ;ask vision [sprout-nodes 1 [set size 0.3 set shape "circle"]]
  ifelse vision != nobody and vision != no-patches [
    set target min-one-of vision [cost]
    set heading (towards target)][set errorate errorate + 1]
  ;ask nodes [die]
end


to navloop
  set variable 0
  loop
  [
    if variable > 30 [move-to min-one-of patches with [identity != "building" and not any? badgers-here][distance myself]]
    set variable variable + 1
    ifelse patch-ahead 1 != nobody and
    [identity] of patch-ahead 1 != "building"
    [
      stop
    ]
    [set heading heading + random variable]
  ]
end

;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------;
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][  REPORTER FUNCTIONS  ][[][][][][][][][][][[][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------;

;[][][][][][]> World Building <[][][][][][]

;[][][][][][]> Running Simulation <[][][][][][]

to-report bounded-random-pareto [a l h]
  let u random-float 1
  report (-(((u * h ^ a) - (u * l ^ a) - (h ^ a)) / ((h ^ a) * (l ^ a)))) ^ (-(1 / a))
end

;[][][][][][]> Data Writing <[][][][][][]

;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][][][][] END [][][][][][][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]

;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][]  CODE BIN  [][][][][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]
;[][][[][][][][][][][][][[][][][][][][][][][][][][][][][][][][[][][][][][][][][][[][][][][][][][][]

;to costeval1
;  ifelse speed < 2
;  [set vision patches in-cone 2 270 with [not any? badgers-here and identity != "building"]]
;  [
;    ifelse patch-ahead speed != nobody [
;      set vision [patches with [not any? badgers-here and identity != "building"] in-radius 2] of patch-ahead speed][set errorate errorate + 1]]
;  ifelse vision != nobody and vision != no-patches [
;    set target min-one-of vision [cost]
;      set heading (towards target)][set errorate errorate + 1]
;end

;to genscatree2
;  if scatreepatch >= 1 [
;    ask n-of scatreepatch patches with [pcolor = grasscol] [set pcolor scatreecol set identity "scattered tree"]]
;end

;to spawnbadgers
;  setpatches
;  let settsites patch-set (list woodpatch scrubpatch)
;  ask n-of (sett-number * 0.2) settsites [sprout-setts 1 [setsetts] ]
;  ask setts [ask n-of (sett-number * 0.8 / (sett-number * 0.2)) settsites in-radius 6 [sprout-setts 1 [setsetts]]]
;  repeat badger-number [ask one-of setts [hatch-badgers 1  [setbadgers]]]
;end

;set neighbor-nodes turtle-set min-n-of 8 other nodes with [closed? = false and color != red] [distance current]
;ask n-of 720 patches with [identity != "building"] [sprout-nodes 1 [set waypoint false resetnodes]]

;to add-entry_old
;  set diary? true
;  set entry insert-item 0 entry (list
;    (reduce word [who] of badgers-here) ","
;    Nightcount ","
;    ticks ","
;    (reduce word [precision(xcor)1] of badgers-here) ","
;    (reduce word [precision(ycor)1] of badgers-here) ","
;    ([precision(pxcor)0] of self) ","
;    ([precision(pycor)0] of self) ","
;    (reduce word [speed] of badgers-here) ","
;    ([identity] of self) ","
;    ([pcolor] of self)
;  )
;end


;to genscatree
;  if scatreepatch >= 1 [
;    ask n-of (0.3 * scatreepatch) patches with [pcolor = grasscol] [set pcolor scatreecol set identity "scattered tree"]
;    repeat scatreepatch - (0.3 * scatreepatch)
;    [
;      set target one-of patches with [pcolor = scatreecol and any? neighbors with [pcolor = grasscol]]
;      ask target [ask one-of neighbors with [pcolor = grasscol] [set pcolor scatreecol set identity "scattered tree"]]
;    ]
;  ]
;end

;to navloop2
;  set measure 0
;  while
;  [
;    patch-ahead 1 = nobody or
;    [pxcor] of patch-ahead 1 = max-pxcor or
;    [pxcor] of patch-ahead 1 = min-pxcor or
;    [pycor] of patch-ahead 1 = max-pycor or
;    [pycor] of patch-ahead 1 = min-pycor or
;    [identity] of patch-ahead 1 = "building"]
;  [
;    set heading heading + variable
;    set measure measure + 1
;    if measure > 30 [stop]
;  ]
;  if measure >= 30 [move-to min-one-of patches with [
;    identity != "building" and
;    pxcor != max-pxcor and
;    pxcor != min-pxcor and
;    pycor != max-pycor and
;    pycor != min-pycor
;  ][distance myself]]
;  set measure 0
;end;

;to navloop1
;  set measure 0
;  while [patch-ahead 1 = nobody or [identity] of patch-ahead 1 = "building"]
;  [
;    set heading heading + variable
;    set measure measure + 1
;    if measure > 30 [stop]
;  ]
;  if measure >= 30 [
;    let space [neighbors] of patch-here
;    ifelse count space with [identity != "building"] > 0 [
;      move-to min-one-of space with [identity != "building"][distance myself]]
;    [move-to min-one-of patches with [identity != "building"] [distance myself]]
;  ]
;  set measure 0
;end


;to genroad_old
;  if roadpatch >= 1 [
;    ask patches with [int (pxcor / 8) = (pxcor / 8) and int (pycor / 8) = (pycor / 8)] [sprout-contractors 2 [set heading one-of [0 90 180 270]]]
;
;    loop
;    [
;      if any? patches with [pcolor = concretecol and any? neighbors with [pcolor = grasscol or pcolor = woodcol or pcolor = scatreecol or pcolor = scrubcol]]
;      [ask one-of patches with [pcolor = concretecol and any? neighbors with [pcolor = grasscol or pcolor = woodcol or pcolor = scatreecol or pcolor = scrubcol]] [set pcolor roadcol set identity "road"]]
;      ask one-of contractors [
;        fd 1
;        if [pcolor] of patch-here = concretecol [set pcolor roadcol set identity "road"]
;        if random 20 > 18  [set heading heading + one-of [0 90 180 270]]
;      ]
;      if count patches with [pcolor = roadcol] > roadpatch [ask contractors [die] stop]
;    ]
;  ]
;end

;to setpatchcost
;  ifelse cover-woodland = true [ask woodpatch[set cost 67]] [ask woodpatch[set cost 17]]
;  ifelse cover-scatree = true [ask scatreepatch[set cost 67]] [ask scatreepatch[set cost 17]]
;  ifelse cover-scrub = true [ask scrubpatch[set cost 67]] [ask scrubpatch[set cost 17]]
;  ifelse cover-garden = true [ask gardenpatch[set cost 67]] [ask gardenpatch[set cost 17]]
;  ifelse cover-grass = true [ask grasspatch[set cost 67]] [ask grasspatch[set cost 17]]
;  ifelse cover-concrete = true [ask concretepatch[set cost 67]] [ask concretepatch[set cost 17]]
;  ifelse cover-road = true [ask roadpatch[set cost 67]] [ask roadpatch[set cost 17]]
;  ask builtupatch [set cost 15]
;end
@#$#@#$#@
GRAPHICS-WINDOW
400
10
1228
839
-1
-1
20.0
1
10
1
1
1
0
0
0
1
-20
20
-20
20
0
0
1
Minutes
30.0

SLIDER
0
10
284
43
grass
grass
0
100
60.0
1
1
NIL
HORIZONTAL

MONITOR
285
10
340
55
 grass
(count patches with [identity = \"grass\"] / count patches) * 100
1
1
11

SLIDER
0
55
284
88
woodland
woodland
0
100
14.0
1
1
NIL
HORIZONTAL

SLIDER
0
100
284
133
scattered-trees
scattered-trees
0
100
16.0
1
1
NIL
HORIZONTAL

SLIDER
0
145
284
178
scrub
scrub
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
0
190
284
223
concrete
concrete
0
100
2.0
1
1
NIL
HORIZONTAL

SLIDER
0
235
284
268
builtup
builtup
0
100
2.0
1
1
NIL
HORIZONTAL

SLIDER
0
280
284
313
road
road
0
100
6.0
1
1
NIL
HORIZONTAL

SLIDER
0
325
284
358
garden
garden
0
100
0.0
1
1
NIL
HORIZONTAL

MONITOR
285
55
340
100
wood
(count patches with [identity = \"woodland\"] / count patches) * 100
1
1
11

MONITOR
285
100
340
145
scatrees
(count patches with [identity = \"scattered tree\"] / count patches) * 100
1
1
11

MONITOR
285
145
340
190
scrub
(count patches with [identity = \"scrub\"] / count patches) * 100
1
1
11

MONITOR
285
190
340
235
concrete
(count patches with [identity = \"concrete\"] / count patches) * 100
1
1
11

MONITOR
285
235
340
280
builtup
(count patches with [identity = \"building\"] / count patches) * 100
1
1
11

MONITOR
285
280
340
325
road
(count patches with [identity = \"road\"] / count patches) * 100
1
1
11

MONITOR
285
325
340
370
garden
(count patches with [identity = \"garden\"] / count patches) * 100
1
1
11

MONITOR
285
370
340
415
vacant
(count patches with [identity = \"vacant\"] / count patches) * 100
3
1
11

MONITOR
0
370
285
415
%
(grass + woodland + scattered-trees + scrub + concrete + builtup + road + garden)
0
1
11

BUTTON
0
725
340
765
NIL
render\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
0
415
50
460
Height
reduce word (list (max-pxcor * 20)\"m\")
17
1
11

MONITOR
50
415
107
460
Width
reduce word (list (max-pycor * 20)\"m\")
0
1
11

MONITOR
107
415
177
460
Patch Size
reduce word (list \"10m x 10m\")
0
1
11

SLIDER
0
460
285
493
park-number
park-number
1
20
1.0
1
1
Park(s)
HORIZONTAL

SWITCH
105
690
195
723
objects
objects
0
1
-1000

BUTTON
265
415
340
448
clear vacant
ask patches with [identity = \"vacant\"] [\nlet host one-of neighbors\nset pcolor ([pcolor] of host)\nset identity ([identity] of host)\nset cost [cost] of host\nif any? meals-here [ask meals-here [die]]\n]
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
0
490
285
523
sett-number
sett-number
1
20
3.0
1
1
Sett(s)
HORIZONTAL

SLIDER
0
520
285
553
badger-number
badger-number
1
70
3.0
1
1
Badger(s)
HORIZONTAL

SLIDER
0
550
285
583
natural-food-patches
natural-food-patches
0
250
14.0
1
1
Patch(es)
HORIZONTAL

SLIDER
0
580
285
613
anthroprogenic-food-patches
anthroprogenic-food-patches
0
60
3.0
1
1
Patch(es)
HORIZONTAL

SWITCH
0
690
105
723
show-nodes
show-nodes
0
1
-1000

SLIDER
1760
360
1950
393
number-of-cameras
number-of-cameras
0
1000
25.0
1
1
Camera(s)
HORIZONTAL

CHOOSER
195
678
333
723
colour-map
colour-map
"realistic" "functional"
0

SLIDER
0
610
285
643
nights
nights
1
100
14.0
1
1
Night(s)
HORIZONTAL

SLIDER
0
640
285
673
nightlength
nightlength
1
12
5.0
1
1
Hours(s)
HORIZONTAL

BUTTON
0
885
115
918
Run Simulation
run-sim
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
0
765
103
798
pen?
pen?
0
1
-1000

MONITOR
0
840
57
885
Nights
nightcount
0
1
11

BUTTON
113
885
176
918
NIL
reset
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
1830
630
1945
663
overwright?
overwright?
1
1
-1000

BUTTON
1760
630
1827
663
export
export
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1760
10
1960
160
Calories Per Night
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot night-calories"

SWITCH
55
840
192
873
badge-memory
badge-memory
0
1
-1000

SWITCH
0
970
122
1003
randomseed
randomseed
0
1
-1000

MONITOR
0
925
80
970
seed
seed
17
1
11

SLIDER
0
1005
172
1038
seed
seed
0
2147483647
0.0
1
1
NIL
HORIZONTAL

MONITOR
1760
310
1842
355
total calories
total-calories
17
1
11

PLOT
1760
160
1960
310
Speed
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"pen-0" 1.0 0 -14835848 true "" "plot current-speed"

MONITOR
1840
310
1927
355
total distance
total-speed
0
1
11

BUTTON
125
970
240
1003
set simulation seed
setseed
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
1760
1020
1897
1053
movement-cost
movement-cost
1
1
-1000

BUTTON
1760
950
1862
983
Set New Cost
setpatchcost
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
1760
745
1932
778
cost-woodland
cost-woodland
1
1.1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
1760
780
1932
813
cost-scatree
cost-scatree
1
1.1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
1760
815
1932
848
cost-scrub
cost-scrub
1
1.1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
1760
710
1932
743
cost-grass
cost-grass
1
1.1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
1760
850
1932
883
cost-garden
cost-garden
1
1.1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
1760
915
1932
948
cost-concrete
cost-concrete
1
1.1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
1760
885
1932
918
cost-road
cost-road
1
1.1
1.0
0.01
1
NIL
HORIZONTAL

BUTTON
1760
985
1840
1018
ViewCost
\nask patches [set pcolor (cost * cost) * 2]\nask patches with [cost > 1] [set pcolor 4]\nask badgers [ask closedpoints [st set color red set size 2]]\nask patches with [cost > 1] [ask nodes-here [set color yellow]]
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
1760
395
1950
428
grass-cameras
grass-cameras
0
100
0.0
1
1
camera(s)
HORIZONTAL

SLIDER
1760
430
1950
463
woodland-cameras
woodland-cameras
0
100
0.0
1
1
camera(s)
HORIZONTAL

SLIDER
1760
465
1950
498
garden-cameras
garden-cameras
0
100
0.0
1
1
camera(s)
HORIZONTAL

SLIDER
1760
500
1950
533
road-cameras
road-cameras
0
100
0.0
1
1
camera(s)
HORIZONTAL

SLIDER
1760
535
1950
568
concrete-cameras
concrete-cameras
0
100
0.0
1
1
camera(s)
HORIZONTAL

SWITCH
1760
595
1950
628
random-habitat-cameras?
random-habitat-cameras?
0
1
-1000

SLIDER
1760
565
1950
598
scatree-cameras
scatree-cameras
0
100
0.0
1
1
camera(s)
HORIZONTAL

BUTTON
1765
1070
1865
1103
NIL
clear-drawing
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1760
665
1817
710
NIL
errorate
0
1
11

BUTTON
1765
1105
1865
1138
show data
ask patches [set pcolor length entry / ([length entry] of max-one-of patches [length entry]) * 100]\nask patches with [identity = \"woodland\" or identity = \"scattered tree\"] [sprout-nodes 1 [set shape \"square\" set color blue set size 0.6]]\n
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
25
1085
197
1118
simulations
simulations
0
100
20.0
1
1
run(s)
HORIZONTAL

SWITCH
200
1085
320
1118
multi-render
multi-render
0
1
-1000

BUTTON
25
1050
320
1083
Run Multiple Simulations
multisim
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
25
1120
75
1180
runo
1.0
1
0
Number

BUTTON
75
1120
182
1153
clear directory
if file-exists? \"D:\\\\UNI\\\\Masters\\\\Project 2 Term 1 - Agent Based Modelling\\\\Developtment\\\\NetLogoR\\\\Test Models\\\\netelogotextfiles\\\\modatmain.csv\"[\n      show \"overwright success\"\n      file-delete \"D:\\\\UNI\\\\Masters\\\\Project 2 Term 1 - Agent Based Modelling\\\\Developtment\\\\NetLogoR\\\\Test Models\\\\netelogotextfiles\\\\modatmain.csv\"]\n      if file-exists? \"D:\\\\UNI\\\\Masters\\\\Project 2 Term 1 - Agent Based Modelling\\\\Developtment\\\\NetLogoR\\\\Test Models\\\\netelogotextfiles\\\\imagedat.csv\"[\n      show \"overwright success\"\n      file-delete \"D:\\\\UNI\\\\Masters\\\\Project 2 Term 1 - Agent Based Modelling\\\\Developtment\\\\NetLogoR\\\\Test Models\\\\netelogotextfiles\\\\imagedat.csv\"]\n    if file-exists? \"D:\\\\UNI\\\\Masters\\\\Project 2 Term 1 - Agent Based Modelling\\\\Developtment\\\\NetLogoR\\\\Test Models\\\\netelogotextfiles\\\\modatcam.csv\"[\n      show \"overwright success\"\n      file-delete \"D:\\\\UNI\\\\Masters\\\\Project 2 Term 1 - Agent Based Modelling\\\\Developtment\\\\NetLogoR\\\\Test Models\\\\netelogotextfiles\\\\modatcam.csv\"]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
1765
1140
1868
1173
buffer?
buffer?
1
1
-1000

MONITOR
1815
665
1935
710
Camera sites
count patches with [int (pxcor / 15) = (pxcor / 15) and int (pycor / 15) = (pycor / 15) and identity != \"building\"]
17
1
11

SWITCH
1670
360
1760
393
grid?
grid?
1
1
-1000

SWITCH
1668
395
1758
428
nested?
nested?
1
1
-1000

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

apple
false
0
Polygon -16777216 true false 33 58 0 150 30 240 105 285 135 285 150 270 165 285 195 285 255 255 300 150 268 62 226 43 194 36 148 32 105 35
Polygon -7500403 true true 15 150 45 60 105 45 150 45 195 45 225 60 255 75 285 150 255 240 195 270 165 270 150 255 135 270 105 270 45 240
Line -16777216 false 106 55 151 62
Line -16777216 false 157 62 209 57
Polygon -6459832 true false 152 62 158 62 160 46 156 30 147 18 132 26 142 35 148 46
Polygon -16777216 false false 132 25 144 38 147 48 151 62 158 63 159 47 155 30 147 18

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

badger
true
3
Polygon -16777216 true false 90 60 90 270 150 225 210 270 210 60 150 120
Polygon -7500403 true false 90 120 90 225 120 255 135 270 150 270 165 270 180 255 210 225 210 120 195 90 180 60 165 30 150 15 150 15 135 30 120 60 105 90
Polygon -16777216 true false 120 105 180 105 195 90 165 30 135 30 105 90
Polygon -7500403 true false 90 165 105 165
Polygon -7500403 true false 105 225
Polygon -1 true false 150 15 120 45 105 75 105 105 135 45 150 45 165 45 195 105 195 75 180 45 150 15
Polygon -1 true false 135 45 150 120 165 45 150 30
Polygon -16777216 true false 150 45
Polygon -1 true false 135 45 150 90 150 120 135 105
Polygon -1 true false 165 105 150 120 150 90 165 45
Polygon -6459832 true true 105 135
Polygon -6459832 true true 150 15 135 30 165 30

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

camera
false
15
Polygon -16777216 true false 75 90 105 60 195 60 225 90 225 225 195 255 105 255 75 225
Polygon -1 true true 90 90 105 75 195 75 210 90 210 225 195 240 105 240 90 225
Circle -16777216 true false 105 135 90
Polygon -14835848 true false 90 60 105 60
Polygon -6459832 true false 75 75
Circle -13345367 true false 120 150 60
Polygon -1 true true 150 165 135 180 150 180 150 165
Circle -2674135 true false 135 90 30

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

flower budding
false
0
Polygon -7500403 true true 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Polygon -7500403 true true 189 233 219 188 249 173 279 188 234 218
Polygon -7500403 true true 180 255 150 210 105 210 75 240 135 240
Polygon -7500403 true true 180 150 180 120 165 97 135 84 128 121 147 148 165 165
Polygon -7500403 true true 170 155 131 163 175 167 196 136

grass
false
0
Polygon -7500403 true true 75 240 75 210 60 195 60 180 60 165 75 180 90 195 90 240 75 240 90 240
Polygon -7500403 true true 120 240 120 165 135 135 135 120 120 105 135 75 135 105 150 105 150 150 135 165 135 240
Polygon -7500403 true true 165 240 165 195 180 180 180 165 195 180 195 195 180 195 180 210 180 240
Polygon -7500403 true true 210 240 210 210 225 195 225 210 225 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

house bungalow
false
0
Rectangle -7500403 true true 210 75 225 255
Rectangle -7500403 true true 90 135 210 255
Rectangle -16777216 true false 165 195 195 255
Line -16777216 false 210 135 210 255
Rectangle -16777216 true false 105 202 135 240
Polygon -7500403 true true 225 150 75 150 150 75
Line -16777216 false 75 150 225 150
Line -16777216 false 195 120 225 150
Polygon -16777216 false false 165 195 150 195 180 165 210 195
Rectangle -16777216 true false 135 105 165 135

house colonial
false
0
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 45 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 60 195 105 240
Rectangle -16777216 true false 60 150 105 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Polygon -7500403 true true 30 135 285 135 240 90 75 90
Line -16777216 false 30 135 285 135
Line -16777216 false 255 105 285 135
Line -7500403 true 154 195 154 255
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 135 150 180 180

house efficiency
false
0
Rectangle -7500403 true true 180 90 195 195
Rectangle -7500403 true true 90 165 210 255
Rectangle -16777216 true false 165 195 195 255
Rectangle -16777216 true false 105 202 135 240
Polygon -7500403 true true 225 165 75 165 150 90
Line -16777216 false 75 165 225 165

house ranch
false
0
Rectangle -7500403 true true 270 120 285 255
Rectangle -7500403 true true 15 180 270 255
Polygon -7500403 true true 0 180 300 180 240 135 60 135 0 180
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 45 195 105 240
Rectangle -16777216 true false 195 195 255 240
Line -7500403 true 75 195 75 240
Line -7500403 true 225 195 225 240
Line -16777216 false 270 180 270 255
Line -16777216 false 0 180 300 180

house two story
false
0
Polygon -7500403 true true 2 180 227 180 152 150 32 150
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 75 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 90 150 135 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Rectangle -7500403 true true 15 180 75 255
Polygon -7500403 true true 60 135 285 135 240 90 105 90
Line -16777216 false 75 135 75 180
Rectangle -16777216 true false 30 195 93 240
Line -16777216 false 60 135 285 135
Line -16777216 false 255 105 285 135
Line -16777216 false 0 180 75 180
Line -7500403 true 60 195 60 240
Line -7500403 true 154 195 154 255

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

plant medium
false
0
Rectangle -7500403 true true 135 165 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 165 120 120 150 90 180 120 165 165

plant small
false
0
Rectangle -7500403 true true 135 240 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 240 120 195 150 165 180 195 165 240

ring
false
0
Circle -7500403 false true -1 -1 301
Circle -7500403 false true 15 15 270

setts
false
0
Polygon -6459832 true false 15 150 30 120 60 105 75 75 105 75 135 60 165 60 210 75 240 75 270 90 285 120 285 165 270 180 255 195 240 195 240 165 225 150 210 150 180 165 195 210 210 225 225 240 195 255 150 255 105 225 105 210 120 180 105 165 75 165 45 180 45 210 30 195 15 180 15 165
Polygon -16777216 true false 45 210 75 210 90 225 105 225 105 210 120 180 105 165 75 165 45 180
Polygon -16777216 true false 225 240 225 210 240 195 240 165 225 150 210 150 180 165 195 210

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

tile stones
false
0
Polygon -7500403 true true 0 240 45 195 75 180 90 165 90 135 45 120 0 135
Polygon -7500403 true true 300 240 285 210 270 180 270 150 300 135 300 225
Polygon -7500403 true true 225 300 240 270 270 255 285 255 300 285 300 300
Polygon -7500403 true true 0 285 30 300 0 300
Polygon -7500403 true true 225 0 210 15 210 30 255 60 285 45 300 30 300 0
Polygon -7500403 true true 0 30 30 0 0 0
Polygon -7500403 true true 15 30 75 0 180 0 195 30 225 60 210 90 135 60 45 60
Polygon -7500403 true true 0 105 30 105 75 120 105 105 90 75 45 75 0 60
Polygon -7500403 true true 300 60 240 75 255 105 285 120 300 105
Polygon -7500403 true true 120 75 120 105 105 135 105 165 165 150 240 150 255 135 240 105 210 105 180 90 150 75
Polygon -7500403 true true 75 300 135 285 195 300
Polygon -7500403 true true 30 285 75 285 120 270 150 270 150 210 90 195 60 210 15 255
Polygon -7500403 true true 180 285 240 255 255 225 255 195 240 165 195 165 150 165 135 195 165 210 165 255

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -7500403 true true 120 195 180 300
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
NetLogo 6.2.0
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
1
@#$#@#$#@
