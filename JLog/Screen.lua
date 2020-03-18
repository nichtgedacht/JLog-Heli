-- Draw Battery and percentage display
local function drawBattery(remaining, alarm_thresh)

	-- Battery
	lcd.drawFilledRectangle(148, 48, 24, 7)	-- Top of Battery
	lcd.drawRectangle(134, 55, 52, 80)
	-- Level of Battery
	local chgY = (135 - (remaining * 0.8))
	local chgH = (remaining * 0.8)

	lcd.drawFilledRectangle(135, chgY, 50, chgH)

	-- Percentage Display
	if( remaining > alarm_thresh ) then	
		lcd.drawRectangle(115, 2, 90, 43, 10)
		lcd.drawRectangle(114, 1, 92, 45, 11)
		lcd.drawText(160 - (lcd.getTextWidth(FONT_MAXI, string.format("%.0f%%",remaining)) / 2),4, string.format("%.0f%%",
							remaining),FONT_MAXI)
	else
		if( system.getTime() % 2 == 0 ) then -- blink every second
			lcd.drawRectangle(115, 2, 90, 43, 10)
			lcd.drawRectangle(114, 1, 92, 45, 11)
			lcd.drawText(160 - (lcd.getTextWidth(FONT_MAXI, string.format("%.0f%%",remaining)) / 2),4, string.format("%.0f%%",
								remaining),FONT_MAXI)
		end
	end

	collectgarbage()
end

-- Draw left top box
local function drawLetopbox(trns, average, min, max)    -- Flightpack Voltage
	-- draw fixed Text
	lcd.drawText(57 - (lcd.getTextWidth(FONT_MINI,trns.mainbat) / 2),1,trns.mainbat,FONT_MINI)
	lcd.drawText(82, 20, "V", FONT_MINI)
	lcd.drawText(6, 32, "Min/Max:", FONT_MINI)

	-- draw Values, average is average of last 1000 values
	lcd.drawText(80 - lcd.getTextWidth(FONT_BIG, string.format("%.1f", average)),13, string.format("%.1f",
	average), FONT_BIG)
	lcd.drawText(60, 32, string.format("%.1f - %.1f", min, max), FONT_MINI)
end

-- Draw left middle box
local function drawLemidbox(trns, rpm, min, max)	-- Rotor Speed
	-- draw fixed Text
	lcd.drawText(50 - (lcd.getTextWidth(FONT_MINI,trns.rotspeed) / 2),50,trns.rotspeed,FONT_MINI)
	lcd.drawText(82, 81, "U/min", FONT_MINI)
	lcd.drawText(6, 97, "Min/Max:", FONT_MINI)

	-- draw Values
	lcd.drawText(80 - lcd.getTextWidth(FONT_MAXI,string.format("%.0f",rpm)),61,string.format("%.0f",rpm),FONT_MAXI)
	lcd.drawText(60,97, string.format("%.0f - %.0f", min, max), FONT_MINI)
end

-- Draw left bottom box
local function drawLebotbox(current, a1, a2, voltage)	-- BEC Voltage
	-- draw fixed Text
	lcd.drawText(6, 116, "I", FONT_BIG)
	lcd.drawText(14, 124, "Motor:", FONT_MINI)
	lcd.drawText(110, 124, "A", FONT_MINI)
        
	-- draw current 
	lcd.drawText(105 - lcd.getTextWidth(FONT_BIG, string.format("%.1f",current)),116, string.format("%.1f",current),FONT_BIG)
        
	-- separator
	lcd.drawFilledRectangle(4, 142, 116, 2)

	-- draw fixed Text
	lcd.drawText(6, 148, "URx", FONT_MINI)
	lcd.drawText(70, 148, "A", FONT_MINI)

	-- draw RX Values
	lcd.drawText(98 - lcd.getTextWidth(FONT_MINI, string.format("%d",a1)),148, string.format("%d",a1),FONT_MINI)
	lcd.drawText(118 - lcd.getTextWidth(FONT_MINI, string.format("%d",a2)),148, string.format("%d",a2),FONT_MINI)

	--lcd.drawText(120 - lcd.getTextWidth(FONT_MINI, string.format("%.0f %%",rx_percent)),148, string.format("%.0f %%",rx_percent),FONT_MINI)
	lcd.drawText(60 - lcd.getTextWidth(FONT_MINI, string.format("%.2fV",voltage)),148, string.format("%.2fV",voltage),FONT_MINI) 
end

-- Draw right top box
local function drawRitopbox(trns, st, mi, se, day)	-- Flight Time
	-- draw fixed Text
	lcd.drawText(265 - (lcd.getTextWidth(FONT_MINI, trns.ftime)/2), 1, trns.ftime, FONT_MINI)
	lcd.drawText(251 - (lcd.getTextWidth(FONT_MINI, trns.date)), 32, trns.date, FONT_MINI)

	-- draw Values
	lcd.drawText(255 - (lcd.getTextWidth(FONT_BIG, string.format("%0d:%02d:%02d", st, mi, se)) / 2), 13, string.format("%0d:%02d:%02d",
						st, mi, se), FONT_BIG)
	lcd.drawText(255, 32, string.format("%02d.%02d.%02d", day.day, day.mon, day.year), FONT_MINI)
end

-- Draw right middle box
local function drawRimidbox(trns, used, initial_percent_used, capacity )	-- Used Capacity
    
	local total_used_capacity = math.ceil( used + (initial_percent_used * capacity) / 100 )

	-- draw fixed Text
	lcd.drawText(262 - (lcd.getTextWidth(FONT_MINI,trns.usedCapa) / 2),50,trns.usedCapa,FONT_MINI)
	lcd.drawText(285, 81, "mAh", FONT_MINI)
	lcd.drawText(205, 97, trns.capacity, FONT_MINI)

	-- draw Values
	lcd.drawText(282 - lcd.getTextWidth(FONT_MAXI, string.format("%.0f",total_used_capacity)),61, string.format("%.0f",
				total_used_capacity), FONT_MAXI)
	lcd.drawText(258,97, string.format("%s mAh", capacity),FONT_MINI)
end

-- Draw right bottom box
local function drawRibotbox(maxrxa, maxcur, maxpwm, maxtmp)	-- Some Max Values

	-- draw fixed Text
	lcd.drawText(205, 113, "MaxIBEC", FONT_MINI)
	lcd.drawText(205, 125, "MaxIMot", FONT_MINI)
	lcd.drawText(205, 137, "MaxPWM", FONT_MINI)
	lcd.drawText(205, 149, "MaxTFETs", FONT_MINI)
	
	lcd.drawText(302,113,"A",FONT_MINI)
	lcd.drawText(302,125,"A",FONT_MINI)
	lcd.drawText(302,137,"%",FONT_MINI)
	lcd.drawText(302,149,"°C",FONT_MINI)

	-- draw Max Values  
	lcd.drawText(295 - lcd.getTextWidth(FONT_MINI, string.format("%.1f",maxrxa)),113, string.format("%.1f",maxrxa),FONT_MINI)
	lcd.drawText(295 - lcd.getTextWidth(FONT_MINI, string.format("%.1f",maxcur)),125, string.format("%.1f",maxcur),FONT_MINI)
	lcd.drawText(295 - lcd.getTextWidth(FONT_MINI, string.format("%.0f",maxpwm)),137, string.format("%.0f",maxpwm),FONT_MINI)
	lcd.drawText(295 - lcd.getTextWidth(FONT_MINI, string.format("%.0f",maxtmp)),149, string.format("%.0f",maxtmp),FONT_MINI)
end

local function drawMibotbox(gyro)

	--[[
	Gyro Gain    
	Mini-Vstabi range is: +40 ... +120
	this range correponds to a
	Gyro Channel Value (times 100) range: -39 ... +93
	Scale and offset
	- renorm to zero ( gyro_channel * 100 + 39 )
	- scale ( 120 - 40 ) / ( 93 + 39 ) = 0.60606060...
	- offset +40
	- gyro_percent = (gyro_channel * 100 + 39) * 0.6060 + 40
	- gyro_percent = gyro_channel * 60.606 + 63.6363   
	--]]

	local gyro_percent = gyro * 60.606 + 63.6363

	if (gyro_percent < 40) then gyro_percent = 40 end
	if (gyro_percent > 120) then gyro_percent = 120 end

	-- draw fixed Text
	lcd.drawText(136,145,"GY",FONT_MINI)
	-- draw Max Values
	lcd.drawText(184 - lcd.getTextWidth(FONT_BIG, string.format("%.0f", gyro_percent)), 138, string.format("%.0f",
				 gyro_percent), FONT_BIG)
end	

local function drawSeparators()
	-- draw horizontal lines
	lcd.drawFilledRectangle(4, 47, 104, 2)     --lo
	lcd.drawFilledRectangle(4, 111, 116, 2)    --lu
	lcd.drawFilledRectangle(212, 47, 104, 2)   --ro
	lcd.drawFilledRectangle(200, 111, 116, 2)  --ru
	lcd.drawFilledRectangle(4, 142, 116, 2)
end

return {

	drawBattery = drawBattery,
	drawLetopbox = drawLetopbox,
	drawLemidbox = drawLemidbox,
	drawLebotbox = drawLebotbox,
	drawRitopbox = drawRitopbox,
	drawRimidbox = drawRimidbox,
	drawRibotbox = drawRibotbox,
	drawMibotbox = drawMibotbox,
	drawSeparators = drawSeparators,

}
