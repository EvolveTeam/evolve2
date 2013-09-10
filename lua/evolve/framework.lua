evolve = {}
evolve.persistences = {}
evolve.persistence = nil

include("evolve/config.lua")
include("evolve/databaseConfig.lua")

local dbVersion = 0


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
evolve.persistence = evolve.persistences[evolve.config.DB.ID]
if evolve.persistence == nil then
	-- TODO: This should probably display a dialog on the clients, as well
	error("Evolve: Could not load persistence framework")
end
local persistence = evolve.persistence


---------------- Initialize/update database if it is not already ----------------


if persistence:exists("evolve_versions") then
	-- Database exists, check for necessary updates
	local cur_ver = tonumber(persistence:get("evolve_versions", {["name"]="framework"})["version"])
	if cur_ver > dbVersion then
		-- Downgrading evolve is a bad idea... abort
		error("Evolve: You are using an older evolve version than your database supports. Please update evolve.")
	elseif cur_ver < 0 then
		-- This should never happen unless someone messes with the DB
		error("Your database is corrupt.")
	end
	if cur_ver < dbVersion then
		print("Evolve: Updating database")
		local switchft = function(ver) -- Since there is neither switch nor computed goto...
			--if-elseifs to compare with ver
			
			if ver < dbVersion then
				switchft(ver+1)
			end
		end
		switchft(cur_ver)
	end
else
	-- Database does not exist, create it
	print("Evolve: Creating new database")
	persistence:createTable("evolve_versions", {["name"] = "VARCHAR", ["version"] = "INT"}, "name") 
	persistence:insert("evolve_versions", {["name"] = "framework", ["version"] = dbVersion})
end

print("Evolve initialized successfully")
