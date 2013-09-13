local PLUGIN = {
	id = "reload",
	title = "Reload",
	description = "Provides a command to reload the map",
	author = "Xandaros",
	dependencies = {"consolecommands"}
}

function PLUGIN.Call(ply, cmd, args, secret, str)
	if evolve:getPlayerPermission(ply:UniqueID(), "reload") ~= 2 then
		evolve:notify(ply, evolve.colors.red, evolve.constants.notallowed)
		return
	end
	if not secret then
		evolve:notify(evolve.colors.blue, ply:Nick(), evolve.colors.white, " has reloaded the map.")
	end
	for k,v in pairs(player.GetAll()) do
		evolve.savePlayer(v)
	end
	timer.Simple(1, function() RunConsoleCommand("changelevel", game.GetMap()) end)
end

function PLUGIN:onInstall()
	evolve:registerPermission("reload", "Reload", "Allows the player to reload the map", {"disabled", "enabled"})
end

function PLUGIN:onUninstall()
	evolve:unregisterPermission("reload")
end

function PLUGIN:onEnable()
	evolve:getPlugin("consolecommands"):registerCommand("reload", PLUGIN.Call)
end

function PLUGIN:onDisable()
	evolve:getPlugin("consolecommands"):unregisterCommand("reload")
end

evolve:registerPlugin(PLUGIN)
