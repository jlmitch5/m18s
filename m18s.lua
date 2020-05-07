--- m185 ~ 2-voice sequencer inspired by RYK M-185
-- in 1: clock
-- out 1: cv 1
-- out 2: gate 1
-- out 3: cv 2
-- out 4: gate 2

function shouldGateFire (stage, numStages, gateMode)
    if stage <= numStages then
        if gateMode == "all" or (gateMode == "single" and stage == 1) or
          (gateMode == "every2" and (stage + 1) % 2 == 0) or
          (gateMode == "every3" and (stage + 2) % 3 == 0) or
          (gateMode == "every4" and (stage + 3) % 4 == 0) or
          (gateMode == "random" and math.random(0, 1) == 0) or
          (gateMode == "long" and numStages == 1) then
            return true
        end
    end
    return false
end

nextStep1 = 1
nextStage1 = 1
pingPongDir1 = 'forward'
fixedLengthStageCount1 = 1
function advance1()
    local nextNote1 = seq1[nextStep1][1]
    local nextNumStages1 = seq1[nextStep1][2]
    local nextGateMode1 = seq1[nextStep1][3]

    print("one: \t\tmode: " .. mode1 .. "\tstep: " ..nextStep1 .. "\tstage: " .. nextStage1 .. "\tfixedLengthCount: " .. fixedLengthStageCount1 .. "\tnote: " .. nextNote1 .. "\t\toct: " .. oct1 .. "\tstageCount: " .. nextNumStages1 .. "\tgateMode: " .. nextGateMode1)

    if nextStage1 == 1 then
        output[1].volts = nextNote1/12 + oct1
    end

    if shouldGateFire(nextStage1, nextNumStages1, nextGateMode1) then
        output[2](pulse(gateLength1, 8))
    elseif nextGateMode1 == "long" and nextStage1 == 1 then
        output[2].volts = 8
    elseif nextGateMode1 == "long" and nextStage1 >= nextNumStages1 then
        output[2].volts = 0
    end

    if mode1 == "fixedLength" and fixedLengthStageCount1 >= fixedLength1 then
        nextStep1 = 1
        nextStage1 = 1
        fixedLengthStageCount1 = 1
        output[2].volts = 0 -- just in case you need to clear out a long gate
    else
        if mode1 == "fixedLength" then
            fixedLengthStageCount1 = fixedLengthStageCount1 + 1
        end
        if nextStage1 >= nextNumStages1 or nextStep1 > #seq1 then
            if mode1 == "forward" or mode1 == "fixedLength" then
                nextStep1 = nextStep1 % #seq1 + 1
            elseif mode1 == "pingPong" then
                if nextStep1 == #seq1 then
                    pingPongDir1 = 'reverse'
                elseif nextStep1 == 1 then
                    pingPongDir1 = 'forward'
                end

                if pingPongDir1 == 'forward' then
                    nextStep1 = nextStep1 % #seq1 + 1
                else
                    nextStep1 = nextStep1 % #seq1 - 1
                    if nextStep1 == -1 then
                        nextStep1 = #seq1 - 1
                    end
                end           
            elseif mode1 == "random" then
                nextStep1 = math.random(1, #seq1)
            end
            nextStage1 = 1
        else
            nextStage1 = nextStage1 + 1
        end
    end
end

nextStep2 = 1
nextStage2 = 1
pingPongDir2 = 'forward'
fixedLengthStageCount2 = 1
function advance2()
    local nextNote2 = seq2[nextStep2][1]
    local nextNumStages2 = seq2[nextStep2][2]
    local nextGateMode2 = seq2[nextStep2][3]

    print("two: \t\tmode: " .. mode2 .. "\tstep: " ..nextStep2 .. "\tstage: " .. nextStage2 .. "\tfixedLengthCount: " .. fixedLengthStageCount2 .. "\tnote: " .. nextNote2 .. "\t\toct: " .. oct2 .. "\tstageCount: " .. nextNumStages2 .. "\tgateMode: " .. nextGateMode2)

    if nextStage2 == 1 then
        output[3].volts = nextNote2/12 + oct2
    end

    if shouldGateFire(nextStage2, nextNumStages2, nextGateMode2) then
        output[4](pulse(gateLength2, 8))
    elseif nextGateMode2 == "long" and nextStage2 == 1 then
        output[4].volts = 8
    elseif nextGateMode2 == "long" and nextStage2 >= nextNumStages2 then
        output[4].volts = 0
    end

    if mode2 == "fixedLength" and fixedLengthStageCount2 >= fixedLength2 then
        nextStep2 = 1
        nextStage2 = 1
        fixedLengthStageCount2 = 1
        output[4].volts = 0 -- just in case you need to clear out a long gate
    else
        if mode2 == "fixedLength" then
            fixedLengthStageCount2 = fixedLengthStageCount2 + 1
        end
        if nextStage2 >= nextNumStages2 or nextStep2 > #seq2 then
            if mode2 == "forward" or mode2 == "fixedLength" then
                nextStep2 = nextStep2 % #seq2 + 1
            elseif mode2 == "pingPong" then
                if nextStep2 == #seq2 then
                    pingPongDir2 = 'reverse'
                elseif nextStep2 == 1 then
                    pingPongDir2 = 'forward'
                end

                if pingPongDir2 == 'forward' then
                    nextStep2 = nextStep2 % #seq2 + 1
                else
                    nextStep2 = nextStep2 % #seq2 - 1
                    if nextStep2 == -1 then
                        nextStep2 = #seq2 - 1
                    end
                end           
            elseif mode2 == "random" then
                nextStep2 = math.random(1, #seq2)
            end
            nextStage2 = 1
        else
            nextStage2 = nextStage2 + 1
        end
    end
end

function advance()
    advance1()
    advance2()
    print("\n")
end

function init()
    input[1]{ mode = "change", direction = "rising" }
    input[1].change = advance
end

-- configuration and initialization below, this is what crow will load on boot of the script
-- scales can be any length

-- voice 1
gateLength1 = .01
mode1 = "forward"
oct1 = 0
fixedLength1 = 10
scale1 = { 0, 4, 5, 7, 9, 12, 16, 17 }
seq1 = {
    { scale1[1], 1, "off" },
    { scale1[2], 2, "single" },
    { scale1[3], 3, "all" },
    { scale1[4], 4, "every2" },
    { scale1[5], 5, "every3" },
    { scale1[6], 6, "every4" },
    { scale1[7], 7, "random" },
    { scale1[8], 8, "long" }
}

-- voice 2
gateLength2 = .01
mode2 = "forward"
oct2 = 2
fixedLength2 = 10
scale2 = { 0, 4, 5, 7, 9, 12, 16, 17 }
seq2 = {
    { scale2[1], 1, "off" },
    { scale2[2], 2, "single" },
    { scale2[3], 3, "all" },
    { scale2[4], 4, "every2" },
    { scale2[5], 5, "every3" },
    { scale2[6], 6, "every4" },
    { scale2[7], 7, "random" },
    { scale2[8], 8, "long" }
}

-- for mode/gate mode lookup use, so you don't have to remember numbers and can type the strings
ms = { "forward", "random", "pingPong", "fixedLength" }
sGMs = { "off", "single", "all", "every2", "every3", "every4", "random", "long" }

-- setters below, you can run these in druid or ^^derwydd to modify and modulate the sequence
function setMode(_v, _m) if _v == 1 then mode1 = _m else mode2 = _m end end
function setFixedLength(_v, _fL) if _v == 1 then fixedLength1 = _fL else fixedLength2 = _fL end end
function setStepNote(_v, _s, _n) if _v == 1 then seq1[_s][1] = _n else seq2[_s][1] = _n end end
function setStageCount(_v, _s, _sC) if _v == 1 then seq1[_s][2] = _sC else seq2[_s][2] = _sC end end
function setThisSequenceOntoOther(_v) if _v == 1 then seq2 = {table.unpack(seq1)} else seq1 = {table.unpack(seq2)} end end
function setStageGateMode(_v, _s, _sGM) if _v == 1 then seq1[_s][3] = _sGM else seq2[_s][3] = _sGM end end
function randomizeMode(_v) if _v == 1 then mode1 = ms[math.random(1, #ms)] else mode2 = ms[math.random(1, #ms)] end end
function randomizeStep(_v, _s)
    if _v == 1 then
        seq1[_s] = { scale1[math.random(1, #scale1)], math.random(1, 8), sGMs[math.random(1, #sGMs)] }
    else
        seq2[_s] = { scale2[math.random(1, #scale2)], math.random(1, 8), sGMs[math.random(1, #sGMs)] }
    end
end
function randomizeAllSteps(_v)
    local seqLength = _v == 1 and #seq1 or #seq2
    for i = 1, seqLength do randomizeStep(_v, i) end
end
