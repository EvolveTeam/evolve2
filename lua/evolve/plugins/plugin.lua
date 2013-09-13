local PLUGIN = {
	id = "plugin",
	title = "Plugin Management",
	description = "Allows to install, uninstall, enable and disable plugins",
	author = "Xandaros",
	dependencies = {"consolecommands"}
}

function PLUGIN.Call(ply, cmd, args, secret, str)
	if #args < 2 then
		print("Usage: plugin <install/uninstall/enable/disable> <plugin>")
	end
	local plugin = args[2]
	if evolve:getPlugin(plugin) == nil then
		print("Could not find plugin: " .. plugin)
	end
	local action
	if args[1] == "install" then
		evolve:installPlugin(plugin)
		action = "installed"
	elseif args[1] == "uninstall" then
		evolve:uninstallPlugin(plugin)
		action = "uninstalled"
	elseif args[1] == "enable" then
		evolve:enablePlugin(plugin)
		action = "enabled"
	elseif args[1] == "disable" then
		evolve:disablePlugin(plugin)
		action = "disabled"
	end
	if not secret then
		evolve:notify(evolve.colors.blue, ply:Nick(), evolve.colors.white, " has ", action, " plugin ", evolve.colors.red, plugin)
	end
end

function PLUGIN:onInstall()
	evolve:registerPermission("plugin", "Plugin Management", "Allows the user to (un)install and en-/disable plugins", {"disabled", "enabled"})
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