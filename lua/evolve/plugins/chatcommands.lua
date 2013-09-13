local PLUGIN = {
	id = "chatcommands",
	title = "Chat commands",
	description = "Allows evolve console commands to be called via chat",
	author = "Xandaros",
	dependencies = {"consolecommands"}
}

function PLUGIN:onEnable()
	hook.Add("PlayerSay", "evolve_chatcommands", function(ply, msg)
		local firstChar = string.sub(msg, 1, 1)
		local command = "ev"
		local args = {}
		
		if firstChar == "@" then
			command = "evs"
		elseif firstChar ~= "!" then
			return
		end
		
		msg = string.sub(msg, 2)
		for arg in string.gmatch(msg, "%S+") do
			table.insert(args, arg)
		end
		
		evolve:getPlugin("consolecommands").command(ply, command, args, msg)
		return ""
	end)
end

function PLUGIN:onDisable()

end

evolve:registerPlugin(PLUGIN)