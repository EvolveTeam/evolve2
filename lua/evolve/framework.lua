evolve = {}
evolve.persistences = {}
evolve.persistence = nil
evolve.plugins = {}

include("evolve/config.lua")
include("evolve/databaseConfig.lua")

local dbVersion = 1

local persistences = evolve.persistences
local plugins = evolve.plugins


---------------- Load persistence frameworks and load the selected one ----------------


-- Every persistence plugin will call this to register itself
function evolve:registerPersistence(plugin)
	persistences[plugin.ID] = plugin
end

-- Load all persistence plugins
local files, _ = file.Find("lua/evolve/persistence/*", "GAME")
for k,v in pairs(files) do
	include("evolve/persistence/" .. v)
end

-- Set the selected framework
evolve.persistence = persistences[evolve.config.DB.ID]
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
		persistence:begin()
		local switchft = function(ver) -- Since there is neither switch nor computed goto...
			--if-elseifs to compare with ver
			if ver == 1 then
				persistence:createTable("evolve_plugins", {["name"] = "VARCHAR", ["status"] = "TINYINT"}, "name")
			end
			
			if ver < dbVersion then
				switchft(ver+1)
			end
			return
		end
		switchft(cur_ver + 1)
		persistence:update("evolve_versions", {["version"] = dbVersion}, {["name"] = "framework"})
		persistence:commit()
	end
else
	-- Database does not exist, create it
	print("Evolve: Creating new database")
	persistence:createTable("evolve_versions", {["name"] = "VARCHAR", ["version"] = "INT"}, "name") 
	persistence:insert("evolve_versions", {["name"] = "framework", ["version"] = dbVersion})
	persistence:createTable("evolve_plugins", {["name"] = "VARCHAR", ["status"] = "TINYINT"}, "name")
end


---------------- Index available plugins ----------------

-- About the same as persistence, see above

function evolve:registerPlugin(plugin)
	plugins[plugin.ID] = plugin
end

local files,_ = file.Find("lua/evolve/plugins/*", "GAME")
for k,v in pairs(files) do
	include("evolve/plugins/" .. v)
end

-- Set installed/enabled status of plugins accordingly
for id,plugin in pairs(plugins) do
	local data = persistence:get("evolve_plugins", {["name"] = id})
	if data == nil then
		-- New plugin
		persistence:insert("evolve_plugins", {["name"] = id, ["status"] = 0})
		plugin.status = 0
	else
		plugin.status = tonumber(data["status"])
	end
	plugin:init()
end

-- Execute onEnabled on enabled plugins
for id,plugin in pairs(plugins) do
	if plugin.status == 2 then
		plugin:onEnable()
	end
end


---------------- Rank management ----------------


---------------- API functions provided by evolve ----------------


print("Evolve initialized successfully")
