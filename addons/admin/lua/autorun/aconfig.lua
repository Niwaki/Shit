Admin = Admin or {}

local timetable = {
	{regex = "y",	name = "year",		mult = 60 * 60 * 24 * 365},
	{regex = "w",	name = "week",		mult = 60 * 60 * 24 * 7},
	{regex = "d",	name = "day",		mult = 60 * 60 * 24},
	{regex = "h",	name = "hour",		mult = 60 * 60},
	{regex = "m",	name = "minute",	mult = 60},
	{regex = "s",	name = "second",	mult = 1}
}

function StringToTime(str)
	local t = 0
	local found
	for k, v in next, timetable do
		local res, _, dat = str:find("(%d+)" .. v.regex)
		if res then
			found = true
			t = t + dat * v.mult
		end
	end
	return found and t
end

local function s(str, times)
	return times > 1 and str .. "s" or str
end

function TimeToString(time)
	if time == 0 then
		return "0"
	end
	local res = {}
	for k, v in next, timetable do
		if v.mult > 1 or #res <= 1 then
			local div = time / v.mult
			if div >= 1 then
				div = math.floor(div)
				time = time - div * v.mult
				table.insert(res, div .. " " .. s(v.name, div))
			end
		end
	end
	return #res > 0 and table.concat(res, " ")
end

function TimeToStringShort(time)
	if time == 0 then
		return "0"
	end
	local res = ""
	for k, v in next, timetable do
		local div = time / v.mult
		if div >= 1 then
			div = math.floor(div)
			time = time - div * v.mult
			res = res .. div .. v.regex
		end
	end
	return res ~= "" and res
end

local function DaysInYear(year)
	return year%4 == 0 and (year%100 ~= 0 or year%400 == 0) and 366 or 365
end

function RelativeDate(time, nohours)
	local now = os.date("*t")
	local Then = os.date("*t", time)
	local diff = (Then.yday + (Then.year > now.year and DaysInYear(now.year) or 0)) - (now.yday + (Then.year < now.year and DaysInYear(now.year) or 0))
	return os.date((diff == 0 and "сегодня в" or diff == 1 and "завтра в" or diff == -1 and "вчера в" or "%d.%m.%y") .. (nohours and "" or " %H:%M"), time)
end