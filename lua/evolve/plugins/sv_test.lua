local PLUGIN = {
	id = "test",
	title = "Test",
	description = "A plugin to test various things. Will be removed",
	dependencies = {"test2"}
}

function PLUGIN:init()
	print("Init")
end

function PLUGIN:onInstall()
	print("onInstall")
end

function PLUGIN:onUninstall()
	print("onUninstall")
end

function PLUGIN:onEnable()
	print("onEnable")
end

function PLUGIN:onDisable()
	print("onDisable")
end

evolve:registerPlugin(PLUGIN)
