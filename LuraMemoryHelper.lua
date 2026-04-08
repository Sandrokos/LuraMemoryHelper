local _, Lura = ...

Lura.ENCOUNTER_ID = 3183

Lura.DEFAULTS = {
    RunesDisplay = true,
    EnableSounds = false,
    locked = true,
    DisplayPoint = "CENTER",
    DisplayX = 300,
    DisplayY = 0,
}

Lura.state = {
    inEncounter = false,
    phase = 1,
    phaseSwapTime = 0,
    difficultyID = 0,
}

function Lura:Print(msg)
    print("|cff00ff00[LuraMemoryHelper]|r " .. tostring(msg))
end

-- Match NSRT "Create Rune Macros" (general macros, not secure buttons). LMH_ prefix avoids clashing with NSRT_LURA_RUNE_*.
function Lura:CreateRuneMacros()
    if InCombatLockdown() then
        self:Print("Cannot create macros while in combat.")
        return
    end
    local iconIDs = { "134635", "340528", "351033", "7242384", "236903" }
    for i = 1, 5 do
        local macroName = "LMH_LURA_RUNE_" .. i
        if not GetMacroInfo(macroName) then
            CreateMacro(macroName, iconIDs[i], "/raid " .. iconIDs[i])
        end
    end
    self:Print("General macros LMH_LURA_RUNE_1–5 created (skipped if names already exist). Drag them to your action bars.")
end