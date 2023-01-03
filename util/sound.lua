local function playSound(speaker, sound)
    if not speaker then
        return
    end

    speaker.playSound(sound.name, sound.volume, sound.pitch)
end

return {
    playSound = playSound
}