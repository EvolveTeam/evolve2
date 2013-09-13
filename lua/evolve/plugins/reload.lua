local PLUGIN = {
	id = "reload",
	title = "Reload",
	description = "Provides a command to reload the map",
	author = "Xandaros",
	dependencies = {"consolecommands"}
}

function PLUGIN.Call(ply, cmd, args, secret, str)
	if not secret then
		evolve:notify(evolve.colors.blue, ply:Nick(), evolve.colors.white, " has reloaded the map.")
	end
	for k,v in pairs(player.GetAll()) do
		evolve.savePlayer(v)
	end
	RunConsoleCommand("changelevel", game.GetMap())
end

function PLUGIN:onEnable()
	evolve:getPlugin("consolecommands"):registerCommand("reload", PLUGIN.Call)
end

evolve:registerPlugin(PLUGIN)
