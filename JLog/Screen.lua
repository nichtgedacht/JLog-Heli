local remaining_capacity_percent = 100
local battery_voltage_average = 0.0
local minvtg = 99
local maxvtg = 0
local mintmp = 99
local maxtmp = 0
local rotor_rpm = 0
local minrpm = 999
local maxrpm = 0
local minpwm = 100
local maxpwm = 0
local motor_current = 0.0
local bec_current = 0
local pwm_percent = 0
local fet_temp = 0
local mincur = 99.9
local maxcur = 0.0
local rx_a1 = 0
local rx_a2 = 0
local std = 0
local min = 0
local sec = 0
local time = 0
local newTime = 0
local lastTime = 0
local next_capacity_announcement = 0
local next_voltage_announcement = 0
local tickTime = 0
local next_capacity_alarm = 0
local next_voltage_alarm = 0
local last_averaging_time = 0
local voltage_alarm_dec_thresh
local today = {}
local used_capacity = 0
local initial_voltage_measured = false
local initial_capacity_percent_used = 0
local maxrxa = 0.0
local minrxa = 9.9
local maxrxv = 0.0
local minrxv = 9.9
local rx_voltage = 0
local gyro_channel_val = 0
local voltages_list = {}

local vars = {}

-- maps cell voltages to remainig capacity
local percentList	=	{{3,0},{3.093,1},{3.196,2},{3.301,3},{3.401,4},{3.477,5},{3.544,6},{3.601,7},{3.637,8},{3.664,9},
						{3.679,10},{3.683,11},{3.689,12},{3.692,13},{3.705,14},{3.71,15},{3.713,16},{3.715,17},{3.72,18},
						{3.731,19},{3.735,20},{3.744,21},{3.753,22},{3.756,23},{3.758,24},{3.762,25},{3.767,26},{3.774,27},
						{3.78,28},{3.783,29},{3.786,30},{3.789,31},{3.794,32},{3.797,33},{3.8,34},{3.802,35},{3.805,36},
						{3.808,37},{3.811,38},{3.815,39},{3.818,40},{3.822,41},{3.825,42},{3.829,43},{3.833,44},{3.836,45},
						{3.84,46},{3.843,47},{3.847,48},{3.85,49},{3.854,50},{3.857,51},{3.86,52},{3.863,53},{3.866,54},
						{3.87,55},{3.874,56},{3.879,57},{3.888,58},{3.893,59},{3.897,60},{3.902,61},{3.906,62},{3.911,63},
						{3.918,64},{3.923,65},{3.928,66},{3.939,67},{3.943,68},{3.949,69},{3.955,70},{3.961,71},{3.968,72},
						{3.974,73},{3.981,74},{3.987,75},{3.994,76},{4.001,77},{4.007,78},{4.014,79},{4.021,80},{4.029,81},
						{4.036,82},{4.044,83},{4.052,84},{4.062,85},{4.074,86},{4.085,87},{4.095,88},{4.105,89},{4.111,90},
						{4.116,91},{4.12,92},{4.125,93},{4.129,94},{4.135,95},{4.145,96},{4.176,97},{4.179,98},{4.193,99},
						{4.2,100}}

local function init (stpvars)
	
	vars = stpvars
	today = system.getDateTime()
	voltage_alarm_dec_thresh = vars.voltage_alarm_thresh / 10
	
end	

-- Draw Battery and percentage display
local function drawBattery()
	
	-- Battery
	lcd.drawFilledRectangle(148, 48, 24, 7)	-- Top of Battery
	lcd.drawRectangle(134, 55, 52, 80)
	-- Level of Battery
	local chgY = (135 - (remaining_capacity_percent * 0.8))
	local chgH = (remaining_capacity_percent * 0.8)
	
	lcd.drawFilledRectangle(135, chgY, 50, chgH)
			
	-- Percentage Display
	if( remaining_capacity_percent > vars.capacity_alarm_thresh ) then	
		lcd.drawRectangle(115, 2, 90, 43, 10)
		lcd.drawRectangle(114, 1, 92, 45, 11)
		lcd.drawText(160 - (lcd.getTextWidth(FONT_MAXI, string.format("%.0f%%",remaining_capacity_percent)) / 2),4, string.format("%.0f%%",
							remaining_capacity_percent),FONT_MAXI)
	else
		if( system.getTime() % 2 == 0 ) then -- blink every second
			lcd.drawRectangle(115, 2, 90, 43, 10)
			lcd.drawRectangle(114, 1, 92, 45, 11)
			lcd.drawText(160 - (lcd.getTextWidth(FONT_MAXI, string.format("%.0f%%",remaining_capacity_percent)) / 2),4, string.format("%.0f%%",
								remaining_capacity_percent),FONT_MAXI)
		end
	end
		
	collectgarbage()
end

-- Draw left top box
local function drawLetopbox()    -- Flightpack Voltage
	-- draw fixed Text
	lcd.drawText(57 - (lcd.getTextWidth(FONT_MINI,vars.trans.mainbat) / 2),1,vars.trans.mainbat,FONT_MINI)
	lcd.drawText(82, 20, "V", FONT_MINI)
	lcd.drawText(6, 32, "Min/Max:", FONT_MINI)
		
	-- draw Values
	lcd.drawText(80 - lcd.getTextWidth(FONT_BIG, string.format("%.1f", battery_voltage_average)),13, string.format("%.1f",
	battery_voltage_average), FONT_BIG)
	lcd.drawText(60, 32, string.format("%.1f - %.1f", minvtg, maxvtg), FONT_MINI)
end

-- Draw left middle box
local function drawLemidbox()	-- Rotor Speed
	-- draw fixed Text
	lcd.drawText(50 - (lcd.getTextWidth(FONT_MINI,vars.trans.rotspeed) / 2),50,vars.trans.rotspeed,FONT_MINI)
	lcd.drawText(82, 81, "U/min", FONT_MINI)
	lcd.drawText(6, 97, "Min/Max:", FONT_MINI)
		
	-- draw Values
	lcd.drawText(80 - lcd.getTextWidth(FONT_MAXI,string.format("%.0f",rotor_rpm)),61,string.format("%.0f",rotor_rpm),FONT_MAXI)
       lcd.drawText(60,97, string.format("%.0f - %.0f", minrpm, maxrpm), FONT_MINI)
end

-- Draw left bottom box
local function drawLebotbox()	-- BEC Voltage
	-- draw fixed Text
	lcd.drawText(6, 116, "I", FONT_BIG)
	lcd.drawText(14, 124, "Motor:", FONT_MINI)
	lcd.drawText(110, 124, "A", FONT_MINI)
        
	-- draw current 
	lcd.drawText(105 - lcd.getTextWidth(FONT_BIG, string.format("%.1f",motor_current)),116, string.format("%.1f",motor_current),FONT_BIG)
        
	-- separator
	lcd.drawFilledRectangle(4, 142, 116, 2)
	
	-- draw fixed Text
	lcd.drawText(6, 148, "URx", FONT_MINI)
	lcd.drawText(70, 148, "A", FONT_MINI)
	
	-- draw RX Values
	lcd.drawText(98 - lcd.getTextWidth(FONT_MINI, string.format("%d",rx_a1)),148, string.format("%d",rx_a1),FONT_MINI)
	lcd.drawText(118 - lcd.getTextWidth(FONT_MINI, string.format("%d",rx_a2)),148, string.format("%d",rx_a2),FONT_MINI)
	
	--lcd.drawText(120 - lcd.getTextWidth(FONT_MINI, string.format("%.0f %%",rx_percent)),148, string.format("%.0f %%",rx_percent),FONT_MINI)
	lcd.drawText(60 - lcd.getTextWidth(FONT_MINI, string.format("%.2fV",rx_voltage)),148, string.format("%.2fV",rx_voltage),FONT_MINI) 
end

-- Draw right top box
local function drawRitopbox()	-- Flight Time
	-- draw fixed Text
	lcd.drawText(265 - (lcd.getTextWidth(FONT_MINI, vars.trans.ftime)/2), 1, vars.trans.ftime, FONT_MINI)
	lcd.drawText(251 - (lcd.getTextWidth(FONT_MINI, vars.trans.date)), 32, vars.trans.date, FONT_MINI)
	
	-- draw Values
	lcd.drawText(255 - (lcd.getTextWidth(FONT_BIG, string.format("%0d:%02d:%02d", std, min, sec)) / 2), 13, string.format("%0d:%02d:%02d",
						std, min, sec), FONT_BIG)
	lcd.drawText(255, 32, string.format("%02d.%02d.%02d", today.day, today.mon, today.year), FONT_MINI)
end

-- Draw right middle box
local function drawRimidbox()	-- Used Capacity
    
	local total_used_capacity = math.ceil( used_capacity + (initial_capacity_percent_used * vars.capacity) / 100 )
	
	-- draw fixed Text
	lcd.drawText(262 - (lcd.getTextWidth(FONT_MINI,vars.trans.usedCapa) / 2),50,vars.trans.usedCapa,FONT_MINI)
	lcd.drawText(285, 81, "mAh", FONT_MINI)
	lcd.drawText(205, 97, vars.trans.capacity, FONT_MINI)
		
	-- draw Values
	lcd.drawText(282 - lcd.getTextWidth(FONT_MAXI, string.format("%.0f",total_used_capacity)),61, string.format("%.0f",
				total_used_capacity), FONT_MAXI)
	lcd.drawText(258,97, string.format("%s mAh", vars.capacity),FONT_MINI)
end

-- Draw right bottom box
local function drawRibotbox()	-- Some Max Values

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

local function drawMibotbox()
	
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
	
	local gyro_percent = gyro_channel_val * 60.606 + 63.6363
	
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


-- Flight time
local function FlightTime()

	local timeSw_val = system.getInputsVal(vars.timeSw)
	local resetSw_val = system.getInputsVal(vars.resSw)
	
	newTime = system.getTimeCounter()

	-- to be in sync with a system timer, do not use CLR key 
	if (resetSw_val == 1) then
		time = 0
	end

	if (timeSw_val ~= 1) then
		lastTime = newTime -- properly start of first interval
	end
	        
	if newTime >= (lastTime + 1000) then  -- one second
		lastTime = newTime
		if (timeSw_val == 1) then 
			time = time + 1
		end
	end

	std = math.floor(time / 3600)
	min = math.floor(time / 60) - std * 60
	sec = time % 60

	collectgarbage()
end

-- Count percentage from cell voltage
local function get_capacity_percent_used()
	result=0
	if(initial_cell_voltage > 4.2 or initial_cell_voltage < 3.00)then
		if(initial_cell_voltage > 4.2)then
			result=0
		end
		if(initial_cell_voltage < 3.00)then
			result=100
		end
	else
		for i,v in ipairs(percentList) do
			if ( v[1] >= initial_cell_voltage ) then
				result =  100 - v[2]
				break
			end
		end
	end
	collectgarbage()
	return result
end

-- Averaging function for smothing display of voltage 
function average(value)
    
	local sum_voltages = 0
	local i, voltage

	if ( #voltages_list == 5 ) then
		table.remove(voltages_list, 1)
	end    

	voltages_list[#voltages_list + 1] = value

	for i,voltage in ipairs(voltages_list) do
		sum_voltages = sum_voltages + voltage
	end

	collectgarbage()
	return sum_voltages / #voltages_list
end    

local function loop()
	
	local sensor
	local anCapaGo = system.getInputsVal(vars.anCapaSw)
	local anVoltGo = system.getInputsVal(vars.anVoltSw)
	local tickTime = system.getTime()

	FlightTime()

	gyro_channel_val = system.getInputs(vars.gyro_output)

	txtelemetry = system.getTxTelemetry()
	rx_voltage = txtelemetry.rx1Voltage
	-- rx_percent = txtelemetry.rx1Percent   -- signal quality not used
	rx_a1 = txtelemetry.RSSI[1]
	rx_a2 = txtelemetry.RSSI[2]

	-- Read Sensor Parameter Voltage 
	sensor = system.getSensorValueByID(vars.sensorId, vars.battery_voltage_param)
	
	if(sensor and sensor.valid ) then
		battery_voltage = sensor.value
		-- guess used capacity from voltage if we started with partially discharged battery 
		if (initial_voltage_measured == false) then
			if ( battery_voltage > 3 ) then
				initial_voltage_measured = true
				initial_cell_voltage = battery_voltage / vars.cell_count
				initial_capacity_percent_used = get_capacity_percent_used()
			end    
		end        

		-- calculate Min/Max
		if ( battery_voltage < minvtg and battery_voltage > 6 ) then minvtg = battery_voltage end
		if battery_voltage > maxvtg then maxvtg = battery_voltage end
		
		if newTime >= (last_averaging_time + 1000) then          -- one second period, newTime set from FlightTime()
			battery_voltage_average = average(battery_voltage)   -- average voltages over n samples
			last_averaging_time = newTime
		end
	else
		battery_voltage = 0
		initial_voltage_measured = false
	end
        
	-- Read Sensor Parameter Current 
	sensor = system.getSensorValueByID(vars.sensorId, vars.motor_current_param)
	if(sensor and sensor.valid) then
		motor_current = sensor.value
		-- calculate Min/Max
		if motor_current < mincur then mincur = motor_current end
		if motor_current > maxcur then maxcur = motor_current end
	else
		motor_current = 0
	end

	-- Read Sensor Parameter Rotor RPM
	sensor = system.getSensorValueByID(vars.sensorId, vars.rotor_rpm_param)
	if(sensor and sensor.valid) then
		rotor_rpm = sensor.value
		-- calculate Min/Max
		if rotor_rpm < minrpm then minrpm = rotor_rpm end
		if rotor_rpm > maxrpm then maxrpm = rotor_rpm end
	else
		rotor_rpm = 0
	end

	-- Read Sensor Parameter Used Capacity
	sensor = system.getSensorValueByID(vars.sensorId, vars.used_capacity_param)
	if(sensor and sensor.valid and (battery_voltage > 1.0)) then
		used_capacity = sensor.value

		if ( initial_voltage_measured == true ) then
			remaining_capacity_percent = math.floor( ( ( (vars.capacity - used_capacity) * 100) / vars.capacity ) - initial_capacity_percent_used)
			if remaining_capacity_percent < 0 then remaining_capacity_percent = 0 end
		end
            
		if ( remaining_capacity_percent <= vars.capacity_alarm_thresh and vars.capacity_alarm_voice ~= "..." and next_capacity_alarm < tickTime ) then
			system.messageBox(trans.capaWarn,2)
			system.playFile(vars.capacity_alarm_voice,AUDIO_QUEUE)
			next_capacity_alarm = tickTime + 4 -- battery percentage alarm every 3 second
		end
        
		if ( battery_voltage_average <= voltage_alarm_dec_thresh and vars.voltage_alarm_voice ~= "..." and next_voltage_alarm < tickTime ) then
			system.messageBox(trans.voltWarn,2)
			system.playFile(vars.voltage_alarm_voice,AUDIO_QUEUE)
		    next_voltage_alarm = tickTime + 4 -- battery voltage alarm every 3 second 
		end    
             
		if(anCapaGo == 1 and tickTime >= next_capacity_announcement) then
			system.playNumber(remaining_capacity_percent, 0, "%", "Capacity")
			next_capacity_announcement = tickTime + 10 -- say battery percentage every 10 seconds
		end

		if(anVoltGo == 1 and tickTime >= next_voltage_announcement) then
			system.playNumber(battery_voltage, 1, "V", "U Battery")
			next_voltage_announcement = tickTime + 10 -- say battery voltage every 10 seconds
		end
                 
		-- Set max/min percentage to 99/0 for drawing
		if( remaining_capacity_percent > 100 ) then remaining_capacity_percent = 100 end
		if( remaining_capacity_percent < 0 ) then remaining_capacity_percent = 0 end
	end	

	-- Read Sensor Parameter BEC Current
	sensor = system.getSensorValueByID(vars.sensorId, vars.bec_current_param)
	if(sensor and sensor.valid) then
		bec_current = sensor.value 
		if bec_current < minrxa then minrxa = bec_current end
		if bec_current > maxrxa then maxrxa = bec_current end
	else
		bec_current = 0
	end

	-- Read Sensor Parameter Governor PWM
	sensor = system.getSensorValueByID(vars.sensorId, vars.pwm_percent_param)
	if(sensor and sensor.valid) then
		pwm_percent = sensor.value
		if pwm_percent < minpwm then minpwm = pwm_percent end
		if pwm_percent > maxpwm then maxpwm = pwm_percent end
	else
		pwm_percent = 0
	end

	-- Read Sensor Parameter FET Temperature
	sensor = system.getSensorValueByID(vars.sensorId, vars.fet_temp_param)
	if(sensor and sensor.valid) then
		fet_temp = sensor.value 
		if fet_temp < mintmp then mintmp = fet_temp end
		if fet_temp > maxtmp then maxtmp = fet_temp end
	else
		fet_temp = 0
	end
	
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
	loop = loop,
	init = init,
}
