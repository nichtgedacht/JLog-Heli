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
	V1.1 changed scope of some vars, minor change in flight timer
	v2.0 moved most part of loop to screen module

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
local model, owner = " ", " "
local trans
local mem, maxmem = 0, 0 -- for debug only
local goregisterTelemetry = nil
local setupvars = {}

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
	
	Screen.drawBattery()
	Screen.drawLetopbox()
	Screen.drawLemidbox()
	Screen.drawLebotbox()
	Screen.drawRitopbox()
	Screen.drawRimidbox()
	Screen.drawRibotbox()
	Screen.drawMibotbox()
	Screen.drawSeparators()
	
end

-- remove unused module
local function unrequire(module)
	package.loaded[module] = nil
	_G[module] = nil
end

-- switch to setup context
local function setupForm(formID)

	Screen = nil					-- comment out if closeForm not available
	unrequire("JLog/Screen")		-- comment out if closeForm not available
	system.unregisterTelemetry(1)	-- comment out if closeForm not available
	
	collectgarbage()

	Form = require "JLog/Form"

	-- return modified data from user
	setupvars = Form.setup(setupvars)

	collectgarbage()
end

-- switch to telemetry context
local function closeForm()

	Form = nil
	unrequire("JLog/Form")
	
	collectgarbage()
	
	--Screen = require "JLog/Screen"
	--Screen.init(setupvars)

	-- register telemetry window again after 500 ms
	goregisterTelemetry = 500 + system.getTimeCounter() -- used in loop()
	
	collectgarbage()

end


-- main loop
local function loop()
	
	-- code of loop from screen module
	if ( Screen ~= nil ) then
		Screen.loop()
	end

	-- register telemetry display again after form was closed 
	if ( goregisterTelemetry and system.getTimeCounter() > goregisterTelemetry ) then
		
		Screen = require "JLog/Screen"
		Screen.init(setupvars)
		
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

	setupvars.trans = trans

	system.registerForm(1, MENU_APPS, trans.appName, setupForm, nil, nil, closeForm)
	system.registerTelemetry(1, trans.appName .. "   " .. model, 4, Window) -- registers a full size Window

	unrequire("wifi")	-- there is no hardware present for this module
	--unrequire("io")	-- can be unloaded if no other App loaded uses file IO 

	Screen = require "JLog/Screen"
	Screen.init(setupvars)

	-- debug, loaded modules
	--local i, p
	--for i, p in pairs(package.loaded) do
	--	print (i, p)
	--end	

	collectgarbage()
end
--------------------------------------------------------------------------------
Version = "2.0"
setLanguage()
collectgarbage()
return {init=init, loop=loop, author="Nichtgedacht", version=Version, name=trans.appName}
