local PLUGIN = {
	id = "plugin",
	title = "Plugin Management",
	description = "Allows to install, uninstall, enable and disable plugins",
	author = "Xandaros",
	dependencies = {"consolecommands"}
}

function PLUGIN.Call(ply, cmd, args, secret, str)
	local function printUsage()
		evolve:notify(ply, evolve.colors.red, "Usage:", evolve.colors.white, " plugin <install/uninstall/enable/disable> <plugin>")
	end

	if evolve:getPlayerPermission(ply:UniqueID(), "plugin") ~= 2 then
		evolve:notify(ply, evolve.colors.red, evolve.constants.notallowed)
		return
	end
	if #args < 2 then
		printUsage()
		return
	end
	local plugin = args[2]
	if evolve:getPlugin(plugin) == nil then
		evolve:notify(ply, evolve.colors.red, "Could not find plugin: ", plugin)
		return
	end
	local action
	local ret
	if args[1] == "install" then
		ret = evolve:installPlugin(plugin)
		action = "installed"
	elseif args[1] == "uninstall" then
		ret = evolve:uninstallPlugin(plugin)
		action = "uninstalled"
	elseif args[1] == "enable" then
		ret = evolve:enablePlugin(plugin)
		action = "enabled"
	elseif args[1] == "disable" then
		ret = evolve:disablePlugin(plugin)
		action = "disabled"
	else
		printUsage()
		return
	end
	
	if not ret then
		evolve:notify(ply, evolve.colors.red, "Plugin could not be " .. action .. ".")
		return
	end
	
	if not secret then
		evolve:notify(evolve.colors.blue, ply:Nick(), evolve.colors.white, " has ", action, " plugin ", evolve.colors.red, plugin)
	end
end

function PLUGIN:onInstall()
	evolve:registerPermission("plugin", "Plugin Management", "Allows the player to (un)install and en-/disable plugins", {"disabled", "enabled"})
end

function PLUGIN:onUninstall()
	evolve:unregisterPermission("plugin")
end

function PLUGIN:onEnable()
	evolve:getPlugin("consolecommands"):registerCommand("plugin", PLUGIN.Call)
end

function PLUGIN:onDisable()
	evolve:getPlugin("consolecommands"):unregisterCommand("plugin")
end

evolve:registerPlugin(PLUGIN)