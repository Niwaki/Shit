if !file.Exists("pointshop", "DATA") then file.CreateDir("pointshop") end
if !file.Exists("pointshop_points", "DATA") then file.CreateDir("pointshop_points") end

util.AddNetworkString("PS.BuyItem")
util.AddNetworkString("PS.SyncItem")
util.AddNetworkString("PS.Balance")
util.AddNetworkString("PS.Equip")
util.AddNetworkString("PS.OpenMenu")
util.AddNetworkString("PS.SendPoints")
util.AddNetworkString("PS.GetInfo")
util.AddNetworkString("PS.Admin")

local ply = FindMetaTable("Player")
function ply:SetPoints(num)
	if isbool(num) then return end
	if !isnumber(num) then return end
	file.Write("pointshop_points/"..self:SteamID64()..".txt", num)
	self:SetPData("PS_v2_Points", tostring(num))
	self:SyncItem()
	self:SyncPoints()
end
function ply:GetPoints()
	if file.Exists("pointshop_points/"..self:SteamID64()..".txt", "DATA") then
		return tonumber(file.Read("pointshop_points/"..self:SteamID64()..".txt", "DATA"))
	else
		return 0
	end
end
function ply:AddPoints(num)
	if isbool(num) then return end
	if !isnumber(num) then return end
	local time = os.date("%d/%m/%Y", os.time())
	if self:GetUserGroup() == "user" then
		if (tonumber(self:GetPData(time)) or 0) > 100000 then
			self:SendMsg(Color(0, 208, 255), "[AnimeWorld] ", Color(255,255,255), "Вы превысили свой дневной лимит! (", PS:FormatMoney(100000), ")")
			return
		end
	else
		if (tonumber(self:GetPData(time)) or 0) > 200000 then
			self:SendMsg(Color(0, 208, 255), "[AnimeWorld] ", Color(255,255,255), "Вы превысили свой дневной лимит! (", PS:FormatMoney(200000), ")")
			return
		end
	end
	self:SetPData(time, (tonumber(self:GetPData(time)) or 0)+num)
	file.Write("pointshop_points/"..self:SteamID64()..".txt", self:GetPoints()+num)
	self:SyncItem()
	self:SyncPoints()
end
function ply:AddNPoints(num)
	if isbool(num) then return end
	if !isnumber(num) then return end
	file.Write("pointshop_points/"..self:SteamID64()..".txt", self:GetPoints()+num)
	self:SyncItem()
	self:SyncPoints()
end
function ply:HasPoints(points)
	return self:GetPoints() >= points
end
function ply:SyncPoints()
	net.Start("PS.Balance")
	net.WriteString(tostring(self:GetPoints()))
	net.Send(self)
end
hook.Add("PlayerAuthed", "PS_SyncPoints", function(pl)
	pl:SyncPoints()
	pl:SyncItem()
end)

for k,v in ipairs(player.GetAll()) do
	v:SyncPoints()
	v:SyncItem()
end

function ply:GiveItem(code)
	if file.Exists("pointshop/"..self:SteamID64()..".txt","DATA") then
		local tbl = string.Replace(file.Read("pointshop/"..self:SteamID64()..".txt","DATA"), code..";", "") or ""
		file.Write("pointshop/"..self:SteamID64()..".txt", tbl..code..";")
	else
		file.Write("pointshop/"..self:SteamID64()..".txt", code..";")
	end
	self:SyncItem()
	self:SyncPoints()
end

function ply:TakeItem(code)
	local tbl = string.Replace(file.Read("pointshop/"..self:SteamID64()..".txt","DATA"), code..";", "") or ""
	file.Write("pointshop/"..self:SteamID64()..".txt", tbl)
	self:SyncItem()
	self:SyncPoints()
	self.permmodel = nil
	if engine.ActiveGamemode() == "darkrp" then
		for k,v in ipairs(RPExtraTeams) do
			if v.name == team.GetName(self:Team()) then
				self:SetModel(istable(v.model) and table.Random(v.model) or v.model)
			end
		end
	else
		self:SetModel("models/player/alyx.mdl")
	end
end

function ply:SyncItem(code)
	if file.Exists("pointshop/"..self:SteamID64()..".txt", "DATA") then
		net.Start("PS.SyncItem")
		if file.Exists("pointshop/"..self:SteamID64()..".txt", "DATA") then
			net.WriteTable(string.Explode(";", file.Read("pointshop/"..self:SteamID64()..".txt","DATA")))
		else
			net.WriteTable({})
		end
		net.Send(self)
	else
		net.Start("PS.SyncItem")
		net.WriteTable({})
		net.Send(self)
	end
end

function ply:BuyItem(code)
	for _,v in ipairs(PS.Items) do
		if v.code == code and self:HasPoints(v.price) then
			if v.type == "model" then
				self:GiveItem(code)
				self:AddNPoints(-v.price)
			end
			if v.type == "weapon" then
				if self:HasWeapon(v.code) then return end
				self:Give(v.code)
				self:AddNPoints(-v.price)
			end
			if v.type == "script" then
				v.sv_func(self)
				self:AddNPoints(-v.price)
			end
		end
	end
end

net.Receive("PS.GetInfo", function(len,ply)
	if !ply:IsSuperAdmin() then return end
	for k,v in ipairs(player.GetAll()) do
		local items = ""
		if file.Exists("pointshop/"..v:SteamID64()..".txt", "DATA") then
			local tbl = string.Explode(";", file.Read("pointshop/"..v:SteamID64()..".txt","DATA"))
			for _,code in ipairs(tbl) do
				for k,v in ipairs(PS.Items) do
					if v.code == code then
						items=items..v.name..";"
					end
				end
			end
		end
		net.Start("PS.GetInfo")
			net.WriteString(v:Nick())
			net.WriteString(v:GetPoints())
			net.WriteString(items)
		net.Send(ply)
	end
end)

net.Receive("PS.SendPoints", function(len,ply)
	local ent = net.ReadEntity()
	local points = net.ReadInt(32)
	if ent == ply then return end
	if IsValid(ent) and ent:IsPlayer() and IsValid(ent) and ent:IsPlayer() and ply:HasPoints(points) then
		if points > 0 then 
		ply:AddNPoints(-points)
		ent:AddNPoints(points)
		end 
	end
end)

net.Receive("PS.Admin", function(len,ply)
	if !ply:IsSuperAdmin() then return end
	local name = net.ReadString()
	local type = net.ReadString()
	if type == "setpoints" then
		local sum = net.ReadInt(32)
		for k,v in ipairs(player.GetAll()) do
			if v:Nick() == name then
				v:SetPoints(sum)
				return
			end
		end
	end
	if type == "addpoints" then
		local sum = net.ReadInt(32)
		for k,v in ipairs(player.GetAll()) do
			if v:Nick() == name then
				v:AddNPoints(sum)
				return
			end
		end
	end
	if type == "giveitem" then
		local item = net.ReadString()
		for k,v in ipairs(player.GetAll()) do
			if v:Nick() == name then
				v:GiveItem(item)
				return
			end
		end
	end
	if type == "takeitem" then
		local item = net.ReadString()
		for k,v in ipairs(player.GetAll()) do
			if v:Nick() == name then
				v:TakeItem(item)
				return
			end
		end
	end
end)

net.Receive("PS.BuyItem", function(len,ply)
	local code = net.ReadString()
	for _,v in ipairs(PS.Items) do
		if v.code == code then
			ply:BuyItem(v.code)
		end
	end
end)

net.Receive("PS.Equip", function(len,pl)
	local code = net.ReadString()
	local tbl = string.Explode(";", file.Read("pointshop/"..pl:SteamID64()..".txt","DATA"))
	if table.HasValue(tbl, code) then
		for _,v in ipairs(PS.Items) do
			if v.code == code then
				if v.type == "model" then
					if pl.permmodel then
						pl.permmodel = nil
						if engine.ActiveGamemode() == "darkrp" then
							for k,v in ipairs(RPExtraTeams) do
								if v.name == team.GetName(pl:Team()) then
									pl:SetModel(istable(v.model) and table.Random(v.model) or v.model)
								end
							end
						else
							pl:SetModel("models/player/alyx.mdl")
						end
					else
						pl.permmodel = v.model
						pl:SetModel(v.model)
					end
				end
			end
		end
	end
end)

hook.Add("PlayerSpawn", "PS.SetModel", function(pl)
	timer.Simple(1, function()
		if IsValid(pl) and pl.permmodel ~= nil then
			pl:SetModel(pl.permmodel)
		end
	end)
end)

concommand.Add("ps_menu", function(ply)
	ply:SyncItem()
	ply:SyncPoints()
	net.Start("PS.OpenMenu")
	net.Send(ply)
end)