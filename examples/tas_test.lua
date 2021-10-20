meta.name = "TAS test"
meta.version = "WIP"
meta.description = "Simple test for TASing a seeded run. Works from start to finish, although you might have to wait a frame or two at the start of boss levels because of cutscene skip weirdness."
meta.author = "Dregu"

local seed = 0

register_option_combo('mode', 'Mode', 'Record\0Playback\0\0')
register_option_bool('pause', 'Start levels paused (when recording)', true)
register_option_bool('pskip', 'Skip level transitions automatically', true)
-- this probably needs a way to save and load the prng state to work
--[[register_option_button('rslevel', 'Restart level', function()
    warp(state.world, state.level, state.theme)
end)]]
register_option_string('seed', 'Seed (empty=random)', '')
register_option_int('delay', "Send delay", 1, -2, 2)
register_option_button('zrestart', 'Instant restart', function()
    if options.seed ~= '' then
        seed = tonumber(options.seed, 16)
    else
        seed = math.random(0, 0xffffffff)
    end
    --[[state.world_start = 3
    state.theme_start = 4
    state.world_next = 3
    state.theme_next = 4
    state.seed = 0x123
    state.quest_flags = 1
    state.loading = 1]]

    set_seed(seed)
end)

local frames = {}
local stopped = true
local stolen = false
local cutcb = -1

set_callback(function()
    if options.mode == 1 and options.pause then -- record
        if state.pause == 0 then
            state.pause = 0x20
        else
            cutcb = set_callback(function() -- wait for a cutscene to end. still desyncs on olmec
                if state.pause == 0 then
                    clear_callback(cutcb)
                    state.pause = 0x20
                end
            end, ON.GUIFRAME)
        end
    elseif options.mode == 2 then -- playback
        steal_input(players[1].uid)
        stopped = false
        stolen = true
    end
end, ON.LEVEL)

set_callback(function()
    if #players < 1 then return end
    if frames[state.level_count] == nil then
        frames[state.level_count] = {}
    end
    if options.mode == 1 then -- record
        frames[state.level_count][state.time_level] = read_input(players[1].uid)
        message('Recording '..string.format('%04x', frames[state.level_count][state.time_level])..' '..#frames[state.level_count])
    elseif options.mode == 2 and not stopped then -- playback
        local input = frames[state.level_count][state.time_level+options.delay]
        if input and stolen then
            message('Sending '..string.format('%04x', input)..' '..state.time_level..'/'..#frames[state.level_count])
            send_input(players[1].uid, input)
        elseif stolen and state.time_level > #frames[state.level_count] then
            message('Stopped')
            return_input(players[1].uid)
            stolen = false
            stopped = true
        end
    end
end, ON.FRAME)

set_callback(function()
    if options.pskip then -- auto skip transitions
        warp(state.world_next, state.level_next, state.theme_next)
    end
end, ON.TRANSITION)

set_callback(function()
    if options.mode == 1 then
        frames = {}
    end
end, ON.RESET)

set_global_interval(function()
    if state.logic.olmec_cutscene ~= nil then
        state.logic.olmec_cutscene.timer = 809
    end
    if state.logic.tiamat_cutscene ~= nil then
        state.logic.tiamat_cutscene.timer = 379
    end
end, 1)
