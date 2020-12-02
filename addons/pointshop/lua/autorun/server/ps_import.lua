local oldconfig = {
	["a1"] = "model_overhaul",
	["a2"] = "model_niko",
	["a3"] = "model_izaya",
	["a321"] = "model_rize",
	["a412ddd"] = "model_silverfox",
	["frisk"] = "model_amiya",
	["ghfghf"] = "model_hyunwoo",
	["hhghg"] = "model_sandfox",
	["ivormodel"] = "model_potofu",
	["mai"] = "model_mei1",
	["mai2"] = "model_mei2",
	["mda"] = "model_wolfberry",
	["ribbon"] = "model_clancy",
	["sy4ka123"] = "model_yukari",
	["update1"] = "model_fiona",
	["update2"] = "model_raphtalia",
	["update3"] = "model_hel",
	["update4"] = "model_miles",
	["update32"] = "model_paimon",
	["update33"] = "model_obsidian",
	["update34"] = "model_zhongli",
	["update41"] = "model_kurotsuno",
	["update42"] = "model_dailin",
}

for _, ply in ipairs(player.GetAll()) do
	if ply:GetPData("PS_Items") == nil then return end
	if ply:GetPData("PS_Items") == false then return end
	local tbl = util.JSONToTable(ply:GetPData("PS_Items", "[]"))
	for k,v in pairs(tbl) do
		for oldindex,v in pairs(oldconfig) do
			if oldindex == k then
				ply:GiveItem(v)
				ply:SyncPoints()
				ply:SyncItem()
			end
		end
	end
end

hook.Add("PlayerAuthed", "AnimeWorld.PS.ImportOldPS", function(ply)
	if ply:GetPData("PS_Items") == nil then return end
	if ply:GetPData("PS_Items") == false then return end
	local tbl = util.JSONToTable(ply:GetPData("PS_Items", "[]"))
	for k,v in pairs(tbl) do
		for oldindex,v in pairs(oldconfig) do
			if oldindex == k then
				ply:GiveItem(v)
			end
		end
	end
end)