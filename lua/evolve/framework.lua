evolve = {}
evolve.persistences = {}
evolve.selectedPersistence = nil

include("evolve/config.lua")
include("evolve/databaseConfig.lua")


---------------- Load persistence frameworks and load the selected one ----------------

-- Every persistence plugin will call this to register itself
function evolve:registerPersistence(plugin)
	evolve.persistences[plugin.ID] = plugin
end

-- Load all persistence plugins
local files, _ = file.Find("lua/evolve/persistence/*", "GAME")
for k,v in pairs(files) do
	include("evolve/persistence/" .. v)
end

-- Set the selected framework
evolve.selectedPersistence = evolve.persistences[evolve.config.DB.ID]
if evolve.selectedPersistence == nil then
	--TODO: This should probably display a dialog on the clients, as well
	error("Evolve: Could not load persistence framework")
end
