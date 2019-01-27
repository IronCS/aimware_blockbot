local font_icon = draw.CreateFont("Webdings", 30, 30)

-- Script --------
local cur_scriptname = GetScriptName()
local cur_version = "1.1"
local git_version = "https://raw.githubusercontent.com/itisluiz/aimware_blockbot/master/version.txt"
local git_repository = "https://raw.githubusercontent.com/itisluiz/aimware_blockbot/master/blockbot.lua"
------------------

-- UI Elements --
local ref_msc_auto_other = gui.Reference("MISC", "AUTOMATION", "Other")

local gb_blockbot = gui.Groupbox(ref_msc_auto_other, "Block Bot by Nyanpasu!", 0, 80, 213, 100)

local key_blockbot = gui.Keybox(gb_blockbot, "msc_blockbot", "Block Bot", 0)
local cob_blockbot_mode = gui.Combobox(gb_blockbot, "msc_blockbot_mode", "Mode", "Match Speed", "Maximum Speed")
-----------------

-- Check for updates
local function git_update()
	if cur_version ~= http.Get(git_version) then
		if not gui.GetValue("lua_allow_cfg") then
			print("[Update] " .. cur_scriptname .. " is outdated. Please enable Lua Allow Config and Lua Editing under Settings")
		else
			local this_script = file.Open(cur_scriptname, "w")
			this_script:Write(http.Get(git_repository))
			this_script:Close()
			print("[Update] " .. cur_scriptname .. " has updated itself from version " .. cur_version .. " to " .. http.Get(git_version))
			print("[Update] Please reload " .. cur_scriptname)
		end
	else
		print("[Update] " .. cur_scriptname .. " is up-to-date")
	end
end

if gui.GetValue("lua_allow_http") then
	git_update()
else
	print("[Update] Please enable Lua HTTP to check for updates")
end

-- Some functions from EssentialsNP file so that the script can stay standalone
local function vector3_subtract(input0, input1) 
	-- Subtracts vector input1 from input0
	return {input0[1] - input1[1], input0[2] - input1[2], input0[3] - input1[3]};
end
	
local function vector3_hypotenuse(input0, input1) 
	-- Gets the hypotenuse between input0 and input1
	local vectorDelta = vector3_subtract(input0, input1);
	
	return math.sqrt(vectorDelta[1] ^ 2 + vectorDelta[2] ^ 2 + vectorDelta[3] ^ 2);	
end

local function vector3_getangles(input0, input1) 
	-- Gets the pitch and yaw needed to aim from input1 to input0.
	local vectorDelta = vector3_subtract(input0, input1);
	local hypotenuse = vector3_hypotenuse(input0, input1);
	
	local AngX = math.asin(vectorDelta[3]/hypotenuse) * -(180/math.pi);
	local AngY = math.atan(vectorDelta[2]/vectorDelta[1]) * (180/math.pi);
	
	if vectorDelta[1] <= 0 then
		AngY = AngY + 180;
	end
	if AngY > 180 then
		AngY = AngY - 360
	end
	
	return {AngX, AngY};
end

-- Shared Variables
local Target = nil
local LocalPlayer = nil

local function DrawingCallback()

	LocalPlayer = entities.GetLocalPlayer()
	
	if LocalPlayer == nil then
		return
	end
	
	if (key_blockbot:GetValue() == nil or key_blockbot:GetValue() == 0) or not LocalPlayer:IsAlive() then
		return
	end

	if input.IsButtonDown(key_blockbot:GetValue()) and Target == nil then

		for Index, Entity in pairs(entities.FindByClass("CCSPlayer")) do
			if Entity:GetIndex() ~= LocalPlayer:GetIndex() and Entity:IsAlive() then
				if Target == nil then		
					Target = Entity;
				elseif vector3_hypotenuse({LocalPlayer:GetAbsOrigin()}, {Target:GetAbsOrigin()}) > vector3_hypotenuse({LocalPlayer:GetAbsOrigin()}, {Entity:GetAbsOrigin()}) then
					Target = Entity;
				end
			end
		end
		
	elseif not input.IsButtonDown(key_blockbot:GetValue()) then
		Target = nil
	end

	if Target ~= nil then
		local NearPlayer_toScreen = {client.WorldToScreen(Target:GetBonePosition(3))}
		draw.SetFont(font_icon)
		draw.Color(255, 0, 0, 255);
		if NearPlayer_toScreen[1] ~= nil and NearPlayer_toScreen[2] ~= nil then
			draw.TextShadow(NearPlayer_toScreen[1] - select(1, draw.GetTextSize("x")) / 2, NearPlayer_toScreen[2], "x")
		end
		
	end
	
end

local function CreateMoveCallback(UserCmd)
	
	if Target ~= nil then
		local LocalAngles = {UserCmd:GetViewAngles()}
		local AimAngles = vector3_getangles({Target:GetAbsOrigin()}, {LocalPlayer:GetAbsOrigin()})
		
		local DiffYaw = AimAngles[2] - LocalAngles[2]

		if DiffYaw > 180 then
			DiffYaw = DiffYaw - 360
		elseif DiffYaw < -180 then
			DiffYaw = DiffYaw + 360
		end
		
		if cob_blockbot_mode:GetValue() == 0 then
			if math.abs(DiffYaw) > 0.75 then
				UserCmd:SetSideMove(450 * -DiffYaw)
			end
		elseif cob_blockbot_mode:GetValue() == 1 then
			if DiffYaw > 0.25 then
				UserCmd:SetSideMove(-450)
			elseif DiffYaw < -0.25 then
				UserCmd:SetSideMove(450)
			end
		end
	end
	
end

callbacks.Register("Draw", DrawingCallback)
callbacks.Register("CreateMove", CreateMoveCallback)