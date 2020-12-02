--[[
	==============================================
    					UserGroup
	==============================================
]]
UserGroups = {
	["user"] = {
		name = "Игрок",
		rank = 0,
	},
	["moder"] = {
		name = "Модератор",
		rank = 1,
	},
	["admin"] = {
		name = "Администратор",
		rank = 5,
	},
	["curator"] = {
		name = "Куратор",
		rank = 8,
	},
	["developer"] = {
		name = "Разработчик",
		rank = 10,
	},
}

local PLAYER = FindMetaTable("Player")
function PLAYER:GetStaffRank()
	local group = UserGroups[self:GetPData("Admin.Group", "user")]
	return group and group.rank or 0
end

timer.Create("Admin.SetRank",5,0,function()
	for k,v in pairs(player.GetAll()) do
		v:SetNWInt("Admin.Rank", v:GetStaffRank())
	end
end)

hook.Add('PlayerNoClip', 'Admin.Noclip', function(ply)
	return ply:GetStaffRank() >= 2
end)

hook.Add('PhysgunPickup', 'Admin.Physgun', function(ply, ent)
	if ent:IsPlayer() and ply:GetStaffRank() > ent:GetStaffRank() then
		ent:SetMoveType(MOVETYPE_FLY)
		ent:Lock()
		return true
	end
	local validprop = ent.CPPIGetOwner and IsValid(ent:CPPIGetOwner())
	if validprop and ply:GetStaffRank() > ent:CPPIGetOwner():GetStaffRank() then
		return true
	end
end)

hook.Add('PhysgunDrop', 'Admin.Physgun', function(ply, ent)
	if IsValid(ent) and ent:IsPlayer() then
		ent:SetMoveType(MOVETYPE_WALK)
		ent:UnLock()
		if ply:KeyDown(IN_ATTACK2) then
			ent:Lock()
		end
		return true
	end
end)

--[[
	==============================================
    					Network
	==============================================
]]
util.AddNetworkString("Admin.Broadcast")

--[[
	==============================================
    					Message
	==============================================
]]

function Admin:Broadcast(...)
	local args = {...}
	net.Start("Admin.Broadcast")
	net.WriteTable(args)
	net.Broadcast()
end
function PLAYER:PlayerMsg(...)
	local args = {...}
	net.Start("Admin.Broadcast")
	net.WriteTable(args)
	net.Send(self)
end

function AdminLog(admin, text, ply, secret)
	if secret == true then
		for k,v in pairs(player.GetAll()) do
			if v:IsAdmin() then
				if IsValid(ply) then
					v:PlayerMsg(Color(50,200,50), " ⮞ ", admin:Nick(), Color(255,255,255), " "..text.." ", team.GetColor(ply:Team()), ply:Nick())
				else
					v:PlayerMsg(Color(50,200,50), " ⮞ ", admin:Nick(), Color(255,255,255), " "..text.." ")
				end
			end
		end
	else
		if IsValid(ply) then
			Admin:Broadcast(Color(50,200,50), " ⮞ Moderator", Color(255,255,255), " "..text.." ", team.GetColor(ply:Team()), ply:Nick())
		else
			Admin:Broadcast(Color(50,200,50), " ⮞ Moderator", Color(255,255,255), " "..text.." ")
		end
		for k,v in pairs(player.GetAll()) do
			if v:GetStaffRank() >= 1 then
				v:PlayerMsg(Color(50,150,50), "@ ", admin:Nick(), " ("..admin:SteamID()..")")
			end
		end
	end
end

--[[
	==============================================
    					SetStaff
	==============================================
]]
hook.Add("PlayerAuthed", "Admin.CheckAdmin", function(ply)
	if file.Exists("adminstaff/"..ply:AccountID()..".txt", "DATA") == true then
		local stafftable = util.JSONToTable(file.Read("adminstaff/"..ply:AccountID()..".txt", "DATA"))
		ply:SetPData("Admin.Group", stafftable.group)
	else
		ply:SetPData("Admin.Group", "user")
	end
end)

if file.Exists("adminstaff", "DATA") == false then
	file.CreateDir("adminstaff")
end

function SetStaff(ply, group)
	file.Delete("adminstaff/"..ply:AccountID()..".txt")
	local admintable = {
		name = ply:Nick(),
		steamid = ply:SteamID(),
		steamid64 = ply:SteamID64(),
		group = group,
	}
	file.Append("adminstaff/"..ply:AccountID()..".txt", util.TableToJSON(admintable))
	ply:SetPData("Admin.Group", group)
end

--[[
	==============================================
    					HardBan
	==============================================
]]
function ClearIP(ip)
    return string.find(ip, ":") and string.sub(ip, 1, string.find(ip, ":" ) - 1) or ip
end

if !file.Exists("hardbans", "DATA") then
    file.CreateDir("hardbans")
end
function HardBan(pl, reason)
    if reason == nil then reason = "читы" end
    local hardtable = {
        name = pl:Nick(),
        steamid = pl:SteamID(),
        steamid64 = pl:SteamID64(),
        reason = reason,
        ip = ClearIP(pl:IPAddress()),
    }
    file.Append("hardbans/"..pl:SteamID64()..".txt", util.TableToJSON(hardtable))
	Admin:Broadcast(Color(255,0,0),"Cheating ban: ", Color(255,200,100), pl:Nick(), Color(255,255,255), " был забанен ", Color(255,150,50), "навсегда", Color(255,255,255),".")
    pl:Kick("HardBan <3")
end

hook.Add("CheckPassword", "AHardBan", function(sid64, ip)
    local banfile = "hardbans/"
    local files, folders = file.Find(banfile.."*", "DATA")
    local newip = ClearIP(ip)
    for k,v in pairs(files) do
        local bans = util.JSONToTable(file.Read("hardbans/"..v, "DATA"))
        if bans.ip == newip then
            local hardtable = {
                reason = "Multiple accounts",
                ip = newip,
            }
            file.Append("hardbans/"..sid64..".txt", util.TableToJSON(hardtable))
            return false, "HardBan! <3"
        end
        if v == sid64..".txt" then
            return false, "HardBan! <3"
        end
    end
end)

--[[
	==============================================
    					Commands
	==============================================
]]

AdminCommands = {
	["Teleport"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					if not v:Alive() then
						v:Spawn()
					end
					v.ReturnPos = v:GetPos()
					timer.Simple(0.1, function()
						v:SetPos(admin:GetEyeTrace().HitPos + admin:GetEyeTrace().HitNormal * 25)
						v:EmitSound('ambient/voices/cough' .. math.random(1, 4) .. '.wav')
					end)
					AdminLog(admin, "телепортировал", v)
				end
			end
		end,
		cl_func = [[
			RunConsoleCommand("admin.Teleport", plysteamid)
		]],
		rank = 1,
	},
	["GoTo"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					if not v:Alive() then
						v:Spawn()
					end
					admin.ReturnPos = admin:GetPos()
					timer.Simple(0.1, function()
						admin:SetPos(v:GetPos() + Vector(0, 0, 25))
						v:EmitSound('ambient/voices/cough' .. math.random(1, 4) .. '.wav')
					end)
					AdminLog(admin, "телепортировался к", v)
				end
			end
		end,
		cl_func = [[
			RunConsoleCommand("admin.GoTo", plysteamid)
		]],
		rank = 1,
	},
	["Bring"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					if not v:Alive() then
						v:Spawn()
					end
					v.ReturnPos = v:GetPos()
					timer.Simple(0.1, function()
						v:SetPos(admin:GetPos() + Vector(0, 0, 25))
						v:EmitSound('ambient/voices/cough' .. math.random(1, 4) .. '.wav')
					end)
					AdminLog(admin, "телепортировал к себе", v)
				end
			end
		end,
		cl_func = [[
			RunConsoleCommand("admin.Bring", plysteamid)
		]],
		rank = 1,
	},
	["Return"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					if not v.ReturnPos then
						admin:ChatPrint('Некуда возвращать')
					end
					if not v:Alive() then
						v:Spawn()
					end
					timer.Simple(0.1, function()
						v:SetPos(v.ReturnPos + Vector(0, 0, 25))
						v:EmitSound('ambient/voices/cough' .. math.random(1, 4) .. '.wav')
					end)
					AdminLog(admin, "вернул обратно", v)
				end
			end
		end,
		cl_func = [[
			RunConsoleCommand("admin.Return", plysteamid)
		]],
		rank = 1,
	},
	["GotoPos"] = {
		func = function(admin, cmd, args)
			admin.ReturnPos = admin:GetPos()
			timer.Simple(0.1, function()
				admin:SetPos(Vector(args[1], args[2], args[3]))
				admin:EmitSound('ambient/voices/cough' .. math.random(1, 4) .. '.wav')
			end)
			AdminLog(admin, "телепортировался по координатам. ")
		end,
		cl_func = [[
			Derma_StringRequest("Введите координаты","","",
			function(text)
				print(text)
				RunConsoleCommand("admin.gotopos", text)
			end,function(text)end)
		]],
		noply = true,
		rank = 1,
	},
	["UnWanted"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					v:unWanted(nil)
					AdminLog(admin, "снял розыск с игрока", v)
				end
			end
		end,
		cl_func = [[
			RunConsoleCommand("admin.UnWanted", plysteamid)
		]],
		rank = 5,
	},
	["UnArrest"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					v:unArrest(nil)
					AdminLog(admin, "снял арест с игрока", v)
				end
			end
		end,
		cl_func = [[
			RunConsoleCommand("admin.UnArrest", plysteamid)
		]],
		rank = 5,
	},
	["ChatMute"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					v:SetPData("chatmute", os.time()+tonumber(args[2]))
					AdminLog(admin, 'заблокировал чат на '..TimeToStringShort(args[2])..' игроку', v)
				end
			end
		end,
		cl_func = [[
			Derma_StringRequest("Введите время","s,m,h,d,w,y","",
			function(text)
				RunConsoleCommand("admin.ChatMute", plysteamid, tonumber(StringToTime(text)))
			end,function(text)end)
		]],
		rank = 1,
	},
	["UnChatMute"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					v:SetPData("chatmute", os.time())
					AdminLog(admin, 'разблокировал чат игроку', v)
				end
			end
		end,
		cl_func = [[
			RunConsoleCommand("admin.UnChatMute", plysteamid)
		]],
		rank = 1,
	},
	["VoiceMute"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					v:SetPData("voicemute", os.time()+tonumber(args[2]))
					AdminLog(admin, 'заблокировал голосовой чат на '..TimeToStringShort(args[2])..' игроку', v)
				end
			end
		end,
		cl_func = [[
			Derma_StringRequest("Введите время","s,m,h,d,w,y","",
			function(text)
				RunConsoleCommand("admin.VoiceMute", plysteamid, tonumber(StringToTime(text)))
			end,function(text)end)
		]],
		rank = 1,
	},
	["HardBan"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					HardBan(v, args[2])
				end
			end
		end,
		cl_func = [[
			Derma_StringRequest("Введите причину","","",
			function(text)
				RunConsoleCommand("admin.HardBan", plysteamid, text)
			end,function(text)end)
		]],
		rank = 10,
	},
	["UnVoiceMute"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					v:SetPData("voicemute", os.time())
					AdminLog(admin, 'разблокировал голосовой чат игроку', v)
				end
			end
		end,
		cl_func = [[
			RunConsoleCommand("admin.UnVoiceMute", plysteamid)
		]],
		rank = 1,
	},
	["SetHealth"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					v:SetHealth(args[2])
					AdminLog(admin, 'установил '..args[2]..' здоровья игроку', v)
				end
			end
		end,
		cl_func = [[
			Derma_StringRequest("Введите кол-во","","",
			function(text)
				RunConsoleCommand("admin.SetHealth", plysteamid, text)
			end,function(text)end)
		]],
		rank = 5,
	},
	["SetArmor"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					v:SetArmor(args[2])
					AdminLog(admin, 'установил '..args[2]..' брони игроку', v)
				end
			end
		end,
		cl_func = [[
			Derma_StringRequest("Введите кол-во","","",
			function(text)
				RunConsoleCommand("admin.SetArmor", plysteamid, text)
			end,function(text)end)
		]],
		rank = 5,
	},
	["SetJob"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					for index,job in pairs(RPExtraTeams) do
						if string.lower(job.name) == string.lower(args[2]) then
							v:changeTeam(index, true)
							AdminLog(admin, 'изменил роль на '..job.name..' игроку', v)
						end
					end
				end
			end
		end,
		cl_func = [[
			Derma_StringRequest("Введите работу","","",
			function(text)
				RunConsoleCommand("admin.SetJob", plysteamid, text)
			end,function(text)end)
		]],
		rank = 5,
	},
	["BanJob"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					for index,job in pairs(RPExtraTeams) do
						if string.lower(job.name) == string.lower(args[2]) then
							v:SetPData("jobban_"..index, os.time()+tonumber(args[3]))
							AdminLog(admin, 'заблокировал роль '..job.name..' на '..TimeToStringShort(args[3])..' игроку', v)
						end
					end
				end
			end
		end,
		cl_func = [[
			Derma_StringRequest("Введите работу","","",
			function(text)
				first = text
				Derma_StringRequest("Введите время","s,m,h,d,w,y","",
				function(text)
					RunConsoleCommand("admin.BanJob", plysteamid, first, tonumber(StringToTime(text)))
				end,function(text)end)
			end,function(text)end)
		]],
		rank = 5,
	},
	["UnBanJob"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					for index,job in pairs(RPExtraTeams) do
						if string.lower(job.name) == string.lower(args[2]) then
							v:SetPData("jobban_"..index, os.time())
							AdminLog(admin, 'разблокировал роль '..job.name..' игроку', v)
						end
					end
				end
			end
		end,
		cl_func = [[
			Derma_StringRequest("Введите работу","","",
			function(text)
				RunConsoleCommand("admin.UnBanJob", plysteamid, text)
			end,function(text)end)
		]],
		rank = 5,
	},
	["ReSpawn"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					v:KillSilent()
					v:Spawn()
					AdminLog(admin, 'респавнул', v)
				end
			end
		end,
		cl_func = [[
			RunConsoleCommand("admin.ReSpawn", plysteamid)
		]],
		rank = 5,
	},
	["StripWeapons"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					v:StripWeapons()
					AdminLog(admin, 'убрал все оружие у игрока', v)
				end
			end
		end,
		cl_func = [[
			RunConsoleCommand("admin.StripWeapons", plysteamid)
		]],
		rank = 5,
	},
	["Cloak"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					v:SetNoDraw(true)
					AdminLog(admin, 'включил невидимость игроку', v)
				end
			end
		end,
		cl_func = [[
			RunConsoleCommand("admin.Cloak", plysteamid)
		]],
		rank = 1,
	},
	["UnCloak"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					v:SetNoDraw(false)
					AdminLog(admin, 'выключил невидимость игроку', v)
				end
			end
		end,
		cl_func = [[
			RunConsoleCommand("admin.UnCloak", plysteamid)
		]],
		rank = 1,
	},
	["God"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					v:GodEnable()
					AdminLog(admin, 'включил бессмертие игроку', v)
				end
			end
		end,
		cl_func = [[
			RunConsoleCommand("admin.God", plysteamid)
		]],
		rank = 1,
	},
	["UnGod"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					v:GodDisable()
					AdminLog(admin, 'выключил бессмертие игроку', v)
				end
			end
		end,
		cl_func = [[
			RunConsoleCommand("admin.UnGod", plysteamid)
		]],
		rank = 1,
	},
	["CleanUP"] = {
		func = function(admin, cmd, args)
			game.CleanUpMap()
			AdminLog(admin, "очистил карту.")
		end,
		cl_func = [[
			RunConsoleCommand("admin.CleanUP")
		]],
		noply = true,
		rank = 5,
	},
	["NSpectate"] = {
		func = function(admin, cmd, args)
			admin:ConCommand("FSpectate")
		end,
		cl_func = [[
			RunConsoleCommand("admin.NSpectate")
		]],
		noply = true,
		rank = 5,
	},
	["Spectate"] = {
		func = function(admin, cmd, args)
		end,
		cl_func = [[
			RunConsoleCommand("FSpectate", plysteamid)
		]],
		rank = 5,
	},
	["ClearDecals"] = {
		func = function(admin, cmd, args)
			for k,v in ipairs(player.GetAll()) do
				v:SendLua("RunConsoleCommand('r_cleardecals')")
				v:SendLua("game.RemoveRagdolls()")
			end
			for _, ent in pairs(ents.GetAll()) do
				if ent:GetClass() == "spawned_food" || ent:GetClass() == "armor" || ent:GetClass() == "medkit" || ent:GetClass() == "pistol_ammo" || ent:GetClass() == "rifle_ammo" || ent:GetClass() == "shotgun_ammo" then
					ent:Remove()
				end
			end
			AdminLog(admin, "очистил мусор.")
		end,
		cl_func = [[
			RunConsoleCommand("admin.ClearDecals")
		]],
		noply = true,
		rank = 5,
	},
	["StopSounds"] = {
		func = function(admin, cmd, args)
			for k,v in ipairs(player.GetAll()) do
				v:SendLua("RunConsoleCommand('stopsound')")
			end
			AdminLog(admin, "остановил все звуки.")
		end,
		cl_func = [[
			RunConsoleCommand("admin.StopSounds")
		]],
		noply = true,
		rank = 5,
	},
	["LockDoor"] = {
		func = function(admin, cmd, args)
			local door = admin:GetEyeTrace().Entity
			door:Fire("Lock")
		end,
		cl_func = [[
			RunConsoleCommand("admin.LockDoor")
		]],
		noply = true,
		rank = 5,
	},
	["UnLockDoor"] = {
		func = function(admin, cmd, args)
			local door = admin:GetEyeTrace().Entity
			door:Fire("UnLock")
		end,
		cl_func = [[
			RunConsoleCommand("admin.UnLockDoor")
		]],
		noply = true,
		rank = 5,
	},
	["SIDBan"] = {
		func = function(admin, cmd, args)
			AddBan(nil, args[1], args[3], args[2], nil)
			AdminLog(admin, "забанил "..args[1].." на "..TimeToStringShort(args[2]).." с причиной: "..args[3])
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] then
					v:Kick("Вы были забанены.")
				end
			end
		end,
		cl_func = [[
			Derma_StringRequest("Введите SteamID","STEAM_0:1:123456789","",
			function(text)
				local first = text
				Derma_StringRequest("Введите время","s,m,h,d,w,y","",
				function(text)
					local second = tonumber(StringToTime(text))
					Derma_StringRequest("Введите причину","","",
					function(text)
						RunConsoleCommand("admin.SIDBan", first, second, text)
					end,function(text)end)
				end,function(text)end)
			end,function(text)end)
		]],
		noply = true,
		rank = 5,
	},
	["Ban"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					AddBan(v:Nick(), v:SteamID(), args[3], args[2], v:IPAddress())
					AdminLog(admin, "забанил "..v:Nick().." на "..TimeToStringShort(args[2]).." с причиной: "..args[3])
					v:Kick("Вы были забанены.")
				end
			end
		end,
		cl_func = [[
			Derma_StringRequest("Введите время","s,m,h,d,w,y","",
			function(text)
				local first = tonumber(StringToTime(text))
				Derma_StringRequest("Введите причину","","",
				function(text)
					RunConsoleCommand("admin.Ban", plysteamid, first, text)
				end,function(text)end)
			end,function(text)end)
		]],
		rank = 5,
	},
	["Jail"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					Jail(v, args[3], args[2])
					AdminLog(admin, "посадил в джайл игрока "..v:Nick().." на "..TimeToStringShort(args[2]).." с причиной: "..args[3])
				end
			end
		end,
		cl_func = [[
			Derma_StringRequest("Введите время","s,m,h,d,w,y","",
			function(text)
				local first = tonumber(StringToTime(text))
				Derma_StringRequest("Введите причину","","",
				function(text)
					RunConsoleCommand("admin.Jail", plysteamid, first, text)
				end,function(text)end)
			end,function(text)end)
		]],
		rank = 1,
	},
	["Kick"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					AdminLog(admin, "кикнул "..v:Nick().." с причиной: "..args[2])
					v:Kick(args[2])
				end
			end
		end,
		cl_func = [[
			Derma_StringRequest("Введите причину","","",
			function(text)
				RunConsoleCommand("admin.Kick", plysteamid, text)
			end,function(text)end)
		]],
		rank = 5,
	},
	["SetStaff"] = {
		func = function(admin, cmd, args)
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == args[1] or v:SteamID64() == args[1] or v:Nick() == args[1] or v:AccountID() == args[1] then
					SetStaff(v, args[2])
					AdminLog(admin, "выдал привилегию "..args[2].." игроку "..v:Nick().."("..v:SteamID()..")", nil, true)
				end
			end
		end,
		cl_func = [[
			Derma_StringRequest("Введите привилегию","","",
			function(text)
				RunConsoleCommand("admin.setstaff", plysteamid, text)
			end,function(text)end)
		]],
		rank = 8,
	},
}

for k,v in pairs(AdminCommands) do
	concommand.Add("admin."..k, function(admin, cmd, args)
		if admin:GetStaffRank() >= v.rank then
			if args[1] ~= nil then
				for _,ply in ipairs(player.GetAll()) do
					if ply:SteamID() == args[1] or ply:SteamID64() == args[1] or ply:Nick() == args[1] or ply:AccountID() == args[1] then
						if admin:GetStaffRank() >= ply:GetStaffRank() then
							v.func(admin,nil,args)
						else
							admin:PlayerMsg(Color(255,50,50), " [Admin] ", Color(255,255,255), "У вас недостаточно разрешений, чтобы активировать команду на этом человеке.")
						end
					end
				end
			else
				v.func(admin,nil,args)
			end
		else
			admin:PlayerMsg(Color(255,50,50), "[Admin] У вас недостаточно разрешений для этой команды.")
		end
	end)
end

hook.Add("PlayerSay", "Admin.ChatMute", function(ply, text)
	if ply:GetPData("chatmute", "1") <= tostring(os.time()) then return end
	if string.lower(text) ~= "/unchatmute" and string.lower(text) ~= "!unchatmute" then
		ply:PlayerMsg(Color(50,200,50), " ⮞ ", Color(255,255,255), "У вас мут, подождите ещё "..TimeToStringShort(ply:GetPData("chatmute")-os.time()))
		return ""
	end
end)

hook.Add("PlayerCanHearPlayersVoice", "Admin.VoiceMute", function(listener, talker)
	if listener:GetPData("voicemute", "1") <= tostring(os.time()) then return end
	return false
end)

hook.Add('playerCanChangeTeam', 'Admin.AdminBanJob', function(ply, tm, force)
	if ply:GetPData("jobban_"..tm) == nil then return end
	if ply:GetPData("jobban_"..tm) >= tostring(os.time()) and not force then
		ply:PlayerMsg(Color(50,200,50), " ⮞ ", Color(255,255,255), "Эта профессия для вас запрещена, подождите ещё "..TimeToStringShort(ply:GetPData("jobban_"..tm)-os.time()))
		return false
	end
end)

util.AddNetworkString("Admin.Menu")
hook.Add("PlayerSay", "Admin.Menu", function(ply, text)
	if text == "/menu" then
		if ply:GetStaffRank() >= 1 then
			local commands = {}
			for k,v in SortedPairs(AdminCommands) do
				if ply:GetStaffRank() >= v.rank then
					if v.noply == nil then
						noply = false
					else
						noply = true
					end
					local send = {
						name = k,
						cl_func = v.cl_func,
						noply = noply,
					}
					table.insert(commands, send)
				end
			end

			net.Start("Admin.Menu")
				net.WriteString(util.TableToJSON(commands))
			net.Send(ply)
		else
			ply:PlayerMsg(Color(255,50,50), "[Admin] У вас недостаточно разрешений для этой команды.")
		end
		return ""
	end
end)

local jailpos = {
	Vector(-2424, 12031, -406),
	Vector(-2456, 12600, -406),
	Vector(-2992, 12612, -406),
	Vector(-3001, 11851, -406),
}

function Jail(ply, rsn, time)
	local times = time+os.time()
	local pos = table.Random(jailpos)
	ply:SetPos(pos)
	ply:SetPData("Admin.JailTime", times)
	ply:SetPData("Admin.JailRsn", rsn)
	print(times)
	ply:SetNWInt("Admin.JailTimee", times)
end

hook.Add("PlayerSpawn", "Admin.JailSpawn", function(ply)
	if os.time() <= tonumber(ply:GetPData("Admin.JailTime", 0)) then
		timer.Simple(2, function()
			local pos = table.Random(jailpos)
			ply:SetPos(pos)
		end)
	end
end)

timer.Create("Admin.JailCheck",5,0,function()
	for k,v in pairs(player.GetAll()) do
		if os.time() <= tonumber(v:GetPData("Admin.JailTime", 0)) then
			local tbl = ents.FindInBox(Vector(7867, 14348, 74), Vector(2298, 10974, 285))
			if table.HasValue(tbl, v) then
				v:StripWeapons()
				v:SetNWInt("Admin.JailTimee", tonumber(v:GetPData("Admin.JailTime")))
			else
				local pos = table.Random(jailpos)
				v:SetPos(pos)
			end
		end
		if (os.time() >= tonumber(v:GetPData("Admin.JailTime", 0))) and v:GetPData("Admin.JailRsn") ~= "" then
			v:KillSilent()
			v:SetPData("Admin.JailTime", 0)
			v:SetPData("Admin.JailRsn", "")
			v:SetNWInt("Admin.JailTimee", 0)
		end
	end
end)

hook.Add("PlayerSay", "Admin.JailChatMute", function(ply, text)
	if ply:GetPData("Admin.JailTime", "1") <= tostring(os.time()) then return end
	if string.lower(text) == "/ooc" or string.lower(text) == "//" then
		ply:PlayerMsg(Color(50,200,50), " ⮞", Color(255,255,255), "Вы можете писать только в обычный чат.")
		return ""
	end
end)

--[[
	==============================================
    					Logs
	==============================================
]]

util.AddNetworkString("Admin.OpenLogs")
util.AddNetworkString("Admin.InsertLogs")
hook.Add("PlayerSay", "Admin.OpenLogs", function(ply, text)
	if text == "/logs" then
		if ply:GetStaffRank() >= 1 then
			local logs = util.JSONToTable(file.Read("logs.txt", "DATA"))

			local categ = {}
			for k, v in ipairs(logs) do
				if v.time > (os.time()-1800) then
					if not table.HasValue(categ, v.category) then
						table.insert(categ, v.category)
					end
				end
			end

			net.Start("Admin.OpenLogs")
				net.WriteString(util.TableToJSON(categ))
			net.Send(ply)

			for k,v in pairs(logs) do
				if v.time > (os.time()-1800) then
					net.Start("Admin.InsertLogs")
						net.WriteString(util.TableToJSON(v))
					net.Send(ply)
				end
			end

		else
			ply:PlayerMsg(Color(255,50,50), "[Admin] У вас недостаточно разрешений для этой команды.")
		end
		return ""
	end
end)
function AddLog(cat, ply, ply2, text)
	local time = os.time()
	local logs = util.JSONToTable(file.Read("logs.txt", "DATA"))
	logtable = {
		time = os.time(),
		category = cat,
		info = text,
	}
	if IsValid(ply) and !IsValid(ply2) then
		logtable = {
			time = os.time(),
			category = cat,
			info = text,
			firstply = {
				nick = ply:Nick(),
				sid = ply:SteamID(),
				pos = ply:GetPos(),
				color = team.GetColor(ply:Team()),
			},
		}
	end
	if IsValid(ply) and IsValid(ply2) then
		logtable = {
			time = os.time(),
			category = cat,
			info = text,
			firstply = {
				nick = ply:Nick(),
				sid = ply:SteamID(),
				pos = ply:GetPos(),
				color = team.GetColor(ply:Team()),
			},
			secondply = {
				nick = ply2:Nick(),
				sid = ply2:SteamID(),
				pos = ply2:GetPos(),
				color = team.GetColor(ply2:Team()),
			},
		}
	end
	table.insert(logs, logtable)
	file.Write("logs.txt", util.TableToJSON(logs))
	logtable = {}
end

if file.Exists("logs.txt", "DATA") == false then
	file.Write("logs.txt", "[]")
end

gameevent.Listen("player_connect")
hook.Add("player_connect", "Logs.AddConnect", function(data)
	local name = data.name
	local steamid = data.networkid

	AddLog("Подключения", nil, nil, name.."("..steamid..") присоединился.")
end)

gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", "Logs.AddDisconnect", function(data)
	local name = data.name
	local steamid = data.networkid

	AddLog("Подключения", nil, nil, name.."("..steamid..") отключился.")
end)

hook.Add("PlayerDeath", "Logs.AddKill", function(victim, inflictor, attacker)
    if IsValid(attacker) then
		if attacker:IsPlayer() then
			AddLog("Смерти", attacker, victim, (IsValid(attacker:GetActiveWeapon()) and "("..attacker:GetActiveWeapon():GetClass()..")" or '').."убил")
		else
			if attacker.CPPIGetOwner and IsValid(attacker:CPPIGetOwner()) then
				AddLog("Смерти", attacker:CPPIGetOwner(), victim, "("..attacker:GetClass()..") убил")
			else
				AddLog("Смерти", victim, nil, "был убит "..attacker:GetClass())
			end
		end
    end
end)

hook.Add("EntityTakeDamage", "Logs.AddDamage", function(ent, dmginfo)
    if IsValid(attacker) then
		if ent:IsPlayer() then
			local attacker = dmginfo:GetAttacker()
			if IsValid(attacker) then
				if attacker:IsPlayer() then
					AddLog("Урон", attacker, ent, (IsValid(attacker:GetActiveWeapon()) and "("..attacker:GetActiveWeapon():GetClass()..")" or '()').."нанёс "..math.Round(dmginfo:GetDamage(), 0).." урона")
				else
					if attacker.CPPIGetOwner and IsValid(attacker:CPPIGetOwner()) then
						AddLog("Урон", attacker:CPPIGetOwner(), ent, "("..attacker:GetClass()..") нанёс "..math.Round(dmginfo:GetDamage(), 0).." урона")
					else
						AddLog("Смерти", victim, nil, "был убит "..attacker:GetClass())
						AddLog("Урон", nil, ent, attacker:GetClass().." нанёс "..math.Round(dmginfo:GetDamage(), 0).." урона")
					end
				end
			end
		end
	end
end)

hook.Add("onPlayerChangedName", "Logs.AddNick", function(pl, old, new)
	if IsValid(pl) then
		AddLog("Ник", pl, nil, ": "..old.." => "..new)
	end
end)

hook.Add("HMHitAccepted", "Logs.AddHitAccepted", function(hitman, target, amount)
	if IsValid(target) then
		AddLog("Заказ", hitman, target, "принял заказ на")
	end
end)

hook.Add("HMHitComplete", "Logs.AddHitComplete", function(hitman, target, amount)
	if IsValid(target) then
		AddLog("Заказ", hitman, target, "выполнил заказ на")
	end
end)

hook.Add("OnPlayerChangedTeam", "Logs.AddDamage", function(pl, old, new)
	if IsValid(pl) then
		AddLog("Профессия", pl, nil, ": "..team.GetName(old).." => "..team.GetName(new))
	end
end)

hook.Add("playerArrested", "Logs.AddArrest", function(target, time, officer)
	if IsValid(officer) then
		AddLog("Арест", officer, target, "арестовал")
	end
end)

hook.Add("playerUnArrested", "Logs.AddUnArrest", function(target, officer)
	if IsValid(officer) then
		AddLog("Арест", officer, target, "разрестовал")
	else
		AddLog("Арест", officer, nil, "был выпущен из тюрьмы")
	end
end)

hook.Add("playerWanted", "Logs.AddWanted", function(target, officer, reason)
	if IsValid(officer) then
		AddLog("Розыск", officer, target, "("..reason..") взял розыск")
	end
end)

hook.Add("playerUnWanted", "Logs.AddUNWanted", function(target, officer)
	if IsValid(officer) then
		AddLog("Розыск", officer, target, "снял розыск")
	else
		AddLog("Розыск", officer, nil, "срок действия розыска истек.")
	end
end)

hook.Add("playerWarranted", "Logs.AddWarrant", function(target, officer, reason)
	if IsValid(officer) then
		AddLog("Ордер", officer, target, "("..reason..") выдал ордер")
	end
end)

hook.Add("playerUnWarranted", "Logs.AddUnWarrant", function(target, officer)
	if IsValid(officer) then
		AddLog("Ордер", officer, target, "снял ордер")
	else
		AddLog("Ордер", target, nil, "срок действия ордера истек.")
	end
end)


--[[
	==============================================
    					Bans
	==============================================
]]

function AddBan(name, steamid, reason, time, ip)
	local time = os.time()+time
	local bans = util.JSONToTable(file.Read("bans.txt", "DATA"))
	local bantable = {
		{
			steamid = steamid,
			name = name,
			reason = reason,
			time = time,
			ip = ip,
		},
	}
	table.insert(bans, bantable)
	file.Write("bans.txt", util.TableToJSON(bans))
end

hook.Add( "CheckPassword", "Admin.BanCheck", function(sid64)
	local bans = util.JSONToTable(file.Read("bans.txt", "DATA"))
	for k,v in pairs(bans) do
		local checksteamid = util.SteamIDTo64(v[1].steamid)
		if sid64 == checksteamid then
			if v[1].time >= os.time() then
				return false, "Вы были забанены.\nПричина: "..v[1].reason.."\nОсталось: "..TimeToString(v[1].time-os.time())
			end
		end
	end
end)

util.AddNetworkString("Admin.OpenBans")
hook.Add("PlayerSay", "Admin.OpenBans", function(ply, text)
	if text == "/bans" then
		if ply:GetStaffRank() >= 1 then
			local bans = file.Read("bans.txt", "DATA")
			net.Start("Admin.OpenBans")
				net.WriteString(bans)
			net.Send(ply)
		else
			ply:PlayerMsg(Color(255,50,50), "[Admin] У вас недостаточно разрешений для этой команды.")
		end
		return ""
	end
end)

if file.Exists("bans.txt", "DATA") == false then
	file.Write("bans.txt", "[]")
end

--[[
	==============================================
    					Reports
	==============================================
]]

util.AddNetworkString("Admin.Report")
hook.Add("PlayerSay", "Admin.Report", function(ply, text)
	local text = string.Explode( " ", text)
	if text[1] == "@" then
		if !ply:GetNWBool("admin.report") then
			local rsn = table.concat(text, " ", 2, #text) or "Игрок забыл указать причину!"
			ply:SetNWString("admin.reporttext", rsn)
			ply:SetNWBool("admin.report", true)
			ply:SetNWInt("admin.reporttime", os.time())
			ply:PlayerMsg(Color(50,255,50), "[#] Спасибо, что подали жалобу! Администрация постарается разобрать её как можно скорее.")
			for k,v in pairs(player.GetAll()) do
				if v:GetStaffRank() >= 1 then
					v:PlayerMsg(Color(255,255,255), "Поступила новая жалоба от ", team.GetColor(ply:Team()), ply:Nick(),Color(255,255,255),": "..rsn)
					v:EmitSound("buttons/combine_button1.wav")
				end
			end
		else
			ply:PlayerMsg(Color(255,50,50), "[#] У вас уже есть одна активная жалоба.")
		end
		return ""
	end
	if text[1] == "/monitoring" and ply:GetStaffRank() >= 1 then
		if ply:GetNWBool("admin.offmonitoring") then
			ply:SetNWBool("admin.offmonitoring", false)
		else
			ply:SetNWBool("admin.offmonitoring", true)
		end
		return ""
	end
end)

timer.Create("Admin.CheckMonitoring",1,0,function()
	for k,v in pairs(player.GetAll()) do
		if v:GetStaffRank() == 0 then
			v:SetNWBool("admin.monitoring", true)
		elseif v:GetNWBool("admin.offmonitoring") == false and v:GetStaffRank() >= 1 then
			v:SetNWBool("admin.monitoring", false)
		end
	end
end)

concommand.Add("report", function(admin, cmd, args)
	if admin:GetStaffRank() >= 1 then
		if args[1] == "claim" then
			for k,v in pairs(player.GetAll()) do
				if args[2] == v:SteamID() and (admin:GetNWString("admin.claimadmin") == "") then
					v:SetNWBool("admin.claim", true)
					admin:SetNWString("admin.claimadmin", v:SteamID())
				end
			end
		elseif args[1] == "unclaim" then
			for k,v in pairs(player.GetAll()) do
				if args[2] == v:SteamID() and (admin:GetNWString("admin.claimadmin") == v:SteamID()) then
					v:SetNWBool("admin.claim", false)
					admin:SetNWString("admin.claimadmin", "")
				end
			end
		elseif args[1] == "close" then
			for k,v in pairs(player.GetAll()) do
				if args[2] == v:SteamID() and (admin:GetNWString("admin.claimadmin") == v:SteamID()) then
					admin:SetNWString("admin.claimadmin", "")
					v:SetNWBool("admin.claim", false)
					v:SetNWString("admin.reporttext", nil)
					v:SetNWBool("admin.report", false)
					v:SetNWInt("admin.reporttime", nil)
				end
			end
		else
			admin:PlayerMsg(Color(255,50,50), "[Report] Ошибка!")
		end
	else
		admin:PlayerMsg(Color(255,50,50), "[Admin] У вас недостаточно разрешений для этой команды.")
	end
end)

util.AddNetworkString("Admin.RunLua")

hook.Add('PlayerShouldTakeDamage','Admin.GreenZone',function(ply, attacker)
	if ply:GetNWBool("SafeZone.GodMe") then
		return false
	end
end)
timer.Create("GreenZone.CheckPlayer",5,0,function()
	local safezone = ents.FindInBox(Vector(-10616, 7, -399), Vector(-9879, 1035, -49))
	for k,v in pairs(safezone) do
		if IsValid(v) and v:IsPlayer() then
			v:ConCommand("cl_refreshlegs")
			v:SetMaterial("models/wireframe")
			v:SetColor(Color(125,0,250))
			v:SetNWBool("SafeZone.GodMe", true)
		end
		if v:GetClass() == "prop_physics" then
			v:Remove()
		end
	end
	for k, v in pairs(player.GetAll()) do
		if !table.HasValue(safezone, v) then
			if IsValid(v) and v:IsPlayer() then
				v:ConCommand("cl_refreshlegs")
				v:SetMaterial("")
				v:SetColor(Color(255,255,255))
				v:SetNWBool("SafeZone.GodMe", false)
			end
		end
	end
end)


local sendreportlua = [[
	surface.CreateFont("Admin.ReportFont", {
		font = "Roboto",
		size = ScrH()*0.02,
		antialias = true,
		outline = true,
		extended = true,
	})
	timer.Create("Admin.Report",1,1,function()
		if Report then Report:Remove() end
		Report = {}
	
		local mainreport = vgui.Create("EditablePanel")
		mainreport:SetSize(ScrW()*0.2, ScrH()*0.3)
		mainreport:SetPos(ScrW()*0.8, ScrH()*0)
		mainreport.Paint = function(self,w,h)
			--draw.RoundedBox(0,0,0,w,h,Color(25,25,25))
			return true
		end
	
		local scroll = mainreport:Add("DScrollPanel")
		scroll:Dock(FILL)
	
		timer.Create("UpdateReport",1,0,function()
			scroll:Clear()
			for k,v in ipairs(player.GetAll()) do
				if (v:GetNWBool("admin.claim") == false and v:GetNWBool("admin.report") and IsValid(v) and v:Name() ~= LocalPlayer():Name()) or (v:SteamID() == LocalPlayer():GetNWString("admin.claimadmin")) then
					local reports = scroll:Add("DButton")
					reports:SetSize(ScrW()*0, ScrH()*0.065)
					reports:Dock(TOP)
					reports.Paint = function(self,w,h)
						return true
					end
					local infoplayer = reports:Add("EditablePanel")
					infoplayer:SetSize(reports:GetWide()*0, reports:GetTall()*1)
					infoplayer:Dock(TOP)
					infoplayer.Paint = function(self,w,h)
						if v:GetNWBool("admin.claim") then
							draw.RoundedBox(0,0,0,w,h,Color(127,0,255))
						else
							draw.RoundedBox(0,0,0,w,h,Color(65,65,65))
						end
						surface.SetDrawColor(Color(0,0,0))
						surface.DrawOutlinedRect(0,0,w,h)
						draw.SimpleText(IsValid(v) and v:Nick() or "Игрок вышел, обновляюсь.".." - "..os.date( "%H:%M", v:GetNWInt("admin.reporttime")), "Admin.ReportFont", w*0.05, h*0.35, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
						return true
					end
					local reason = infoplayer:Add("DLabel")
					reason:SetSize(infoplayer:GetWide()*0, infoplayer:GetTall()*0.4)
					reason:Dock(BOTTOM)
					reason:SetFont("Admin.ReportFont")
					reason:SetTextColor(Color(255,255,255))
					reason:SetText(v:GetNWString("admin.reporttext"))
					local claim = infoplayer:Add("DImageButton")
					claim:SetSize(ScrW()*0.02, reports:GetTall()*0)
					claim:Dock(RIGHT)
					claim:SetImage("icon16/accept.png")
					claim.DoClick = function()
						local menu = DermaMenu()
							if v:GetNWBool("admin.claim") then
								menu:AddOption("Отдать жалобу", function()RunConsoleCommand("report", "unclaim", v:SteamID())end)
								menu:AddOption("Закрыть жалобу", function()RunConsoleCommand("report", "close", v:SteamID())end)
							else
								menu:AddOption("Взять жалобу", function()RunConsoleCommand("report", "claim", v:SteamID())end)
						   end
							menu:AddSpacer()
							menu:AddOption("Закрыть", function()end)
						menu:Open()
					end
					if v:SteamID() == LocalPlayer():GetNWString("admin.claimadmin") then
						local helper = infoplayer:Add("DImageButton")
						helper:SetSize(ScrW()*0.02, reports:GetTall()*0)
						helper:Dock(RIGHT)
						helper:SetImage("icon16/brick.png")
						helper.DoClick = function()
							local menu = DermaMenu()
								menu:AddOption("Открыть логи", function()LocalPlayer():SetNWString("Logs.Category", v:SteamID())RunConsoleCommand("say","/logs")end)
								menu:AddSpacer()
								menu:AddOption("Телепортироваться к нему", function()RunConsoleCommand("admin.goto", v:SteamID())end)
								menu:AddOption("Телепортировать к себе", function()RunConsoleCommand("admin.bring", v:SteamID())end)
								menu:AddOption("Вернуть обратно", function()RunConsoleCommand("admin.return", v:SteamID())end)
								menu:AddSpacer()
								menu:AddOption("Скопировать SteamID", function()SetClipboardText(v:SteamID())end)
								menu:AddSpacer()
								menu:AddOption("Закрыть", function()end)
							menu:Open()
						end
					end
				end
			end
		end)
	
		timer.Create("Admin.Reported",1,0,function()
			if LocalPlayer():GetNWBool("admin.monitoring") then
				mainreport:SetSize(ScrW()*0, ScrH()*0)
				mainreport:SetPos(ScrW()*0.8, ScrH()*0)
			else
				mainreport:SetSize(ScrW()*0.2, ScrH()*0.3)
				mainreport:SetPos(ScrW()*0.8, ScrH()*0)
			end
		end)
	
		function Report:Remove()
			mainreport:Remove()
		end
	end)
]]
hook.Add("PlayerInitialSpawn", "Admin.SendReport", function(ply)
	if ply:GetStaffRank() >= 1 then
		timer.Simple(2, function()
			net.Start("Admin.RunLua")
				net.WriteString(sendreportlua)
			net.Send(ply)
		end)
	end
end)

hook.Add("CanPlayerSuicide", "Admin.AllowSuicide", function(ply)
	ply:PlayerMsg(Color(255,50,50), "[Admin] ", Color(255,255,255), "Самоубийство отключено.")
	return false
end )