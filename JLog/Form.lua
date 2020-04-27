local device_label_list = {}
local deviceId_list = {}
local sensor_lists = {}
local deviceIndex = 0
local show

output_list = { "O1", "O2", "O3", "O4", "O5", "O6", "O7", "O8", "O9", "O10", "O11", "O12",
							"O13", "O14", "O15", "O16" }

local function make_lists (deviceId)
	local sensor, i
	if ( not deviceId_list[1] ) then	-- sensors not yet checked or rebooted
		deviceIndex = 0
		for i,sensor in ipairs(system.getSensors()) do
			if (sensor.param == 0) then	-- new multisensor/device
				device_label_list[#device_label_list + 1] = sensor.label	-- list presented in sensor select box
				deviceId_list[#deviceId_list + 1] = sensor.id				-- to get id from if sensor changed, same numeric indexing
				if (sensor.id == deviceId) then
					deviceIndex = #deviceId_list
				end
				sensor_lists[#sensor_lists + 1] = {}						-- start new param list only containing label and unit as string
			else															-- subscript is number of param for current multisensor/device
				sensor_lists[#sensor_lists][sensor.param] = sensor.label .. "  " .. sensor.unit	-- list presented in param select box
				sensor_lists[#sensor_lists][sensor.param + 1] = "..."
			end
		end
		device_label_list[#device_label_list + 1] = "..."
	end
end

local function check_other_device(sens, deviceId)
	local i
	show = true
	if ( sens[1] ~= deviceId and sens[2] ~= 0 ) then	-- sensor selectet from another device 
		for i in next, deviceId_list do
			if ( sens[1] == deviceId_list[i] ) then	-- this other device is still present
				show = false
			end	
		end	
	end
end	

local function setup(vars)

	make_lists(vars.deviceId)

	form.setTitle(vars.trans.title)

	form.addSpacer(318,7)

	form.addRow(1)
	form.addLabel({label=vars.trans.label0,font=FONT_BOLD})

	form.addRow(2)
	form.addLabel({label = vars.trans.labelp0, width=200})

	form.addSelectbox( device_label_list, deviceIndex, true,
						function (value)
							if ( not deviceId_list[1] ) then	-- no device found
								return
							end
							if (device_label_list[value] == "...") then
								vars.deviceId = 0
								deviceIndex = 0
							else
								vars.deviceId  = deviceId_list[value]
								deviceIndex = value
							end
							system.pSave("deviceId", vars.deviceId)
							form.reinit()
						end )
		
	if ( deviceId_list and deviceIndex > 0 ) then

		form.addRow(2) 	
		form.addLabel({label = vars.trans.labelp1})
		check_other_device(vars.battery_voltage_sens, vars.deviceId)
		form.addSelectbox(sensor_lists[deviceIndex], vars.battery_voltage_sens[2], true,
							function (value)
								if sensor_lists[deviceIndex][value] == "..." then
									value = 0
								end
								vars.battery_voltage_sens[1] = vars.deviceId
								vars.battery_voltage_sens[2] = value 
								system.pSave("battery_voltage_sens", vars.battery_voltage_sens)
							end,
							{enabled=show, visible=show} )

		form.addRow(2) 	
		form.addLabel({label = vars.trans.labelp2})
		check_other_device(vars.motor_current_sens, vars.deviceId)
		form.addSelectbox(sensor_lists[deviceIndex], vars.motor_current_sens[2], true,
							function (value)
								if sensor_lists[deviceIndex][value] == "..." then
									value = 0
								end
								vars.motor_current_sens[1] = vars.deviceId
								vars.motor_current_sens[2] = value
								system.pSave("motor_current_sens", vars.motor_current_sens)
							end,
							{enabled=show, visible=show} )

		form.addRow(2) 	
		form.addLabel({label = vars.trans.labelp3})
		check_other_device(vars.rotor_rpm_sens, vars.deviceId)
		form.addSelectbox(sensor_lists[deviceIndex], vars.rotor_rpm_sens[2], true,
							function (value)
								if sensor_lists[deviceIndex][value] == "..." then
									value = 0
								end
								vars.rotor_rpm_sens[1] = vars.deviceId
								vars.rotor_rpm_sens[2] = value
								system.pSave("rotor_rpm_sens", vars.rotor_rpm_sens)
							end,
							{enabled=show, visible=show} )

		form.addRow(2) 	
		form.addLabel({label = vars.trans.labelp4})
		check_other_device(vars.used_capacity_sens, vars.deviceId)
		form.addSelectbox(sensor_lists[deviceIndex], vars.used_capacity_sens[2], true,
							function (value)
								if sensor_lists[deviceIndex][value] == "..." then
									value = 0
								end
								vars.used_capacity_sens[1] = vars.deviceId
								vars.used_capacity_sens[2] = value
								system.pSave("used_capacity_sens", vars.used_capacity_sens)
							end,
							{enabled=show, visible=show} )

		form.addRow(2) 	
		form.addLabel({label = vars.trans.labelp5})
		check_other_device(vars.bec_current_sens, vars.deviceId)
		form.addSelectbox(sensor_lists[deviceIndex], vars.bec_current_sens[2], true,
							function (value)
								if sensor_lists[deviceIndex][value] == "..." then
									value = 0
								end
								vars.bec_current_sens[1] = vars.deviceId
								vars.bec_current_sens[2] = value
								system.pSave("bec_current_sens", vars.bec_current_sens)
							end,
							{enabled=show, visible=show} )

		form.addRow(2) 	
		form.addLabel({label = vars.trans.labelp6})
		check_other_device(vars.pwm_percent_sens, vars.deviceId)
		form.addSelectbox(sensor_lists[deviceIndex], vars.pwm_percent_sens[2], true,
							function (value)
								if sensor_lists[deviceIndex][value] == "..." then
									value = 0
								end
								vars.pwm_percent_sens[1] = vars.deviceId
								vars.pwm_percent_sens[2] = value
								system.pSave("pwm_percent_sens", vars.pwm_percent_sens)
							end,
							{enabled=show, visible=show} )

		form.addRow(2) 	
		form.addLabel({label = vars.trans.labelp7})
		check_other_device(vars.fet_temp_sens, vars.deviceId)
		form.addSelectbox(sensor_lists[deviceIndex], vars.fet_temp_sens[2], true,
							function (value)
								if sensor_lists[deviceIndex][value] == "..." then
									value = 0
								end
								vars.fet_temp_sens[1] = vars.deviceId
								vars.fet_temp_sens[2] = value
								system.pSave("fet_temp_sens", vars.fet_temp_sens)
							end,
							{enabled=show, visible=show} )
	end
	
	form.addRow(1)
	form.addLabel({label=vars.trans.label1,font=FONT_BOLD})

	form.addRow(2)
	form.addLabel({label=vars.trans.anCapaSw, width=220})
	form.addInputbox(vars.anCapaSw,true,
						function (value)
							vars.anCapaSw = value
							system.pSave("anCapaSw", vars.anCapaSw)
						end )

	form.addRow(2)
	form.addLabel({label=vars.trans.anVoltSw, width=220})
	form.addInputbox(vars.anVoltSw,true,
						function (value)
							vars.anVoltSw = value
							system.pSave("anVoltSw", vars.anVoltSw)
						end )
        
	form.addSpacer(318,7)

	form.addRow(1)
	form.addLabel({label=vars.trans.label3,font=FONT_BOLD})

	form.addRow(2)
	form.addLabel({label=vars.trans.voltAlarmVoice, width=140})
	form.addAudioFilebox(vars.voltage_alarm_voice,
						function (value)
							vars.voltage_alarm_voice=value
							system.pSave("voltage_alarm_voice", vars.voltage_alarm_voice)
						end )
        
	form.addRow(2)
	form.addLabel({label=vars.trans.capaAlarmVoice, width=140})
	form.addAudioFilebox(vars.capacity_alarm_voice,
						function (value)
							vars.capacity_alarm_voice = value
							system.pSave("capacity_alarm_voice", vars.capacity_alarm_voice)
						end )

	form.addSpacer(318,7)

	form.addRow(1)
	form.addLabel({label=vars.trans.label2,font=FONT_BOLD})

	form.addRow(2)
	form.addLabel({label=vars.trans.capacitymAh, width=210})
	form.addIntbox(vars.capacity, 0, 32767, 0, 0, 10,
						function (value)
							vars.capacity = value
							system.pSave("capacity", vars.capacity)
						end, {label=" mAh"} )

	form.addRow(2)
	form.addLabel({label=vars.trans.cellcnt, width=210})
	form.addIntbox(vars.cell_count, 1, 12, 1, 0, 1,
						function (value)
							vars.cell_count = value
							system.pSave("cell_count", vars.cell_count)
						end, {label=" S"} )

	form.addRow(2)
	form.addLabel({label=vars.trans.capaAlarmThresh, width=210 })
	form.addIntbox(vars.capacity_alarm_thresh, 0, 100, 0, 0, 1,
						function (value)
							vars.capacity_alarm_thresh = value
							system.pSave("capacity_alarm_thresh", vars.capacity_alarm_thresh)
						end, {label=" %"} )
    
	form.addRow(2)
	form.addLabel({label=vars.trans.voltAlarmThresh, width=210})
	form.addIntbox(vars.voltage_alarm_thresh,0,1000,0,1,1,
						function (value)
							vars.voltage_alarm_thresh=value
							system.pSave("voltage_alarm_thresh", vars.voltage_alarm_thresh)
						end, {label=" V"} )

	form.addSpacer(318,7)

	form.addRow(1)
	form.addLabel({label=vars.trans.label4,font=FONT_BOLD})

	form.addRow(2)
	form.addLabel({label=vars.trans.timeSw, width=210})
	form.addInputbox(vars.timeSw,true,
						function (value)
							vars.timeSw = value
							system.pSave("timeSw", vars.timeSw)
						end )

	form.addRow(2)
	form.addLabel({label=vars.trans.resSw, width=210})
	form.addInputbox(vars.resSw,true,
						function (value)
							vars.resSw = value
							system.pSave("resSw", vars.resSw)
						end )

	form.addSpacer(318,7)

	form.addRow(1)
	form.addLabel({label=vars.trans.label5,font=FONT_BOLD})

	form.addRow(2)
	form.addLabel({label=vars.trans.channel, width=210})
	form.addIntbox(vars.gyChannel,1,16,6,0,1,
						function (value)
							vars.gyChannel = value
							vars.gyro_output = output_list[vars.gyChannel]
							system.pSave("gyChannel", vars.gyChannel)
							system.pSave("gyro_output", vars.gyro_output)
						end )

	form.addSpacer(318,7)

	form.addRow(1)
	form.addLabel({label=vars.trans.appName .. " " .. Version .. " ", font=FONT_MINI, alignRight=true})
    
	collectgarbage()

	return (vars)
end

return {

	setup = setup

}
