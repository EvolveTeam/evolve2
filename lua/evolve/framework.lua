evolve = {}
evolve.persistences = {}
evolve.persistence = nil
evolve.plugins = {}
evolve.playerData = {}

include("evolve/config.lua")
include("evolve/databaseConfig.lua")

local dbVersion = 4

local persistences = evolve.persistences
local plugins = evolve.plugins
local playerData = evolve.playerData

local persistence

-- Constants
evolve.colors = {}
evolve.constants = {}

evolve.colors.blue = Color( 98, 176, 255, 255 )
evolve.colors.red = Color( 255, 62, 62, 255 )
evolve.colors.white = color_white
evolve.constants.notallowed = "You are not allowed to do that."
evolve.constants.noplayers = "No matching players with an equal or lower immunity found."
evolve.constants.noplayers2 = "No matching players with a lower immunity found."
evolve.constants.noplayersnoimmunity = "No matching players found."


---------------- Setup Net Messages ----------------


util.AddNetworkString("evolve_notify")


---------------- API functions provided by evolve ----------------


function evolve:getPlugin(id)
	return plugins[id]
end

function evolve:getPlayer(uid)
	if not uid then return nil end
	local playerData = persistence:get("evolve_player", {["uid"] = uid})
	return playerData
end

function evolve:getRank(id)
	return persistence:get("evolve_rank", {["id"] = id})
end

function evolve:getPlayerRank(uid)
	local playerData = evolve:getPlayer(uid)
	return evolve:getRank(playerData["rank"])
end

function evolve:isPlayerAbove(ply1, ply2)
	local ply1rank = evolve:getPlayerRank(ply1)
	local ply2rank = evolve:getPlayerRank(ply2)
	
	return ply1rank["immunity"] > ply2rank["immunity"]
end

function evolve:isPlayerAboveOrEqual(ply1, ply2)
	local ply1rank = evolve:getPlayerRank(ply1)
	local ply2rank = evolve:getPlayerRank(ply2)
	
	return ply1rank["immunity"] >= ply2rank["immunity"]
end

local function findPlayers(name, def, mode)
	local function namesMatch(nick, name)
		if name == "*" then return true end
		return string.find(nick:lower(), name:lower())
	end
	
	-- mode: 0 - any player, 1 - below, 2 - below or equal,
	local ret = {}
	local perfect
	for _,player in pairs(player.GetAll()) do
		perfect = false
		if player:Nick():lower() == name:lower() then
			perfect = true
		end
		if not namesMatch(player:Nick(), name) then
			goto continue_2
		end
		if mode == 0 then
			if perfect then return {player} end
			table.insert(ret, player)
		elseif mode == 1 then
			if evolve:isPlayerAbove(def, player:UniqueID()) then
				if perfect then return {player} end
				table.insert(ret, player)
			end
		elseif mode == 2 then
			if evolve:isPlayerAboveOrEqual(def, player:UniqueID()) then
				if perfect then return {player} end
				table.insert(ret, player)
			end
		end
		::continue_2::
	end
	return ret
end

function evolve:findPlayers(name, def)
	return findPlayers(name, def, 0)
end

function evolve:findPlayersBelow(name, def)
	return findPlayers(name, def, 1)
end

function evolve:findPlayersBelowOrEqual(name, def)
	return findPlayers(name, def, 2)
end

-- Name: Identifier of perm
-- Title: Displayed name of perm
-- Description: Description of perm
-- Options: Table containing the options in the format {title, title, ...}
function evolve:registerPermission(name, title, description, options)
	persistence:begin()
	
	persistence:insert("evolve_permission", {["name"] = name, ["title"] = title, ["description"] = description})
	for k,v in pairs(options) do
		persistence:insert("evolve_permission_option", {["id"] = k, ["perm"] = name, ["title"] = v})
	end
	
	persistence:commit()
end

function evolve:unregisterPermission(name)
	persistence:delete("evolve_permission_option", {["perm"] = name})
	persistence:delete("evolve_permission", {["name"] = name})
	persistence:delete("evolve_rank_permission", {["perm"] = name})
end

-- Rank: ID of rank
-- Perm: Name of permission
-- Option: The value of the permission [0 is inherited]
function evolve:givePermission(rank, perm, option)
	persistence:insert("evolve_rank_permission", {["rank"] = rank, ["perm"] = perm, ["option"] = option})
end

-- Defaults to 1, make sure 1 disables your functionality associated with this perm
function evolve:getRankPermission(rank, perm)
	local ret = persistence:get("evolve_rank_permission", {["rank"] = rank, ["perm"] = perm})
	if ret == nil or tonumber(ret["option"]) == 0 then
		local super = evolve:getRank(rank)["super"]
		
		if super ~= "NULL" then
			return evolve:getRankPermission(super, perm)
		else
			return 1
		end
	end
	return tonumber(ret["option"])
end

function evolve:getPlayerPermission(uid, perm)
	local rank = tonumber(evolve:getPlayer(uid)["rank"])
	return evolve:getRankPermission(rank, perm)
end

function evolve:enablePlugin(plugin)
	local plug = evolve:getPlugin(plugin)
	if plug == nil then return false end
	if plug.status ~= 1 then return false end
	
	-- Check for dependencies
	if plug.dependencies ~= nil then
		for _, pl in pairs(plug.dependencies) do
			local found = false
			for k,v in pairs(plugins) do
				if k == pl then
					if v.status ~= 2 then return false end
					found = true
					break
				end
			end
			if found == false then return false end
		end
	end
	
	if plug.onEnable then plug:onEnable() end
	plug.status = 2
	persistence:update("evolve_plugins", {["status"] = 2}, {["name"] = plugin})
	return true
end

-- TODO: Disallow disabling if there are dependencies
function evolve:disablePlugin(plugin)
	local plug = evolve:getPlugin(plugin)
	if plug == nil then return false end
	if plug.status ~= 2 then return false end
	
	-- Check for plugins depending on the one to be disabled
	for id,pl in pairs(plugins) do
		if pl.dependencies ~= nil and pl.status == 2 then
			for k,v in pairs(pl.dependencies) do
				if v == plugin then return false end
			end
		end
	end
	
	if plug.onDisable then plug:onDisable() end
	plug.status = 1
	persistence:update("evolve_plugins", {["status"] = 1}, {["name"] = plugin})
	return true
end

function evolve:installPlugin(plugin)
	local plug = evolve:getPlugin(plugin)
	if plug == nil then return false end

	if plug.status ~= 0 and plug.status ~= 3 then return false end
	
	if plug.onInstall then plug:onInstall() end
	plug.status = 1
	persistence:update("evolve_plugins", {["status"] = 1}, {["name"] = plugin})
	return true
end

function evolve:uninstallPlugin(plugin)
	local plug = evolve:getPlugin(plugin)
	if plug == nil then return false end

	if plug.status == 0 then return false end
	if plug.status == 2 then evolve:disablePlugin(plugin) end -- Disable first
	
	if plug.onUninstall then plug:onUninstall() end
	plug.status = 0
	persistence:update("evolve_plugins", {["status"] = 0}, {["name"] = plugin})
	return true
end

function evolve:notify(...)
	local args = {...}
	local ply
	if type(args[1]) == "Player" or istable(args[1]) then
		if args[1].r == nil then -- Make sure we don't send anything to a color instead of a player
			ply = args[1]
			table.remove(args, 1)
		end
	end
	
	net.Start("evolve_notify")
		net.WriteUInt(#args, 8)
		for k,v in pairs(args) do
			if isstring(v) then
				net.WriteBit(false)
				net.WriteString(v)
			elseif istable(v) then
				net.WriteBit(true)
				net.WriteUInt(v.r, 8)
				net.WriteUInt(v.g, 8)
				net.WriteUInt(v.b, 8)
				net.WriteUInt(v.a, 8)
			else
				error("Unsupported parameter")
			end
		end
	if ply == nil then
		net.Broadcast()
	else
		net.Send(ply)
	end
end


---------------- Load persistence frameworks and load the selected one ----------------


-- Every persistence plugin will call this to register itself
function evolve:registerPersistence(plugin)
	persistences[plugin.id] = plugin
end

-- Load all persistence plugins
local files, _ = file.Find("lua/evolve/persistence/*", "GAME")
for k,v in pairs(files) do
	include("evolve/persistence/" .. v)
end

-- Set the selected framework
evolve.persistence = persistences[evolve.config.DB.id]
if evolve.persistence == nil then
	-- TODO: This should probably display a dialog on the clients, as well
	error("Evolve: Could not load persistence framework")
end
persistence = evolve.persistence


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
			elseif ver == 2 then
				persistence:createTable("evolve_rank", {["id"] = "INT", ["title"] = "VARCHAR", ["super"] = "INT", ["usergroup"] = "VARCHAR", ["icon"] = "VARCHAR", ["color_r"] = "INT", ["color_g"] = "INT", ["color_b"] = "INT"}, "id")
				persistence:insert("evolve_rank", {["id"] = 0, ["title"] = "Guest", ["usergroup"] = "user", ["icon"] = "user", ["color_r"] = 127, ["color_g"] = 127, ["color_b"] = 127})
				persistence:insert("evolve_rank", {["id"] = 1, ["title"] = "Respected", ["super"] = 0, ["usergroup"] = "user", ["icon"] = "user_add", ["color_r"] = 0, ["color_g"] = 255, ["color_b"] = 0})
				persistence:insert("evolve_rank", {["id"] = 2, ["title"] = "Admin", ["super"] = 1, ["usergroup"] = "admin", ["icon"] = "shield", ["color_r"] = 255, ["color_g"] = 127, ["color_b"] = 0})
				persistence:insert("evolve_rank", {["id"] = 3, ["title"] = "Superadmin", ["super"] = 2, ["usergroup"] = "superadmin", ["icon"] = "shield_add", ["color_r"] = 255, ["color_g"] = 0, ["color_b"] = 0})
				persistence:insert("evolve_rank", {["id"] = 4, ["title"] = "Owner", ["super"] = 3, ["usergroup"] = "superadmin", ["icon"] = "key", ["color_r"] = 0, ["color_g"] = 127, ["color_b"] = 255})
				
				persistence:createTable("evolve_player", {["uid"] = "BIGINT", ["lastNick"] = "VARCHAR", ["lastJoined"] = "BIGINT", ["playtime"] = "INT", ["rank"] = "INT"}, "uid")
			elseif ver == 3 then
				persistence:createTable("evolve_permission", {["name"] = "VARCHAR", ["title"] = "VARCHAR", ["description"] = "VARCHAR"}, "name")
				persistence:createTable("evolve_permission_option", {["id"] = "INT", ["perm"] = "VARCHAR", ["title"] = "VARCHAR"}, {"id", "perm"})
				persistence:createTable("evolve_rank_permission", {["rank"] = "INT", ["perm"] = "VARCHAR", ["option"] = "INT"}, {"rank", "perm"})
			elseif ver == 4 then
				persistence:addColumn("evolve_rank", "immunity", "INT")
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
	
	persistence:createTable("evolve_rank", {["id"] = "INT", ["title"] = "VARCHAR", ["super"] = "INT", ["usergroup"] = "VARCHAR", ["icon"] = "VARCHAR", ["color_r"] = "INT", ["color_g"] = "INT", ["color_b"] = "INT", ["immunity"] = "INT"}, "id")
	persistence:insert("evolve_rank", {["id"] = 0, ["title"] = "Guest", ["usergroup"] = "user", ["icon"] = "user", ["color_r"] = 127, ["color_g"] = 127, ["color_b"] = 127, ["immunity"] = 0})
	persistence:insert("evolve_rank", {["id"] = 1, ["title"] = "Respected", ["super"] = 0, ["usergroup"] = "user", ["icon"] = "user_add", ["color_r"] = 0, ["color_g"] = 255, ["color_b"] = 0, ["immunity"] = 1})
	persistence:insert("evolve_rank", {["id"] = 2, ["title"] = "Admin", ["super"] = 1, ["usergroup"] = "admin", ["icon"] = "shield", ["color_r"] = 255, ["color_g"] = 127, ["color_b"] = 0, ["immunity"] = 2})
	persistence:insert("evolve_rank", {["id"] = 3, ["title"] = "Superadmin", ["super"] = 2, ["usergroup"] = "superadmin", ["icon"] = "shield_add", ["color_r"] = 255, ["color_g"] = 0, ["color_b"] = 0, ["immunity"] = 3})
	persistence:insert("evolve_rank", {["id"] = 4, ["title"] = "Owner", ["super"] = 3, ["usergroup"] = "superadmin", ["icon"] = "key", ["color_r"] = 0, ["color_g"] = 127, ["color_b"] = 255, ["immunity"] = 4})
	
	persistence:createTable("evolve_player", {["uid"] = "BIGINT", ["lastNick"] = "VARCHAR", ["lastJoined"] = "BIGINT", ["playtime"] = "BIGINT", ["rank"] = "INT"}, "uid")
	
	persistence:createTable("evolve_permission", {["name"] = "VARCHAR", ["title"] = "VARCHAR", ["description"] = "VARCHAR"}, "name")
	persistence:createTable("evolve_permission_option", {["id"] = "INT", ["perm"] = "VARCHAR", ["title"] = "VARCHAR"}, {"id", "perm"})
	persistence:createTable("evolve_rank_permission", {["rank"] = "INT", ["perm"] = "VARCHAR", ["option"] = "INT"}, {"rank", "perm"})
end


---------------- Index available plugins ----------------

-- About the same as persistence, see above

local prePlugins = {}
local prePluginsCount = 0

function evolve:registerPlugin(plugin)
	prePlugins[plugin.id] = plugin
	prePluginsCount = prePluginsCount + 1
end

local files,_ = file.Find("lua/evolve/plugins/*", "GAME")
for k,v in pairs(files) do
	include("evolve/plugins/" .. v)
end

-- Set installed/enabled status of plugins accordingly
for id,plugin in pairs(prePlugins) do
	local data = persistence:get("evolve_plugins", {["name"] = id})
	if data == nil then
		-- New plugin
		persistence:insert("evolve_plugins", {["name"] = id, ["status"] = 0})
		plugin.status = 0
	else
		plugin.status = tonumber(data["status"])
	end
	if plugin.init then plugin:init() end
end

-- Check for dependencies - This process is SLOW, can it be improved? (Only occurs on startup, but still)
while true do
	local before = prePluginsCount
	
	for id,plugin in pairs(prePlugins) do
		if plugin.dependencies == nil then
			plugins[plugin.id] = plugin
			prePlugins[plugin.id] = nil
			prePluginsCount = prePluginsCount - 1
		else
			for _,dep in pairs(plugin.dependencies) do
				if plugins[dep] == nil or plugins[dep].status ~= 2 then
					goto continue_1
				end
			end
			plugins[plugin.id] = plugin
			prePlugins[plugin.id] = nil
			prePluginsCount = prePluginsCount - 1
			::continue_1::
		end
	end

	if prePluginsCount == 0 or before == prePluginsCount then break end
end

-- Set unmet dependencies status of plugins accordingly
for id, plugin in pairs(prePlugins) do
	print("Unmet dependencies in plugin: " .. id)
	plugin.status = 3
	plugins[id] = plugin
	prePlugins[id] = nil
end

-- Clean up
files = nil
prePlugins = nil
prePluginsCount = nil


-- Execute onEnabled on enabled plugins
for id,plugin in pairs(plugins) do
	if plugin.status == 2 then
		if plugin.onEnable then plugin:onEnable() end
	end
end


---------------- Rank management ----------------
-- Register players upon connect

hook.Add("PlayerInitialSpawn", "evolve_framework", function(player)
	local uid = player:UniqueID()
	
	playerData[uid] = {}
	
	local time = os.time()
	local data = persistence:get("evolve_player", {["uid"] = uid})

	if data == nil then
		-- Player connected for the very first time

		persistence:insert("evolve_player", {["uid"] = uid, ["lastNick"] = player:Nick(), ["lastJoined"] = time, ["playtime"] = 0, ["rank"] = 0})
		playerData[uid] = {
			lastNick = "",
			lastJoined = 0,
			joined = time,
			playtime = 0,
			rank = 0
		}
	else
		playerData[uid] = {
			lastNick = data["lastNick"],
			lastJoined = data["lastJoined"],
			joined = time,
			playtime = data["playtime"],
			rank = data["rank"]
		}
	end

	if game.SinglePlayer() and evolve.config.alwaysOwner then -- Singleplayer and set to make owner - make him owner
		persistence:update("evolve_player", {["rank"] = 4}, {["uid"] = 1})
	end
end)

function evolve.savePlayer(player)
	local uid = player:UniqueID()
	local data = playerData[uid]

	persistence:update("evolve_player", {["lastNick"] = player:Nick(), ["lastJoined"] = data.joined, ["playtime"] = data.playtime + (os.time() - data.joined)}, {["uid"] = uid})
end

hook.Add("PlayerDisconnected", "evolve_framework", evolve.savePlayer)
hook.Add("Shutdown", "evolve_framework", function()
	for k,v in pairs(player.GetAll()) do
		evolve.savePlayer(v)	-- TODO: This might cause players to be saved twice, needs further testing
					-- Does this even work?
	end
end)

print("Evolve initialized successfully")
