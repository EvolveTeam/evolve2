local PLUGIN = {
	id = "SQLite",
}

local function SQLiteType(MySQLType)
	local numeric = {["DECIMAL"]=true, ["FLOAT"]=true, ["DOUBLE"]=true}
	local integer = {["TINYINT"]=true, ["SMALLINT"]=true, ["MEDIUMINT"]=true, ["INT"]=true, ["BIGINT"]=true}
	local text = {["VARCHAR"]=true}
	
	if numeric[MySQLType] then
		return "NUMERIC"
	elseif integer[MySQLType] then
		return "INTEGER"
	elseif text[MySQLType] then
		return "TEXT"
	else
		error("Unknown type: " .. MySQLType)
	end
end

local function formatFilter(filter)
	local ret = ""
	for k,v in pairs(filter) do
		local value
		if isstring(v) then
			value = "\"" .. v .. "\""
		else
			value = tostring(v)
		end
		local operator = "="
		if istable(v) then
			value = v[1]
			if isstring(value) then
				value = "\"" .. value .. "\""
			else
				value = tostring(value)
			end
			if v[2] == 1 then
				operator = "="
			elseif v[2] == 2 then
				operator = "<"
			elseif v[2] == 3 then
				operator = "<="
			elseif v[2] == 4 then
				operator = ">"
			elseif v[2] == 5 then
				operator = ">="
			elseif v[2] == 6 then
				operator = "!="
			elseif v[2] == 7 then
				operator = " LIKE "
			else
				error("Unknown flag: " .. v[2])
			end
		end
		ret = ret .. " AND " .. k .. operator .. value
	end
	return ret:sub(6)
end

function PLUGIN:begin()
	sql.Begin()
end

function PLUGIN:commit()
	sql.Commit()
end

function PLUGIN:createTable(table, tableData, primaryKey)
	local tdata = ""
	local pKey = ""
	
	for k,v in pairs(tableData) do
		tdata = tdata  .. ", " .. tostring(k) .. " " .. SQLiteType(v)
	end
	tdata = tdata:sub(3)
	
	if istable(primaryKey) then
		for i=1, #primaryKey do
			if i > 1 then
				pKey = pKey .. ", "
			end
			
			pKey = pKey .. primaryKey[i]
		end
	else
		pKey = primaryKey
	end
	
	sql.Query("CREATE TABLE " .. table .. " (" .. tdata .. ", PRIMARY KEY(" .. pKey .. "))")
end

function PLUGIN:dropTable(table)
	sql.Query("DROP TABLE " .. table)
end

function PLUGIN:addColumn(table, name, type)
	sql.Query("ALTER TABLE " .. table .. " ADD " .. name .. " " .. SQLiteType(type))
end

function PLUGIN:renameTable(table, newName)
	sql.Query("ALTER TABLE " .. table .. " RENAME TO " .. newName)
end

function PLUGIN:dropColumns(table_, columns)
	sql.Query("BEGIN EXCLUSIVE TRANSACTION") -- no other read/write accesses while we are working. Also allows to abort in case of error
	
	local oldcolumns = {}
	local pKeys = {}
	local newcolumns = ""
	for k,v in pairs(sql.Query('pragma table_info(' .. table_ .. ')')) do
		--This is a hack to make types work with createTable
		local type = v.type
		if type == "INTEGER" then type = "INT"
		elseif type == "NUMERIC" then type = "DECIMAL"
		elseif type == "TEXT" then type = "VARCHAR"
		end
		----------------------------------------------------
		
		oldcolumns[v.name] = type
		if tonumber(v.pk) > 0 then
			table.insert(pKeys, v.name)
		end
	end
	
	for k,_ in pairs(oldcolumns) do
		for i=1, #columns do
			if k == columns[i] then
				oldcolumns[k] = nil
			end
		end
	end
	
	for k,_ in pairs(oldcolumns) do
		newcolumns = newcolumns .. ", " .. k
	end
	newcolumns = newcolumns:sub(3)
	
	
	PLUGIN:renameTable(table_, table_ .. "_old")
	PLUGIN:createTable(table_, oldcolumns, pKeys)
	sql.Query("INSERT INTO " .. table_ .. " SELECT " .. newcolumns .. " FROM " .. table_ .. "_old")
	PLUGIN:dropTable(table_ .. "_old")
	PLUGIN:renameTable(table_ .. "_old", table_)
	
	sql.Query("COMMIT")
end
function PLUGIN:modifyColumnType(table, column, type)
	--Not possible in SQLite unless hacked like dropColumn
	--But since datatypes aren't rigid - who cares?
end

function PLUGIN:insert(table, data)
	local columns = ""
	local values = ""
	
	for k,v in pairs(data) do
		columns = columns .. ", " .. k
		values = values .. ", "
		if isstring(v) then
			values = values .. "\"" .. v .. "\""
		else
			values = values .. tostring(v)
		end
	end
	columns = columns:sub(3)
	values = values:sub(3)
	
	local ret = sql.Query("INSERT INTO " .. table .. " (" .. columns .. ") VALUES (" .. values .. ")")
	if ret == false then
		error(sql.LastError())
	end
end

function PLUGIN:get(table, filter)
	local ret = sql.Query("SELECT * FROM " .. table .. " WHERE " .. formatFilter(filter))
	
	if ret == nil then
		-- Empty result
		return nil
	elseif ret == false then
		-- Error
		error(sql.LastError())
	end
	
	return ret[1]
end

function PLUGIN:delete(table, filter)
	sql.Query("DELETE FROM " .. table .. " WHERE " .. formatFilter(filter))
end

function PLUGIN:update(table, data, filter)
	local values = ""
	
	for k,v in pairs(data) do
		values = values .. ", " .. k .. "="
		if isstring(v) then
			values = values .. "\"" .. v .. "\""
		else
			values = values .. tostring(v)
		end
	end
	values = values:sub(3)
	
	local ret = sql.Query("UPDATE " .. table .. " SET " .. values .. " WHERE " .. formatFilter(filter))
	if ret == false then
		error(sql.LastError())
	end
end

function PLUGIN:exists(table)
	return sql.TableExists(table)
end

evolve:registerPersistence(PLUGIN)
