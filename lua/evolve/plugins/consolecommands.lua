PLUGIN = {
	id = "consolecommands",
	title = "Console commands",
	description = "Provides API for console commands",
	commands = {}
}

function PLUGIN.command(player, cmd, args, str)
	local command = args[1]
	local secret = cmd == "evs"
	if PLUGIN.commands[command] ~= nil then
		table.remove(args, 1)
		PLUGIN.commands[command](player, command, args, secret, str)
	end
end

function PLUGIN:registerCommand(command, func)
	PLUGIN.commands[command] = func
end

function PLUGIN:onEnable()
	concommand.Add("ev", PLUGIN.command)
	concommand.Add("evs", PLUGIN.command)
end

function PLUGIN:onDisable()
	concommand.Remove("ev")
	concommand.Remove("evs")
end

evolve:registerPlugin(PLUGIN)
