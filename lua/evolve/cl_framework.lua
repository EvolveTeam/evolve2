evolve = {}

net.Receive("evolve_notify", function(length)
	local args = {}
	local argc = net.ReadUInt(8)
	
	for i = 1, argc do
		if net.ReadBit() == 1 then
			table.insert(args, Color(net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8)))
		else
			table.insert(args, net.ReadString())
		end
	end
	chat.AddText(unpack(args))
end)
