PLUGIN = {
	id = "plugin",
	title = "Plugin Management",
	description = "Allows to install, uninstall, enable and disable plugins",
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
	if args[1] == "install" then
		evolve:installPlugin(plugin)
	elseif args[1] == "uninstall" then
		evolve:uninstallPlugin(plugin)
	elseif args[1] == "enable" then
		evolve:enablePlugin(plugin)
	elseif args[1] == "disable" then
		evolve:disablePlugin(plugin)
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