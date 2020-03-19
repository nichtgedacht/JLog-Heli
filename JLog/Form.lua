local sensor_label_list = {}
local sensor_id_list = {}
local sensor_param_lists = {}
local sensorIndex = 0
output_list = { "O1", "O2", "O3", "O4", "O5", "O6", "O7", "O8", "O9", "O10", "O11", "O12",
							"O13", "O14", "O15", "O16" }


local function make_lists (sensorId)
	if ( not sensor_id_list[1] ) then	-- sensors not yet checked or rebooted
		for i,sensor in ipairs(system.getSensors()) do
			if (sensor.param == 0) then	-- new multisensor/device
				sensor_label_list[#sensor_label_list + 1] = sensor.label	-- list presented in sensor select box
				sensor_id_list[#sensor_id_list + 1] = sensor.id				-- to get id from if sensor changed, same numeric indexing
				if (sensor.id == sensorId) then
					sensorIndex = #sensor_id_list
				end
				sensor_param_lists[#sensor_param_lists + 1] = {}			-- start new param list only containing label and unit as string
			else															-- subscript is number of param for current multisensor/device
				sensor_param_lists[#sensor_param_lists][sensor.param] = sensor.label .. "  " .. sensor.unit	-- list presented in param select box
			end
		end
	end	
end

local function setup(vars)

	make_lists(vars.sensorId)

	form.setTitle(vars.trans.title)

	form.addSpacer(318,7)

	form.addRow(1)
	form.addLabel({label=vars.trans.label0,font=FONT_BOLD})

	form.addRow(2)
	form.addLabel({label = vars.trans.labelp0, width=200})

	form.addSelectbox( sensor_label_list, sensorIndex, true,
						function (value)
							if ( not sensor_id_list[1] ) then	-- no device found
								return
							end
							vars.sensorId  = sensor_id_list[value]
							system.pSave("sensorId", vars.sensorId)
							sensorIndex = value

							vars.battery_voltage_param = 0 --default is "..."
							vars.motor_current_param = 0
							vars.rotor_rpm_param = 0
							vars.used_capacity_param = 0
							vars.bec_current_param = 0
							vars.pwm_percent_param = 0
							vars.fet_temp_param = 0

							form.reinit()
						end )

	if ( sensor_id_list and sensorIndex > 0 ) then

		form.addRow(2) 	
		form.addLabel({label = vars.trans.labelp1})
		form.addSelectbox(sensor_param_lists[sensorIndex], vars.battery_voltage_param, true,
							function (value)
								vars.battery_voltage_param = value
								system.pSave("battery_voltage_param", vars.battery_voltage_param)
							end )

		form.addRow(2) 	
		form.addLabel({label = vars.trans.labelp2})
		form.addSelectbox(sensor_param_lists[sensorIndex], vars.motor_current_param, true,
							function (value)
								vars.motor_current_param = value
								system.pSave("motor_current_param", vars.motor_current_param)
							end )

		form.addRow(2) 	
		form.addLabel({label = vars.trans.labelp3})
		form.addSelectbox(sensor_param_lists[sensorIndex], vars.rotor_rpm_param, true,
							function (value)
								vars.rotor_rpm_param = value
								system.pSave("rotor_rpm_param", vars.rotor_rpm_param)
							end )

		form.addRow(2) 	
		form.addLabel({label = vars.trans.labelp4})
		form.addSelectbox(sensor_param_lists[sensorIndex], vars.used_capacity_param, true,
							function (value)
								vars.used_capacity_param = value
								system.pSave("used_capacity_param", vars.used_capacity_param)
							end )

		form.addRow(2) 	
		form.addLabel({label = vars.trans.labelp5})
		form.addSelectbox(sensor_param_lists[sensorIndex], vars.bec_current_param, true,
							function (value)
								vars.bec_current_param = value
								system.pSave("bec_current_param", vars.bec_current_param)
							end )

		form.addRow(2) 	
		form.addLabel({label = vars.trans.labelp6})
		form.addSelectbox(sensor_param_lists[sensorIndex], vars.pwm_percent_param, true,
							function (value)
								vars.pwm_percent_param = value
								system.pSave("pwm_percent_param", vars.pwm_percent_param)
							end )

		form.addRow(2) 	
		form.addLabel({label = vars.trans.labelp7})
		form.addSelectbox(sensor_param_lists[sensorIndex], vars.fet_temp_param, true,
							function (value)
								vars.fet_temp_param = value
								system.pSave("fet_temp_param", vars.fet_temp_param)
							end )
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
						--	vars.voltage_alarm_dec_thresh = vars.voltage_alarm_thresh / 10
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
