-- in-progress version of a good sequence printer.  not 100% copy/pastable yet
function printSequences()
    print("voice 1:") for k,v in pairs(seq1) do str = "{ " for k2,v2 in pairs(v) do str = str .. v2 .. ", " end str = string.sub(str, 1, -3) .. "}," print(string.sub(str, 1, -1)) end
    print("voice 2:") for k,v in pairs(seq2) do str = "{ " for k2,v2 in pairs(v) do str = str .. v2 .. ", " end str = string.sub(str, 1, -3) .. " }," print(string.sub(str, 1, -1)) end
end
