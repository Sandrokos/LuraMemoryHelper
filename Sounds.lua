local _, Lura = ...

Lura.Sounds = {}

function Lura.Sounds:PlayCount(index)

    local sounds = {
        "Interface\\AddOns\\LuraMemoryHelper\\sounds\\1.ogg",
        "Interface\\AddOns\\LuraMemoryHelper\\sounds\\2.ogg",
        "Interface\\AddOns\\LuraMemoryHelper\\sounds\\3.ogg",
        "Interface\\AddOns\\LuraMemoryHelper\\sounds\\4.ogg",
        "Interface\\AddOns\\LuraMemoryHelper\\sounds\\5.ogg",
    }

    PlaySoundFile(sounds[index], "Master")
end