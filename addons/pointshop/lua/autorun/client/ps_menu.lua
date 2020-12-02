for i = 1, 40 do
	surface.CreateFont("PS_Font_"..i, {
		font = "Arial",
		extended = true,
		outline = true,
		size = i,
	})
end

surface.CreateFont("PS_Font_Close", {
	font = "Marlett",
	extended = true,
	symbol = true,
	outline = true,
	size = 19,
})

net.Receive("PS.Balance", function()
	PS.MyBalance = tonumber(net.ReadString())
end)
net.Receive("PS.SyncItem", function()
	PS.MyPurchase = net.ReadTable()
end)

function PS:OpenMenu()
	if IsValid(pointshop_main) then pointshop_main:Remove() end

	pointshop_main = vgui.Create("EditablePanel")
	pointshop_main:SetSize(ScrW()*0.6, ScrH()*0.6)
	pointshop_main:Center()
	pointshop_main:MakePopup()
	pointshop_main.Paint = function(s,w,h)
		if input.IsKeyDown(KEY_ESCAPE) then
			pointshop_main:Remove()
			gui.HideGameUI()
		end
		Derma_DrawBackgroundBlur(pointshop_main)
		draw.RoundedBox(2,0,0,w,h,Color(25,25,25))
		draw.SimpleText("Баланс: "..PS:FormatMoney(PS.MyBalance), "PS_Font_22", w*0.93, h*0.01, Color(255,255,255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
	end

	local w,h = pointshop_main:GetSize()

	pointshop_closemain = pointshop_main:Add("DButton")
	pointshop_closemain:SetSize(w*0.05, h*0.04)
	pointshop_closemain:SetPos(w*0.945, h*0.01)
	pointshop_closemain.Paint = function(s,w,h)
		if s:IsDown() then
			draw.RoundedBox(2,0,0,w,h,Color(255,50,50))
		elseif s:IsHovered() then
			draw.RoundedBox(2,0,0,w,h,Color(200,50,50))
		else
			draw.RoundedBox(2,0,0,w,h,Color(150,50,50))
		end
		draw.SimpleText("r", "PS_Font_Close", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		return true
	end
	pointshop_closemain.DoClick = function()
		pointshop_main:Remove()
	end

	local pointshop_sendpoints = pointshop_main:Add("DButton")
	pointshop_sendpoints:SetSize(w*0.2,h*0.08)
	pointshop_sendpoints:SetPos(w*0,h*0)
	pointshop_sendpoints.Paint = function(s,w,h)
		draw.RoundedBox(2,0,0,w,h,Color(75,0,130))
		draw.SimpleText("Отправить поинты", "PS_Font_17", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		return true
	end
	pointshop_sendpoints.DoClick = function()
		local m = DermaMenu()
		for k,v in ipairs(player.GetAll()) do
			--if v == LocalPlayer() then return end
			m:AddOption(v:Nick(), function()
				Derma_StringRequest("", "Укажите сумму перевода", "", function(text)
					local text = tonumber(text) or 0
					if text and isnumber(text) then
						net.Start("PS.SendPoints")
							net.WriteEntity(v)
							net.WriteInt(text,32)
						net.SendToServer()
					end
				end)
			end)
		end
		m:Open()
	end

	local sheet = pointshop_main:Add("DPropertySheet")
	sheet:Dock(BOTTOM)
	sheet:SetSize(w*0, h*0.92)

	local scroll = sheet:Add("DHorizontalScroller")
	scroll:Dock(FILL)
	scroll:SetOverlap(-4)
	sheet:AddSheet("Поинтшоп", scroll, "icon16/coins.png")

	local scroll2 = sheet:Add("DHorizontalScroller")
	scroll2:Dock(FILL)
	scroll2:SetOverlap(-4)
	sheet:AddSheet("Сезонное", scroll2, "icon16/medal_gold_1.png")

	if LocalPlayer():IsSuperAdmin() then
		local adminlist = pointshop_main:Add("DListView")
		adminlist:Dock(FILL)
		adminlist:SetMultiSelect(false)
		adminlist:AddColumn("Имя")
		adminlist:AddColumn("Поинты")
		adminlist:AddColumn("Предметы")
		local adminlistreload = adminlist:Add("DButton")
		adminlistreload:Dock(BOTTOM)
		adminlistreload:SetSize(w*0,h*0.08)
		adminlistreload.Paint = function(self,w,h)
			draw.RoundedBox(0,0,0,w,h,Color(200,50,50))
			draw.SimpleText("Прогрузить игроков", "PS_Font_17", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			return true
		end
		adminlistreload.DoClick = function()
			net.Start("PS.GetInfo")
			net.SendToServer()
			adminlistreload:Remove()
		end


		net.Receive("PS.GetInfo", function()
			local name = net.ReadString()
			local points = net.ReadString()
			local items = net.ReadString()

			adminlist:AddLine(name, points, items)
		end)

		adminlist.OnRowSelected = function(lst, index, pnl)
			CloseDermaMenus()
			local m = DermaMenu()
			m:AddOption("Добавить поинтов", function()
				Derma_StringRequest("", "Добавить поинтов", "", function(text)
					local text = tonumber(text)
					if text == nil or !isnumber(text) then return end
					net.Start("PS.Admin")
					net.WriteString(pnl:GetColumnText(1))
					net.WriteString("addpoints")
					net.WriteInt(text, 32)
					net.SendToServer()
					adminlist:Clear()
					net.Start("PS.GetInfo")
					net.SendToServer()
				end)
			end)
			m:AddOption("Установить поинтов", function()
				Derma_StringRequest("", "Установить поинтов", "", function(text)
					local text = tonumber(text)
					if text == nil or !isnumber(text) then return end
					net.Start("PS.Admin")
					net.WriteString(pnl:GetColumnText(1))
					net.WriteString("setpoints")
					net.WriteInt(text, 32)
					net.SendToServer()
					adminlist:Clear()
					net.Start("PS.GetInfo")
					net.SendToServer()
				end)
			end)
			local sm = m:AddSubMenu("Выдать вещь")
			for k,v in ipairs(PS.Items) do
				if table.HasValue(string.Explode(";", pnl:GetColumnText(3)), v.name) then continue end
				sm:AddOption(v.name, function()
					net.Start("PS.Admin")
					net.WriteString(pnl:GetColumnText(1))
					net.WriteString("giveitem")
					net.WriteString(v.code)
					net.SendToServer()
					adminlist:Clear()
					net.Start("PS.GetInfo")
					net.SendToServer()
				end)
			end
			local sm = m:AddSubMenu("Забрать вещь")
			for k,v in ipairs(PS.Items) do
				if !table.HasValue(string.Explode(";", pnl:GetColumnText(3)), v.name) then continue end
				sm:AddOption(v.name, function()
					net.Start("PS.Admin")
					net.WriteString(pnl:GetColumnText(1))
					net.WriteString("takeitem")
					net.WriteString(v.code)
					net.SendToServer()
					adminlist:Clear()
					net.Start("PS.GetInfo")
					net.SendToServer()
				end)
			end
			m:AddOption("Закрыть меню", function()
			end)
			m:Open()
		end
		sheet:AddSheet("Админ-панель", adminlist, "icon16/medal_gold_1.png")
	end

	for k,v in ipairs(PS.Items) do
		if v.season then continue end
		local bgscroll = scroll:Add("EditablePanel")
		bgscroll:Dock(LEFT)
		bgscroll:SetSize(w*0.19,h*0.88)
		bgscroll.Paint = function(s,w,h)
			draw.RoundedBox(0,0,0,w,h,v.color)
		end
		if v.type ~= "script" then
			local mainmodel = bgscroll:Add("DModelPanel")
			mainmodel:Dock(FILL)
			mainmodel:SetModel(v.model)
			local mn, mx = mainmodel.Entity:GetRenderBounds()
			local size = 0
			size = math.max(size,math.abs(mn.x)+math.abs(mx.x))
			size = math.max(size,math.abs(mn.y)+math.abs(mx.y))
			size = math.max(size,math.abs(mn.z)+math.abs(mx.z))
			mainmodel:SetFOV(18)
			mainmodel:SetCamPos(Vector(size,size,size))
			mainmodel:SetLookAt((mn + mx) * 0.5)
		else
			if v.icon then
				local mainmodel = bgscroll:Add("DImage")
				mainmodel:DockMargin(w*0.03, h*0.25, w*0.03, h*0.25)
				mainmodel:Dock(FILL)
				mainmodel:SetImage(v.icon)
			end
			if v.desc then
				local mainmodel = bgscroll:Add("RichText")
				mainmodel:Dock(FILL)
				mainmodel:InsertColorChange(255,255,255,255)
				mainmodel:AppendText(v.desc)
				mainmodel.Paint = function(self,w,h)
					self:SetFontInternal("PS_Font_17")
				end
			end
		end

		local pointshop_closemain = bgscroll:Add("DButton")
		pointshop_closemain:SetSize(w*0, h*0.05)
		pointshop_closemain:Dock(BOTTOM)
		pointshop_closemain.Paint = function(s,w,h)
			if table.HasValue(PS.MyPurchase, v.code) then
				if s:IsDown() then
					draw.RoundedBox(2,0,0,w,h,Color(50,255,50))
				elseif s:IsHovered() then
					draw.RoundedBox(2,0,0,w,h,Color(50,200,50))
				else
					draw.RoundedBox(2,0,0,w,h,Color(50,150,50))
				end
			elseif PS.MyBalance>=v.price then
				if s:IsDown() then
					draw.RoundedBox(2,0,0,w,h,Color(255,150,50))
				elseif s:IsHovered() then
					draw.RoundedBox(2,0,0,w,h,Color(225,150,50))
				else
					draw.RoundedBox(2,0,0,w,h,Color(210,140,50))
				end
			else
				if s:IsDown() then
					draw.RoundedBox(2,0,0,w,h,Color(255,50,50))
				elseif s:IsHovered() then
					draw.RoundedBox(2,0,0,w,h,Color(200,50,50))
				else
					draw.RoundedBox(2,0,0,w,h,Color(150,50,50))
				end
			end
			if table.HasValue(PS.MyPurchase, v.code) then
				if LocalPlayer():GetModel() == v.model then
					draw.SimpleText("Снять", "PS_Font_17", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				else
					draw.SimpleText("Надеть", "PS_Font_17", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
			else
				draw.SimpleText("Цена: "..PS:FormatMoney(v.price), "PS_Font_17", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			return true
		end
		pointshop_closemain.DoClick = function()
			if table.HasValue(PS.MyPurchase, v.code) then
				net.Start("PS.Equip")
				net.WriteString(v.code)
				net.SendToServer()
			else
				net.Start("PS.BuyItem")
				net.WriteString(v.code)
				net.SendToServer()
			end
		end
		scroll:AddPanel(bgscroll)
	end

	for k,v in ipairs(PS.Items) do
		if !v.season then continue end
		local bgscroll = scroll2:Add("EditablePanel")
		bgscroll:Dock(LEFT)
		bgscroll:SetSize(w*0.19,h*0.88)
		bgscroll.Paint = function(s,w,h)
			draw.RoundedBox(0,0,0,w,h,v.color)
		end

		--if v.type ~= "script" then
			local mainmodel = bgscroll:Add("DModelPanel")
			mainmodel:Dock(FILL)
			mainmodel:SetModel(v.model)
			local mn, mx = mainmodel.Entity:GetRenderBounds()
			local size = 0
			size = math.max(size,math.abs(mn.x)+math.abs(mx.x))
			size = math.max(size,math.abs(mn.y)+math.abs(mx.y))
			size = math.max(size,math.abs(mn.z)+math.abs(mx.z))
			mainmodel:SetFOV(18)
			mainmodel:SetCamPos(Vector(size,size,size))
			mainmodel:SetLookAt((mn + mx) * 0.5)
		--else
			if v.icon then
				local mainmodel = bgscroll:Add("DImage")
				mainmodel:DockMargin(w*0.03, h*0.25, w*0.03, h*0.25)
				mainmodel:Dock(FILL)
				mainmodel:SetImage(v.icon)
			end
			if v.desc then
				local mainmodel = bgscroll:Add("RichText")
				mainmodel:Dock(FILL)
				mainmodel:InsertColorChange(255,255,255,255)
				mainmodel:AppendText(v.desc)
				mainmodel.Paint = function(self,w,h)
					self:SetFontInternal("PS_Font_17")
				end
			end
		--end

		local pointshop_closemain = bgscroll:Add("DButton")
		pointshop_closemain:SetSize(w*0, h*0.05)
		pointshop_closemain:Dock(BOTTOM)
		pointshop_closemain.Paint = function(s,w,h)
			if table.HasValue(PS.MyPurchase, v.code) then
				if s:IsDown() then
					draw.RoundedBox(2,0,0,w,h,Color(50,255,50))
				elseif s:IsHovered() then
					draw.RoundedBox(2,0,0,w,h,Color(50,200,50))
				else
					draw.RoundedBox(2,0,0,w,h,Color(50,150,50))
				end
			elseif PS.MyBalance>=v.price then
				if s:IsDown() then
					draw.RoundedBox(2,0,0,w,h,Color(255,150,50))
				elseif s:IsHovered() then
					draw.RoundedBox(2,0,0,w,h,Color(225,150,50))
				else
					draw.RoundedBox(2,0,0,w,h,Color(210,140,50))
				end
			else
				if s:IsDown() then
					draw.RoundedBox(2,0,0,w,h,Color(255,50,50))
				elseif s:IsHovered() then
					draw.RoundedBox(2,0,0,w,h,Color(200,50,50))
				else
					draw.RoundedBox(2,0,0,w,h,Color(150,50,50))
				end
			end
			if table.HasValue(PS.MyPurchase, v.code) then
				if LocalPlayer():GetModel() == v.model then
					draw.SimpleText("Снять", "PS_Font_17", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				else
					draw.SimpleText("Надеть", "PS_Font_17", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
			else
				draw.SimpleText("Цена: "..PS:FormatMoney(v.price), "PS_Font_17", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			return true
		end
		pointshop_closemain.DoClick = function()
			if table.HasValue(PS.MyPurchase, v.code) then
				net.Start("PS.Equip")
				net.WriteString(v.code)
				net.SendToServer()
			else
				net.Start("PS.BuyItem")
				net.WriteString(v.code)
				net.SendToServer()
			end
		end
		scroll2:AddPanel(bgscroll)
	end
end

net.Receive("PS.OpenMenu", function()
	gui.HideGameUI()
	PS:OpenMenu()
end)