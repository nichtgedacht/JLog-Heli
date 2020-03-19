--[[
	----------------------------------------------------------------------------
	App using JLog(2.6 or 32) Sensor Data from motor control for helicopter usage
	----------------------------------------------------------------------------
	MIT License
   
	Hiermit wird unentgeltlich jeder Person, die eine Kopie der Software und der
	zugehörigen Dokumentationen (die "Software") erhält, die Erlaubnis erteilt,
	sie uneingeschränkt zu nutzen, inklusive und ohne Ausnahme mit dem Recht, sie
	zu verwenden, zu kopieren, zu verändern, zusammenzufügen, zu veröffentlichen,
	zu verbreiten, zu unterlizenzieren und/oder zu verkaufen, und Personen, denen
	diese Software überlassen wird, diese Rechte zu verschaffen, unter den
	folgenden Bedingungen: 
	Der obige Urheberrechtsvermerk und dieser Erlaubnisvermerk sind in allen Kopien
	oder Teilkopien der Software beizulegen. 
	DIE SOFTWARE WIRD OHNE JEDE AUSDRÜCKLICHE ODER IMPLIZIERTE GARANTIE BEREITGESTELLT,
	EINSCHLIEßLICH DER GARANTIE ZUR BENUTZUNG FÜR DEN VORGESEHENEN ODER EINEM
	BESTIMMTEN ZWECK SOWIE JEGLICHER RECHTSVERLETZUNG, JEDOCH NICHT DARAUF BESCHRÄNKT.
	IN KEINEM FALL SIND DIE AUTOREN ODER COPYRIGHTINHABER FÜR JEGLICHEN SCHADEN ODER
	SONSTIGE ANSPRÜCHE HAFTBAR ZU MACHEN, OB INFOLGE DER ERFÜLLUNG EINES VERTRAGES,
	EINES DELIKTES ODER ANDERS IM ZUSAMMENHANG MIT DER SOFTWARE ODER SONSTIGER
	VERWENDUNG DER SOFTWARE ENTSTANDEN. 
	----------------------------------------------------------------------------


	nichtgedacht Version History:
	V1.0 initial release

--]]

--[[
Jlog2.6 Telemetry Parameters (Number is Sensor Parameter, quoted Text is Parameter Label):
                                                                                                                                          
Basis                                                                                                                                     
1 “U battery”   nn.n    V   (Akkuspannung)
2 “I motor”     nnn.n   A   (Motorstrom)
3 “RPM uni”     nnnn    rpm (Rotordrehzahl)
4 “mAh”         nnnnn   mAh (verbrauchte Kapazität)
5 “U bec”       n.n     V   (BEC-Ausgangsspannung)
6 “I bec”       nn.n    A   (BEC-Ausgangsstrom)
7 “Throttle”    nnn     %   (Gas 0..100%)
8 “PWM”         nnn     %   (Stelleraussteuerung 0..100%)
9 “Temp         nnn     °C  (Temperatur der Leistungs-FETs (Endstufe), bisher “TempPA” genannt)

+

Configuration 0 setup by JLC5 (Standard):
10 “extTemp1″   [-]nn.n     °C (JLog-eigener (Steller-externer) Temperatursensor 1 (1/5))
11 “extTemp2″   [-]nn.n     °C (JLog-eigener (Steller-externer) Temperatursensor 2 (2/5))
12 “extRPM”     nnnnn       rpm (JLog-eigener (Steller-externer) Drehzahlsensor)
13 “Speed”      nnn         km/h (JLog-eigener Sensor, Prandtl-Sonde (Staurohr) SM#2560)
14 “MaxSpd”     nnn         km/h (Maximalgeschwindigkeit)
15 “RPM mot”    nnnnn       rpm (Motordrehzahl)

or Configuration 1 (selected config) setup by JLC5 (Min/Max-Werte):
10 “RPM mot”    nnnnn   rpm (Motordrehzahl)
11 “Ubat Min”   nn.n    V   (Akkuminimalspannung)
12 “Ubec Min”   n.n     V   (BEC-Minimalspannung)
13 “Imot Max”   nnn.n   A   (Motormaximalstrom)
14 “Ibec Max”   nn.n    A   (BEC-Maximalstrom)
15 “Power Max”  nnnnn   W   (Maximalleistung)
--]]


collectgarbage()
--------------------------------------------------------------------------------
local initial_voltage_measured = false
local initial_capacity_percent_used = 0
local initial_cell_voltage
local model, owner = " ", " "
local trans, anCapaGo, anVoltGo
local battery_voltage, battery_voltage_average, motor_current, rotor_rpm, used_capacity, rx_voltage = 0.0, 0.0, 0.0, 0, 0, 0.00
local bec_current, pwm_percent, fet_temp = 0, 0, 0
local remaining_capacity_percent, minpwm, maxpwm = 100, 0, 0
local minrpm, maxrpm, mincur, maxcur = 999, 0, 99.9, 0
local minvtg, maxvtg, mintmp, maxtmp = 99, 0, 99, 0
local std, min, sec = 0, 0, 0
local time, newTime, lastTime = 0, 0, 0
local minrxv, maxrxv, minrxa, maxrxa = 9.9, 0.0, 9.9, 0.0
local next_capacity_announcement, next_voltage_announcement, tickTime = 0, 0, 0
local next_capacity_alarm, next_voltage_alarm = 0, 0
local last_averaging_time = 0
local voltage_alarm_dec_thresh
local voltages_list = {}
--local rx_percent = 0 -- signal quality, not used
local rx_a1, rx_a2 = 0, 0
--local mem, maxmem = 0, 0 -- for debug only
local goregisterTelemetry = nil
local setupvars = {}
local gyro_channel = 0 -- stores value of selected servo output "OXX" used for GY

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
                   
-- Read translations
local function setLanguage()
	local lng=system.getLocale()
	local file = io.readall("Apps/Lang/JLog.jsn")
	local obj = json.decode(file)
	if(obj) then
		trans = obj[lng] or obj[obj.default]
	end
end

-- Telemetry Window
local function Window(width, height)

	Screen.drawBattery(remaining_capacity_percent, setupvars.capacity_alarm_thresh)
	Screen.drawLetopbox(trans, battery_voltage_average, minvtg, maxvtg)
	Screen.drawLemidbox(trans, rotor_rpm, minrpm, maxrpm)
	Screen.drawLebotbox(motor_current, rx_a1, rx_a2, rx_voltage)
	Screen.drawRitopbox(trans, std, min, sec, today)
	Screen.drawRimidbox(trans, used_capacity, initial_capacity_percent_used, setupvars.capacity)
	Screen.drawRibotbox(maxrxa, maxcur, maxpwm, maxtmp)
	Screen.drawMibotbox(gyro_channel)
	Screen.drawSeparators()
	
end

-- remove unused module
local function unrequire(module)
	package.loaded[module] = nil
	_G[module] = nil
end

-- switch to setup context
local function setupForm(formID)

	Screen = nil
	unrequire("JLog/Screen")
	system.unregisterTelemetry(1)
	collectgarbage()

	Form = require "JLog/Form"

	-- return data from user
	setupvars = Form.setup(setupvars)

	voltage_alarm_dec_thresh = setupvars.voltage_alarm_thresh / 10

	collectgarbage()
end

-- switch to telemetry context
local function closeForm()

	Form = nil
	unrequire("JLog/Form")
	Screen = require "JLog/Screen"
	collectgarbage()

	-- register telemetry window again after 500 ms
	goregisterTelemetry = newTime + 500 -- used in loop()

end

-- Flight time
local function FlightTime()

	local timeSw_val = system.getInputsVal(setupvars.timeSw)
	local resetSw_val = system.getInputsVal(setupvars.resSw)
	
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

-- main loop
local function loop()
	
	local anCapaGo = system.getInputsVal(setupvars.anCapaSw)
	local anVoltGo = system.getInputsVal(setupvars.anVoltSw)
	local tickTime = system.getTime()

	FlightTime()

	gyro_channel = system.getInputs(setupvars.gyro_output)

	txtelemetry = system.getTxTelemetry()
	rx_voltage = txtelemetry.rx1Voltage
	-- rx_percent = txtelemetry.rx1Percent   -- signal quality not used
	rx_a1 = txtelemetry.RSSI[1]
	rx_a2 = txtelemetry.RSSI[2]

	-- Read Sensor Parameter Voltage 
	sensor = system.getSensorValueByID(setupvars.sensorId, setupvars.battery_voltage_param)

	if(sensor and sensor.valid ) then
		battery_voltage = sensor.value
		-- TRY TRY
	--if(sensor) then
	--	battery_voltage = 19
		if (initial_voltage_measured == false) then
			if ( battery_voltage > 3 ) then
				initial_voltage_measured = true
				initial_cell_voltage = battery_voltage / setupvars.cell_count
				initial_capacity_percent_used = get_capacity_percent_used()
			end    
		end        

		-- calculate Min/Max Sensor 1
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
	sensor = system.getSensorValueByID(setupvars.sensorId, setupvars.motor_current_param)
	if(sensor and sensor.valid) then
		motor_current = sensor.value
		-- calculate Min/Max Sensor 2
		if motor_current < mincur then mincur = motor_current end
		if motor_current > maxcur then maxcur = motor_current end
	else
		motor_current = 0
	end

	-- Read Sensor Parameter Rotor RPM
	sensor = system.getSensorValueByID(setupvars.sensorId, setupvars.rotor_rpm_param)
	if(sensor and sensor.valid) then
		rotor_rpm = sensor.value
		-- calculate Min/Max Sensor 3
		if rotor_rpm < minrpm then minrpm = rotor_rpm end
		if rotor_rpm > maxrpm then maxrpm = rotor_rpm end
	else
		rotor_rpm = 0
	end

	-- Read Sensor Parameter Used Capacity
	sensor = system.getSensorValueByID(setupvars.sensorId, setupvars.used_capacity_param)

	if(sensor and sensor.valid and (battery_voltage > 1.0)) then
		used_capacity = sensor.value

		if ( initial_voltage_measured == true ) then
			remaining_capacity_percent = math.floor( ( ( (setupvars.capacity - used_capacity) * 100) / setupvars.capacity ) - initial_capacity_percent_used)
			if remaining_capacity_percent < 0 then remaining_capacity_percent = 0 end
		end
            
		if ( remaining_capacity_percent <= setupvars.capacity_alarm_thresh and setupvars.capacity_alarm_voice ~= "..." and next_capacity_alarm < tickTime ) then
			system.messageBox(trans.capaWarn,2)
			system.playFile(setupvars.capacity_alarm_voice,AUDIO_QUEUE)
			next_capacity_alarm = tickTime + 4 -- battery percentage alarm every 3 second
		end
        
		if ( battery_voltage_average <= voltage_alarm_dec_thresh and setupvars.voltage_alarm_voice ~= "..." and next_voltage_alarm < tickTime ) then
			system.messageBox(trans.voltWarn,2)
			system.playFile(setupvars.voltage_alarm_voice,AUDIO_QUEUE)
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

	-- Read Sensor Parameter 6 BEC Current
	sensor = system.getSensorValueByID(setupvars.sensorId, setupvars.bec_current_param)
	if(sensor and sensor.valid) then
		bec_current = sensor.value 
		if bec_current < minrxa then minrxa = bec_current end
		if bec_current > maxrxa then maxrxa = bec_current end
	else
		bec_current = 0
	end

	-- Read Sensor Parameter Governor PWM
	sensor = system.getSensorValueByID(setupvars.sensorId, setupvars.pwm_percent_param)
	if(sensor and sensor.valid) then
		pwm_percent = sensor.value
		if pwm_percent < minpwm then minpwm = pwm_percent end
		if pwm_percent > maxpwm then maxpwm = pwm_percent end
	else
		pwm_percent = 0
	end

	-- Read Sensor Parameter FET Temperature
	sensor = system.getSensorValueByID(setupvars.sensorId, setupvars.fet_temp_param)
	if(sensor and sensor.valid) then
		fet_temp = sensor.value 
		if fet_temp < mintmp then mintmp = fet_temp end
		if fet_temp > maxtmp then maxtmp = fet_temp end
	else
		fet_temp = 0
	end

	if ( goregisterTelemetry and goregisterTelemetry <= newTime ) then
		system.registerTelemetry(1, trans.appName .. "   " .. model, 4, Window)
		goregisterTelemetry = nil
	end

	-- debug, memory usage
	--mem = math.modf(collectgarbage("count")) + 1
	--if ( maxmem < mem ) then
	--	maxmem = mem
	--	print (maxmem)
	--end

	collectgarbage()

end

-- init all
local function init(code1)

	model = system.getProperty("Model")
	owner = system.getUserName()
	today = system.getDateTime()	

	setupvars.sensorId = system.pLoad("sensorId", 0)
	setupvars.battery_voltage_param = system.pLoad("battery_voltage_param", 0)
	setupvars.motor_current_param = system.pLoad("motor_current_param", 0)
	setupvars.rotor_rpm_param = system.pLoad("rotor_rpm_param", 0)
	setupvars.used_capacity_param = system.pLoad("used_capacity_param", 0)
	setupvars.bec_current_param = system.pLoad("bec_current_param", 0)
	setupvars.pwm_percent_param = system.pLoad("pwm_percent_param", 0)
	setupvars.fet_temp_param = system.pLoad("fet_temp_param", 0)

	setupvars.anCapaSw = system.pLoad("anCapaSw")
	setupvars.anVoltSw = system.pLoad("anVoltSw")
	setupvars.voltage_alarm_voice = system.pLoad("voltage_alarm_voice", "...")
	setupvars.capacity_alarm_voice = system.pLoad("capacity_alarm_voice", "...")
	setupvars.capacity = system.pLoad("capacity",0)
	setupvars.cell_count = system.pLoad("cell_count",0)
	setupvars.capacity_alarm_thresh = system.pLoad("capacity_alarm_thresh", 0)
	setupvars.voltage_alarm_thresh = system.pLoad("voltage_alarm_thresh", 0)
	setupvars.timeSw = system.pLoad("timeSw")
	setupvars.resSw = system.pLoad("resSw")
	setupvars.gyChannel = system.pLoad("gyChannel", 1) -- going to form only
	setupvars.gyro_output = system.pLoad("gyro_output", 0) -- coming from form only

	voltage_alarm_dec_thresh = setupvars.voltage_alarm_thresh / 10	
	setupvars.trans = trans

	system.registerForm(1, MENU_APPS, trans.appName, setupForm, nil, nil, closeForm)
	system.registerTelemetry(1, trans.appName .. "   " .. model, 4, Window) -- registers a full size Window

	unrequire("wifi")	-- there is no hardware present for this module
	--unrequire("io")	-- can be unloaded if no other App loaded uses file IO 

	Screen = require "JLog/Screen"

	-- debug, loaded modules
	--local i, p
	--for i, p in pairs(package.loaded) do
	--	print (i, p)
	--end	

	collectgarbage()
end
--------------------------------------------------------------------------------
Version = "1.1"
setLanguage()
collectgarbage()
return {init=init, loop=loop, author="Nichtgedacht", version=Version, name=trans.appName}
