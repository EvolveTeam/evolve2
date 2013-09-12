local PLUGIN = {
	id = "reload",
	title = "Reload",
	description = "Provides a command to reload the map",
	dependencies = {"consolecommands"}
}

function PLUGIN.Call(ply, cmd, args, secret, str)
	for k,v in pairs(player.GetAll()) do
		evolve.savePlayer(v)
	end
	RunConsoleCommand("changelevel", game.GetMap())
end

function PLUGIN:onEnable()
	evolve:getPlugin("consolecommands"):registerCommand("reload", PLUGIN.Call)
end

evolve:registerPlugin(PLUGIN)
