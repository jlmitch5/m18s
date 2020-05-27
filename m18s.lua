--- m185 ~ 2-voice sequencer inspired by RYK M-185

engine.name = 'PolySub'

local MusicUtil = require "musicutil"
local polysub = include 'lib/polysub'
local screen_framerate = 15
local sGMs = { "off", "single", "all", "every2", "every3", "every4", "random", "long" }
local modes = { "forward", "pingPong", "fixedLength", "random" }

local scale_names = {}
local notes = {}

-- configuration and sequencer state

v1 = {
  nextStep = 1,
  initialStep = 1,
  nextStage = 1,
  initialStage = 1,
  pingPongDir = 'forward',
  fixedLengthStageCount = 1,
  nextNote = 0,
  nextNumStages = 0,
  nextGateMode = "off",
  mode = "forward",
  fixedLength = 18,
  oct = 5,
  seq = {
    { 1, 1, sGMs[1] },
    { 2, 2, sGMs[2] },
    { 3, 3, sGMs[3] },
    { 4, 4, sGMs[4] },
    { 5, 5, sGMs[5] },
    { 6, 6, sGMs[6] },
    { 7, 7, sGMs[7] },
    { 8, 8, sGMs[8] }
  }
}

v2 = {
  nextStep = 1,
  initialStep = 1,
  nextStage = 1,
  initialStage = 1,
  pingPongDir = 'forward',
  fixedLengthStageCount = 1,
  nextNote = 0,
  nextNumStages = 0,
  nextGateMode = "off",
  mode = "forward",
  fixedLength = 16,
  oct = 4,
  seq = { 
    { 1, 1, sGMs[1] },
    { 2, 2, sGMs[2] },
    { 3, 3, sGMs[3] },
    { 4, 4, sGMs[4] },
    { 5, 5, sGMs[5] },
    { 6, 6, sGMs[6] },
    { 7, 7, sGMs[7] },
    { 8, 8, sGMs[8] }
  }
}

-- handle note generation

local noteCounter = 1
local heldNotes1 = {}
local heldNotes2 = {}

function getNote(scale, seqNote)
  return scale[(seqNote - 1) % #scale + 1]
end

function pulseNote(voice, freq)
  local gateLength = voice == 1 and params:get('v1_gateLength') or params:get('v2_gateLength')
  local currentNote = noteCounter
  noteCounter = noteCounter + 1
  engine.start(currentNote, freq)
  clock.sleep(gateLength)
  engine.stop(currentNote)
end

function playNote (voice, noteNum, gateType, cur)
  local cur_oct = voice == 1 and params:get('v1_octave') or params:get('v2_octave')
  local freq = MusicUtil.note_num_to_freq(getNote(notes, noteNum) + cur_oct * 12)
  if gateType == 'pulse' then
      clock.run(pulseNote, voice, freq)
  elseif gateType == 'hold' then
    local currentNote = noteCounter
    noteCounter = noteCounter + 1
    table.insert(voice == 1 and heldNotes1 or heldNotes2, currentNote)
    engine.start(currentNote, freq)
  end
end

function stopHeldNote (voice, all)
  local noteToStop = table.remove(voice == 1 and heldNotes1 or heldNotes2)
  if noteToStop ~= nil then
    engine.stop(noteToStop)
    if all then
      stopHeldNote(voice, true)
    end
  end
end

-- sequencer logic

function shouldGateFire (stage, numStages, gateMode, noRand)
    if stage <= numStages then
        if gateMode == "all" or (gateMode == "single" and stage == 1) or
          (gateMode == "every2" and (stage + 1) % 2 == 0) or
          (gateMode == "every3" and (stage + 2) % 3 == 0) or
          (gateMode == "every4" and (stage + 3) % 4 == 0) or
          (not noRand and gateMode == "random" and math.random(0, 1) == 0) or
          (gateMode == "long" and numStages == 1) then
            return true
        end
    end
    return false
end

function advance(voice)
    local cur
    local cur_mode
    local cur_fixedLength
    if voice == 1 then
      cur = v1
      cur_mode = modes[params:get('v1_mode')]
      cur_fixedLength = params:get('v1_fixedLength')
    elseif voice == 2 then
      cur = v2
      cur_mode = modes[params:get('v2_mode')]
      cur_fixedLength = params:get('v2_fixedLength')
    end

    if (cur.nextStep > #cur.seq) then
        cur.nextStep = 1
        cur.nextStage1 = 1
    end

    cur.nextNote = cur.seq[cur.nextStep][1]
    cur.nextNumStages = cur.seq[cur.nextStep][2]
    cur.nextGateMode = cur.seq[cur.nextStep][3]

    if shouldGateFire(cur.nextStage, cur.nextNumStages, cur.nextGateMode) then
        playNote(voice, cur.nextNote, 'pulse', cur)
    elseif cur.nextGateMode == "long" and cur.nextStage == 1 then
        playNote(voice, cur.nextNote, 'hold', cur)
    elseif cur.nextGateMode == "long" and cur.nextStage >= cur.nextNumStages then
        stopHeldNote(voice)
    end

    if cur_mode == "fixedLength" and cur.fixedLengthStageCount >= cur_fixedLength then
        cur.nextStep = cur.initialStep
        cur.nextStage = cur.initialStage
        cur.fixedLengthStageCount = 1
        stopHeldNote(voice)
    else
        if cur_mode == "fixedLength" then
            cur.fixedLengthStageCount = cur.fixedLengthStageCount + 1
        end
        if cur.nextStage >= cur.nextNumStages or cur.nextStep > #cur.seq then
            if cur_mode == "forward" or cur_mode == "fixedLength" then
                cur.nextStep = cur.nextStep % #cur.seq + 1
            elseif cur_mode == "pingPong" then
                if cur.nextStep == #cur.seq then
                    cur.pingPongDir = 'reverse'
                elseif cur.nextStep == 1 then
                    cur.pingPongDir = 'forward'
                end

                if cur.pingPongDir == 'forward' then
                    cur.nextStep = cur.nextStep % #cur.seq + 1
                else
                    cur.nextStep = cur.nextStep % #cur.seq - 1
                    if cur.nextStep == -1 then
                        cur.nextStep = #cur.seq - 1
                    end
                end           
            elseif cur_mode == "random" then
                cur.nextStep = math.random(1, #cur.seq)
            end
            cur.nextStage = 1
        else
            cur.nextStage = cur.nextStage + 1
        end
    end
end

function build_scale()
  notes = MusicUtil.generate_scale_of_length(params:get("root_note"), params:get("scale_mode"), 8)
  local num_to_add = 8 - #notes
  for i = 1, num_to_add do
    table.insert(notes, notes[8 - num_to_add])
  end
  tab.print(notes)
end

function init()
      for i = 1, #MusicUtil.SCALES do
        table.insert(scale_names, string.lower(MusicUtil.SCALES[i].name))
      end
  
      params:add_separator('scale params')
      params:add{type = "option", id = "scale_mode", name = "scale",
      options = scale_names, default = 31,
      action = function() build_scale() end}
      params:add{
        type = "number",
        id = "root_note",
        name = "root note",
        min = 0,
        max = 11,
        default = 0,
        formatter = function(param) return MusicUtil.note_num_to_name(param:get()) end,
        action = function() build_scale() end
      }
      params:add_separator('sequence one params')
      params:add_option("v1_mode", "mode", modes, 1)
      params:add_taper("v1_gateLength", "pulse length", 0.05, 10, .3, 0, "s")
      params:add_number ("v1_fixedLength", "fixed length", 1, 128, 16)
      params:add_number ("v1_octave", "octave", 0, 8, 5)
      
      -- params:add_taper("reverb_mix", "*"..sep.."mix", 0, 100, 50, 0, "%")
      
      -- v1 = {
      --   mode = 'forward' ('forward', 'pingPong', 'fixedLength', 'random')
      --   fixedLength = 18, (1..128)
      --   gateLength = .3, (.05..10)
      --   oct = 5 (0..8)
      --   scale = { 0, 3, 5, 7, 10 } (?)
      -- }
      params:add_separator('sequence two params')
      params:add_option("v2_mode", "mode", modes, 1)
      params:add_taper("v2_gateLength", "pulse length", 0.05, 10, .2, 0, "s")
      params:add_number ("v2_fixedLength", "fixed length", 1, 128, 16)
      params:add_number ("v2_octave", "octave", 0, 8, 4)
      
      -- v2 = {
      --   mode = "forward",
      --   fixedLength = 16,
      --   gateLength = .2,
      --   oct = 4,
      --   scale = { 0, 3, 5, 7, 10 },
      -- }
      params:add_separator('sound params')
      polysub:params()
      
      -- params:default()
      params:read("data/m18s-01.pset")
      params:bang()

      function pulse()
          while true do
              clock.sync(1/4)
              advance(2)
              advance(1)
              -- random notes should change in time with the rhythm,
              -- not screen refresh rate
              generateRandomDisplayData()
          end
      end

      clock.run(pulse)
      
      screen_refresh_metro = metro.init()
      screen_refresh_metro.event = function(stage)
        redraw()
      end
      screen_refresh_metro:start(1 / screen_framerate)
end

-- k2/k3 = reset step

function reset(_v)
  local cur = _v == 1 and v1 or v2
  local currentStep = _v == 1 and cursor.v1 or cursor.v2
  local totalSteps = 0
  local nextStep = 1
  local nextStage = 1
  local stepIdx = 1
  for i = 1, #cur.seq do
    totalSteps = totalSteps + cur.seq[i][2]
    for j = 1, cur.seq[i][2] do
      if stepIdx == currentStep then
        nextStep = i
        nextStage = j
      end
      stepIdx = stepIdx + 1
    end
  end
  stopHeldNote(_v, true)
  cur.initialStep = nextStep
  cur.nextStep = nextStep
  cur.initialStage = nextStage
  cur.nextStage = nextStage
  if _v == 1 then
    cursor.v1 = util.clamp(cursor.v1, 1, totalSteps)
  else
    cursor.v2 = util.clamp(cursor.v2, 1, totalSteps)
  end
end

-- k2+k3 = randomize function

function randomizeStep(_v, _s)
    cur = _v == 1 and v1 or v2
    cur.seq[_s] = {
      math.random(1, 8),
      math.random(1, 8),
      sGMs[math.random(1, #sGMs)]
    }
end

function randomizeAllSteps(_v)
    cur = _v == 1 and v1 or v2
    for i = 1, #cur.seq do randomizeStep(_v, i) end
end

local keyPressed2 = false
local keyPressed3 = false
function key(n,z)
  function randomize()
    stopHeldNote(1, true)
    stopHeldNote(2, true)
    randomizeAllSteps(1)
    randomizeAllSteps(2)
  end
  if n == 2 or n == 3 then
    if z == 1 and (keyPressed2 or keyPressed3) then
      randomize()
      reset(1)
      reset(2)
    end
    if z == 1 then
      if n == 2 then
        keyPressed2 = true
      elseif n == 3 then
        keyPressed3 = true
      end
    elseif z == 0 then
      if n == 2 then
        keyPressed2 = false
      elseif n == 3 then
        keyPressed3 = false
      end
    end
  end
  if n == 2 and z == 1 then
    reset(1)
  elseif n == 3 and z == 1 then
    reset(2)
  end
end

-- screen drawing stuff

function generateRandomDisplayData()
  for i = 1, #randomDisplayData do
    randomDisplayData[i] = math.random(0,1)
  end
end

local tabDelta = 0
local highlighted = -1
local docstring = 0
cursor = {
  v1 = 1,
  v2 = 1
}

randomDisplayData = {}
for i = 1, 128 do
  table.insert(randomDisplayData, math.random(0,1))
end
local yOff = 9
local fontFace = 21

function shouldRandomPulseDisplay (stage, numStages, gateMode, _v)
    if stage <= numStages and
      gateMode == "random" and
      randomDisplayData[
        -- generate a deterministic, but somewhat random index so that the display
        -- looks random
        ((stage + numStages) * (_v * _v * stage * numStages * stage) + _v) % #randomDisplayData + 1
      ] == 0 then
        return true
    else
      return false
    end
end

function enc(n, delta)
  -- e1 = change tab, e2 = change highlighted note
  -- if n==1 then
  --   tabDelta = util.clamp(tabDelta + delta, 0, 5)
  -- elseif n==2 then
  --   print(delta)
  --   highlighted = util.clamp(highlighted + delta, 1, 2)
  -- end
  if n == 1 then
    docstring = (docstring + 1) % 4
  end
  if n == 2 or n == 3 then
    cur = n == 2 and v1 or v2
    local totalSteps = 0
    for i = 1, #cur.seq do
      totalSteps = totalSteps + cur.seq[i][2]
    end
    if n == 2 then
      cursor.v1 = util.clamp(cursor.v1 + delta, 1, totalSteps)
    elseif n == 3 then
      cursor.v2 = util.clamp(cursor.v2 + delta, 1, totalSteps)
    end
  end
end

function drawTabs()
  -- screen.level(8)
  -- screen.rect(0 + 21 * tabDelta,0,23,11)
  -- screen.fill()
  -- screen.stroke()
  
  -- screen.font_face(fontFace)
  -- screen.font_size(9)
  -- screen.level(0)
  -- for i = 0, 6 do
  --   screen.move(1 + i * 21,9)
  --   screen.text(math.random(0,9) .. math.random(0,9) .. math.random(0,9) .. math.random(0,9))
  --   screen.stroke() 
  -- end

  screen.level(8)
  screen.rect(0,0,28,11)
  screen.fill()
  screen.stroke()
  screen.font_face(fontFace)
  screen.font_size(9)
  screen.level(0)
  screen.move(1, 9)
  screen.text('RESET')
  screen.stroke()
  screen.level(8)
  screen.move(126, 9)
  if docstring == 0 then
    screen.text_right('TURN E1 FOR DOCS')
  elseif docstring == 1 then
    screen.text_right('E2/E3 MOVES CURSOR')
  -- elseif docstring == 2 then
  --   screen.text_right('PASS ENDS FOR MUTE')
  elseif docstring == 2 then
    -- screen.text_right('K2/K3 RESETS/MUTES')
    screen.text_right('K2/K3 RESETS NOTE')
  elseif docstring == 3 then
    screen.text_right('K2+K3 RANDOMIZES')
  end
  
  
  screen.stroke() 
end

function drawHighlights()
  screen.level(12)
  screen.rect(0, (highlighted - 1) * 22 + 3 + yOff,128,19)
  screen.fill()
  screen.stroke()
end

function drawSpacerLines()
  screen.move(0,11)
  screen.level(15)
  screen.line(128,11)
  screen.stroke()

  screen.move(0,33)
  screen.level(15)
  screen.line(128,33)
  screen.stroke()
  
  screen.move(0,55)
  screen.level(15)
  screen.line(128,55)
  screen.stroke()
end

function drawPulseNotes(_v, invert)
  local cur = _v == 1 and v1 or v2
  local voiceYOffset = (_v - 1) * 22 + yOff
  local seqRef = {}
  local stepRef = {}
  for i = 1, #cur.seq do
    for j = 1, cur.seq[i][2] do
      if invert then
        table.insert(seqRef,
          cur.nextStep == i and cur.nextStage == j and 0 or
          shouldGateFire(j, cur.seq[i][2], cur.seq[i][3], true) and 7 or
          shouldRandomPulseDisplay(j, cur.seq[i][2], cur.seq[i][3], _v) and 7 or
          12
        )
        table.insert(stepRef,
          j == 1 and cur.nextStep == i and 0 or
          j == 1 and 7 or
          12
        )
      else
        table.insert(seqRef,
          cur.nextStep == i and cur.nextStage == j and 15 or
          shouldGateFire(j, cur.seq[i][2], cur.seq[i][3], true) and 3 or
          shouldRandomPulseDisplay(j, cur.seq[i][2], cur.seq[i][3], _v) and 3 or
          0
        )
        table.insert(stepRef,
          j == 1 and cur.nextStep == i and 15 or
          j == 1 and 5 or
          0
        )
      end
    end
  end 
  for i = 1, #seqRef do
    i = i - 1
    local row = math.floor(i/32)
    screen.level(seqRef[i + 1])
    screen.circle(4*i + 2 - row * 128,10 + row * 10 + voiceYOffset, 1)
    screen.stroke()
    screen.level(stepRef[i + 1])
    screen.circle(4*i + 2 - row * 128,5 + row * 10 + voiceYOffset, 1)
    screen.stroke()
  end
end

function drawLongNotes(_v, invert)
  local cur = _v == 1 and v1 or v2
  local voiceYOffset = (_v - 1) * 22 + yOff
  local longRef = {}
  local numSteps = 0
  for i = 1, #cur.seq do
    if cur.seq[i][3] == 'long' and cur.seq[i][2] > 1 then
      local firstStep = numSteps
      local lastStep = numSteps + cur.seq[i][2] - 1
      if firstStep <= 31 and lastStep >= 32 then
        table.insert(longRef, { firstStep , 31 })
        table.insert(longRef, { 32 , lastStep })
      else
        table.insert(longRef, { firstStep, lastStep })
      end
    end
    numSteps = numSteps + cur.seq[i][2]
  end
  -- print('hey')
  -- tab.print(longRef)
  for i = 1, #longRef do
    local onLevel = invert and 7 or 3
    local row = math.floor(longRef[i][1]/32)
    screen.move(4*longRef[i][1] + 1 - row * 128, 10 + voiceYOffset + row * 10)
    screen.level(onLevel)
    screen.line_width(2)
    screen.line(4*longRef[i][2] + 3 - row * 128, 10 + voiceYOffset + row * 10)
    screen.stroke()
  end
  screen.line_width(1)
end

function drawCurrentStage(_v, invert)
  local cur = _v == 1 and v1 or v2
  local voiceYOffset = (_v - 1) * 22 + yOff
  local seqRef = {}
  local stepRef = {}
  for i = 1, #cur.seq do
    for j = 1, cur.seq[i][2] do
      if invert then
        table.insert(seqRef,
          cur.nextStep == i and cur.nextStage == j and 0 or -1
        )
        table.insert(stepRef,
          j == 1 and cur.nextStep == i and 0 or -1
        )
      else
        table.insert(seqRef,
          cur.nextStep == i and cur.nextStage == j and 15 or -1
        )
        table.insert(stepRef,
          j == 1 and cur.nextStep == i and 15 or -1
        )
      end
    end
  end 
  for i = 1, #seqRef do
    i = i - 1
    local row = math.floor(i/32)
    if seqRef[i + 1] ~= -1 then
      screen.level(seqRef[i + 1])
      screen.circle(4*i + 2 - row * 128,10 + row * 10 + voiceYOffset, 1)
      screen.stroke()
      screen.level(stepRef[i + 1])
      screen.circle(4*i + 2 - row * 128,5 + row * 10 + voiceYOffset, 1)
      screen.stroke()
    end
  end
end

function drawFooter()
  screen.font_face(fontFace)
  screen.font_size(9)
  screen.level(8)
  screen.move(-2,64)
  screen.text('1 ' .. v1.nextStep .. ':' .. v1.nextStage .. ':' .. string.format("%03d", v1.nextNote))
  screen.move(127,64)
  screen.text_right('2 ' .. v2.nextStep .. ':' .. v2.nextStage .. ':' .. string.format("%03d", v2.nextNote))
  screen.stroke() 
    if highlighted == 1 then
    screen.move(-2,64)
    screen.level(15)
    screen.text('1')
  elseif 
    highlighted == 2 then
    screen.move(83,64)
    screen.level(12)
    screen.text('2')
  end
end

function drawResetCursors()
  screen.level(12)
  local row1 = math.floor((cursor.v1 - 1) / 32)
  screen.rect(1 + 4 * (cursor.v1 - 1) % 128, 18 + row1 * 10, 3, 3)
  screen.stroke()
  local row2 = math.floor((cursor.v2 - 1) / 32)
  screen.rect(1 + 4 * (cursor.v2 - 1) % 128, 40 + row2 * 10, 3, 3)
  screen.stroke()
end

function redraw()
  screen.aa(0)
  screen.clear()
  drawTabs()
  drawHighlights()
  drawSpacerLines()
  drawPulseNotes(1, highlighted == 1 and true or false)
  drawLongNotes(1, highlighted == 1 and true or false)
  drawCurrentStage(1, highlighted == 1 and true or false)
  drawPulseNotes(2, highlighted == 2 and true or false)
  drawLongNotes(2, highlighted == 2 and true or false)
  drawCurrentStage(2, highlighted == 1 and true or false)
  drawFooter()
  drawResetCursors()
  screen.update()
end
