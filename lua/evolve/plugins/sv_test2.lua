local PLUGIN = {
	id = "test2",
	title = "Test2",
	description = "A plugin to test various things. Will be removed"
}

function PLUGIN:init()
	print("Init2")
end

function PLUGIN:onInstall()
	print("onInstall2")
end

function PLUGIN:onUninstall()
	print("onUninstall2")
end

function PLUGIN:onEnable()
	print("onEnable2")
end

function PLUGIN:onDisable()
	print("onDisable2")
end

evolve:registerPlugin(PLUGIN)
