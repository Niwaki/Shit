surface.CreateFont("Admin.CloseMenu", {
	font = "Roboto",
	size = ScrH()*0.025,
    antialias = true,
    outline = true,
    extended = true,
})

net.Receive("Admin.Broadcast",function(len)
    local msg = net.ReadTable()
    chat.AddText(unpack(msg))
    chat.PlaySound()
end)

net.Receive("Admin.Menu",function(len)
    local commands = util.JSONToTable(net.ReadString())

    local amenu = vgui.Create("EditablePanel")
    amenu:SetSize(ScrW()*0.2, ScrH()*0.4)
    amenu:Center()
    amenu:MakePopup()
    amenu.Paint = function(self,w,h)
        draw.RoundedBox(4, 0, 0, w, h, Color(25,25,25))
        return true
    end

    local closemenu = amenu:Add("DButton")
    closemenu:SetSize(ScrW()*0, ScrH()*0.025)
    closemenu:Dock(BOTTOM)
    closemenu.Paint = function(self,w,h)
        if self:IsHovered() then
            draw.RoundedBox(4, 0, 0, w, h, Color(255,50,50))
        else
            draw.RoundedBox(4, 0, 0, w, h, Color(150,50,50))
        end
        draw.SimpleText("Закрыть", "Admin.CloseMenu", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return true
    end
    closemenu.DoClick = function()
        amenu:Remove()
    end

    local noplayer = amenu:Add("DButton")
    noplayer:SetSize(ScrW()*0, ScrH()*0.03)
    noplayer:Dock(TOP)
    noplayer.Paint = function(self,w,h)
        if self:IsHovered() then
            draw.RoundedBox(4, 0, 0, w, h, Color(255,185,50))
        else
            draw.RoundedBox(4, 0, 0, w, h, Color(255,150,0))
        end
        draw.SimpleText("ADMIN", "Admin.CloseMenu", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return true
    end
    noplayer.DoClick = function()
        local m = DermaMenu()
        for k,v in pairs(commands) do
            if v.noply then
                m:AddOption(v.name, function()
                    if v.cl_func ~= nil then
                        RunString(v.cl_func)
                    else
                        chat.AddText(Color(255, 255, 255), "[#] '"..v.name.."' в разработке.")
                    end
                end)
            end
        end
        m:Open()
    end

    local scroll = amenu:Add("DScrollPanel")
    scroll:Dock(FILL)

    for k,v in pairs(player.GetAll()) do v.hide = false end
    local function RefreshPlayer()
        for index,ply in pairs(player.GetAll()) do
            if ply.hide == false then
                local players = scroll:Add("DButton")
                players:SetSize(ScrW()*0, ScrH()*0.03)
                players:Dock(TOP)
                players.Paint = function(self,w,h)
                    if IsValid(ply) then
                        if self:IsHovered() then
                            draw.RoundedBox(4, 0, 0, w, h, Color(team.GetColor(ply:Team()).r+25,team.GetColor(ply:Team()).g+25,team.GetColor(ply:Team()).b+25))
                        else
                            draw.RoundedBox(4, 0, 0, w, h, team.GetColor(ply:Team()))
                        end
                        draw.SimpleText(ply:Nick(), "Admin.CloseMenu", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    else
                        draw.SimpleText("Игрок покинул сервер", "Admin.CloseMenu", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                    return true
                end
                players.DoClick = function()
                    local m = DermaMenu()
                    for k,v in pairs(commands) do
                        if !v.noply then
                            m:AddOption(v.name, function()
                                if v.cl_func ~= nil then
                                    plysteamid = ply:SteamID()
                                    RunString(v.cl_func)
                                else
                                    chat.AddText(Color(255, 255, 255), "[#] '"..v.name.."' в разработке.")
                                end
                            end)
                        end
                    end
                    m:Open()
                end
            end
        end
    end


    RefreshPlayer()
    local search = amenu:Add("DTextEntry")
    search:SetSize(ScrW()*0, ScrH()*0.035)
    search:Dock(TOP)
    search:SetValue("Поиск...")
    search.OnEnter = function(self)
        scroll:Clear()
        for k,v in pairs(player.GetAll()) do
            if self:GetValue() == v:SteamID() or string.find(v:Name(), self:GetValue()) or self:GetValue() == v:SteamID64() then
                v.hide = false
            else
                v.hide = true
            end
        end
        RefreshPlayer()
    end

end)

net.Receive("Admin.OpenBans",function(len)
    local bans = util.JSONToTable(net.ReadString())
    local amenu = vgui.Create("EditablePanel")
    amenu:SetSize(ScrW()*0.8, ScrH()*0.6)
    amenu:Center()
    amenu:MakePopup()
    amenu.Paint = function(self,w,h)
        draw.RoundedBox(4, 0, 0, w, h, Color(25,25,25))
        return true
    end

    local closemenu = amenu:Add("DButton")
    closemenu:SetSize(ScrW()*0, ScrH()*0.025)
    closemenu:Dock(BOTTOM)
    closemenu.Paint = function(self,w,h)
        if self:IsHovered() then
            draw.RoundedBox(4, 0, 0, w, h, Color(255,50,50))
        else
            draw.RoundedBox(4, 0, 0, w, h, Color(150,50,50))
        end
        draw.SimpleText("Закрыть", "Admin.CloseMenu", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return true
    end
    closemenu.DoClick = function()
        amenu:Remove()
    end

    local infoban = amenu:Add("EditablePanel")
    infoban:SetSize(ScrW()*0, ScrH()*0.03)
    infoban:Dock(TOP)
    infoban.Paint = function(self,w,h)
        draw.SimpleText("Игрок", "Admin.CloseMenu", w*0, h/2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Причина", "Admin.CloseMenu", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Разбан", "Admin.CloseMenu", w, h/2, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        return true
    end

    local scroll = amenu:Add("DScrollPanel")
    scroll:Dock(FILL)

    for k,v in pairs(bans) do v[1].hide = false end
    local function RefreshBans()
        for k,v in pairs(bans) do
            if v[1].hide == false then
                local players = scroll:Add("DButton")
                players:SetSize(ScrW()*0, ScrH()*0.035)
                players:Dock(TOP)
                players.Paint = function(self,w,h)
                    if v[1].time < os.time() then
                        draw.RoundedBox(4, 0, 0, w, h, Color(70,150,70))
                    else
                        draw.RoundedBox(4, 0, 0, w, h, Color(150,70,70))
                    end
                    draw.SimpleText((v[1].name or "").."("..v[1].steamid..")", "Admin.CloseMenu", w*0, h/2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(v[1].reason, "Admin.CloseMenu", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(RelativeDate(v[1].time), "Admin.CloseMenu", w, h/2, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                    return true
                end
                players.DoClick = function()
                    local m = DermaMenu()
                    m:Open()
                end
            end
        end
    end


    RefreshBans()
    local search = amenu:Add("DTextEntry")
    search:SetSize(ScrW()*0, ScrH()*0.035)
    search:Dock(TOP)
    search:SetValue("Поиск...")
    search.OnEnter = function(self)
        scroll:Clear()
        for k,v in pairs(bans) do
            if self:GetValue() == v[1].name or self:GetValue() == v[1].steamid or self:GetValue() == v[1].reason or self:GetValue() == v[1].ip then
                v[1].hide = false
            else
                v[1].hide = true
            end
        end
        RefreshBans()
    end

end)

surface.CreateFont("Admin.LogFont", {
	font = "Trebuchet18",
	size = ScrH()*0.017,
    antialias = true,
    outline = true,
    extended = true,
})

surface.CreateFont("Admin.CloseLog", {
	font = "Roboto",
	size = ScrH()*0.025,
    antialias = true,
    outline = true,
    extended = true,
})

net.Receive("Admin.OpenLogs", function()
    local categ = util.JSONToTable(net.ReadString())

    local lm = vgui.Create("EditablePanel")
    lm:SetSize(ScrW()*0.5, ScrH()*0.5)
    lm:Center()
    lm:MakePopup()
    lm.Paint = function(self,w,h)
        draw.RoundedBox(0,0,0,w,h,Color(25,25,25))
        return true
    end

    local text = lm:Add("RichText")
    text:Dock(FILL)
    text.PerformLayout = function(self)
        self:SetFontInternal("Admin.LogFont")
        self:SetBGColor(Color(0, 16, 32))
    end

    local i=0
    net.Receive("Admin.InsertLogs", function()
        local log = util.JSONToTable(net.ReadString())
        if LocalPlayer():GetNWString("Logs.Category") == "Все" or LocalPlayer():GetNWString("Logs.Category") == log.category or LocalPlayer():GetNWString("Logs.Category") == log.firstsid then
            i=i+1
            text:InsertColorChange(255,150,0,255)
            text:AppendText("["..os.date("%H:%M:%S",log.time).."]["..log.category.."]")

            if log.firstply then
                text:InsertColorChange(log.firstply.color.r,log.firstply.color.g,log.firstply.color.b,255)
                text:InsertClickableTextStart(util.TableToJSON(log.firstply))
                text:AppendText((log.firstply.sid or ""))
                text:InsertClickableTextEnd()
            end

            text:InsertColorChange(255,255,255,255)
            text:AppendText(" "..log.info.." ")

            if log.secondply then
                text:InsertColorChange(log.secondply.color.r,log.secondply.color.g,log.secondply.color.b,255)
                text:InsertClickableTextStart(util.TableToJSON(log.secondply))
                text:AppendText((log.secondply.sid or "").."\n")
                text:InsertClickableTextEnd()
            else
                text:AppendText("\n")
            end

            function text:ActionSignal(n, l)
                if n == "TextClicked" then
                    local log = util.JSONToTable(l)
                    local menu = DermaMenu()
                    menu:AddOption("Открыть профиль в Steam", function()gui.OpenURL("http://steamcommunity.com/profiles/"..util.SteamIDTo64(log.sid))end)
                    menu:AddOption("Телепортироваться на позицию", function()RunConsoleCommand("admin.gotopos", log.pos[1], log.pos[2], log.pos[3])end)
                    menu:AddOption("Скопировать Nick", function()SetClipboardText(log.nick)end)
                    menu:AddOption("Скопировать SteamID", function()SetClipboardText(log.sid)end)
                    menu:Open()
                end
            end

        end
    end)

    local closelm = lm:Add("DButton")
    closelm:SetSize(lm:GetWide()*0, lm:GetTall()*0.075)
    closelm:Dock(BOTTOM)
    closelm.Paint = function(self,w,h)
        draw.RoundedBox(0,0,0,w,h,Color(150,50,50))
        draw.SimpleText("Закрыть", "Admin.CloseLog", w/2, h/2, Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
        return true
    end
    closelm.DoClick = function()lm:Remove()end

    local filter = lm:Add("DButton")
    filter:SetSize(lm:GetWide()*0, lm:GetTall()*0.075)
    filter:Dock(TOP)
    filter.Paint = function(self,w,h)
        draw.RoundedBox(0,0,0,w,h,Color(50,150,50))
        draw.SimpleText("Фильтр", "Admin.CloseLog", w/2, h/2, Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
        return true
    end
    filter.DoClick = function()
        local menu = DermaMenu()
        menu:AddOption("Все", function()LocalPlayer():SetNWString("Logs.Category", "Все")lm:Remove()RunConsoleCommand("say", "/logs")end)
        menu:AddOption("Поиск по SteamID", function()
            Derma_StringRequest("Введите SteamID","","", function(text) LocalPlayer():SetNWString("Logs.Category", text) lm:Remove() RunConsoleCommand("say", "/logs") end, function(text)end)
        end)
        for k,v in ipairs(categ) do
            menu:AddOption(v, function()
                LocalPlayer():SetNWString("Logs.Category", v)
                lm:Remove()
                RunConsoleCommand("say", "/logs")
            end)
        end
        menu:Open()
    end

end)

net.Receive("Admin.RunLua", function()
    local lua = net.ReadString()
    RunString(lua)
end)