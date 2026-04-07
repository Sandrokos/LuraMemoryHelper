Lura.Sounds = {}

function Lura.Sounds:PlayCount(index)

    local sounds = {
        "Interface\\AddOns\\LuraMemory\\sounds\\1.ogg",
        "Interface\\AddOns\\LuraMemory\\sounds\\2.ogg",
        "Interface\\AddOns\\LuraMemory\\sounds\\3.ogg",
        "Interface\\AddOns\\LuraMemory\\sounds\\4.ogg",
        "Interface\\AddOns\\LuraMemory\\sounds\\5.ogg",
    }

    PlaySoundFile(sounds[index], "Master")
end