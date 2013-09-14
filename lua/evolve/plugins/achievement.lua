local PLUGIN = {
	id = "achievement",
	title = "Achievement",
	description = "Fakes someone getting an achievement",
	author = "Xandaros",
	dependencies = {"consolecommands"}
}

function PLUGIN.Call(ply, cmd, args, secret, str)
	local perm = evolve:getPlayerPermission(ply:UniqueID(), "achievement")
	if perm == 1 then
		evolve:notify(ply, evolve.colors.red, evolve.constants.notallowed)
		return
	end
	local players, err
	if perm == 2 then
		players = {ply}
	elseif perm == 3 then
		players = evolve:findPlayersBelow(args[1], ply:UniqueID())
		err = evolve.constants.noplayers2
	elseif perm == 4 then
		players = evolve:findPlayersBelowOrEqual(args[1], ply:UniqueID())
		err = evolve.constants.noplayers
	elseif perm == 5 then
		players = evolve:findPlayers(args[1], ply:UniqueID())
		err = evolve.constants.noplayersnoimmunity
	end
	
	if players == nil or #players == 0 then
		evolve:notify(ply, evolve.colors.red, err)
		return
	end
	
	local ach = table.concat(args, " ", 2)
	if ach == nil or #ach == 0 then
		evolve:notify(ply, evolve.colors.red, "No achievement specified.")
		return
	end
	
	for k,v in pairs(players) do
		evolve:notify(team.GetColor(v:Team()), v:Nick(), color_white, " earned the achievement ", Color(255, 201, 0, 255), ach)
	end
end

function PLUGIN:onInstall()
	evolve:registerPermission("achievement", "Achievement", "Allows the player to fake someone getting an achievement", {"disabled", "self", "below", "same", "all"})
end

function PLUGIN:onUninstall()
	evolve:unregisterPermission("achievement")
end

function PLUGIN:onEnable()
	evolve:getPlugin("consolecommands"):registerCommand("ach", PLUGIN.Call)
end

function PLUGIN:onDisable()
	evolve:getPlugin("consolecommands"):unregisterCommand("ach")
end

evolve:registerPlugin(PLUGIN)
