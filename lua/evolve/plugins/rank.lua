local PLUGIN = {
	id = "rank",
	title = "Rank changing",
	description = "Supplies a command to change the rank of other players",
	dependencies = {"consolecommands"}
}

function PLUGIN.Call(ply, cmd, args, secret, str)
	local perm = evolve:getPlayerPermission(ply:UniqueID(), "rank")
	if perm == 1 then
		evolve:notify(ply, evolve.colors.red, evolve.constants.notallowed)
		return
	end
	
	if #args ~= 2 then
		evolve:notify(ply, evolve.colors.red, "Usage: rank <player> <rank>")
		return
	end
	
	local players, err
	if perm == 2 then
		players = evolve:findPlayersBelow(args[1], ply:UniqueID())
		err = evolve.constants.noplayers2
	elseif perm == 3 then
		players = evolve:findPlayersBelowOrEqual(args[1], ply:UniqueID())
		err = evolve.constants.noplayers
	end
	
	if players == nil or #players == 0 then
		evolve:notify(ply, evolve.colors.red, err)
		return
	elseif #players > 1 then
		evolve:notify(ply, evolve.colors.red, "More than one player found.")
		return
	end
	
	local ranks = evolve:findRanks(args[2])
	if #ranks < 1 then
		evolve:notify(ply, evolve.colors.red, "Rank " .. args[2] .. " not found.")
		return
	elseif #ranks > 1 then
		evolve:notify(ply, evolve.colors.red, "More than one rank found.")
		return
	end
	
	evolve:setPlayerRank(players[1]:UniqueID(), ranks[1]["id"])
	
	if not secret then
		evolve:notify(evolve.colors.blue, ply:Nick(), evolve.colors.white, " has set the rank of ", evolve.colors.red, players[1]:Nick(), evolve.colors.white, " to ", ranks[1]["title"])
	end
end

function PLUGIN:onInstall()
	evolve:registerPermission("rank", "Rank changing", "Allows the player to change the rank of other people", {"disabled", "below", "equal"})
end

function PLUGIN:onDisable()
	evolve:unregisterPermission("rank")
end

function PLUGIN:onEnable()
	evolve:getPlugin("consolecommands"):registerCommand("rank", PLUGIN.Call)
end

function PLUGIN:onDisable()
	evolve:getPlugin("consolecommands"):unregisterCommand("rank")
end

evolve:registerPlugin(PLUGIN)
