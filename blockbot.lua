local font_icon = draw.CreateFont("Webdings", 30, 30)

-- Script --------
local cur_scriptname = GetScriptName()
local cur_version = "1.2"
local git_version = "https://raw.githubusercontent.com/itisluiz/aimware_blockbot/master/version.txt"
local git_repository = "https://raw.githubusercontent.com/itisluiz/aimware_blockbot/master/blockbot.lua"
------------------

-- UI Elements --
local ref_msc_auto_other = gui.Reference("MISC", "AUTOMATION", "Other")

local gb_blockbot = gui.Groupbox(ref_msc_auto_other, "Block Bot by Nyanpasu!", 0, 80, 213, 120)

local key_blockbot = gui.Keybox(gb_blockbot, "msc_blockbot", "Block Bot", 0)
local cob_blockbot_mode = gui.Combobox(gb_blockbot, "msc_blockbot_mode", "Mode", "Match Speed", "Maximum Speed")
local chb_blockbot_retreat = gui.Checkbox(gb_blockbot, "chb_blockbot_retreat", "Retreat on BunnyHop", 0)
-----------------

-- Check for updates
local function git_update()
	if cur_version ~= http.Get(git_version) then
		if not gui.GetValue("lua_allow_cfg") then
			print("[Update] " .. cur_scriptname .. " is outdated. Please enable Lua Allow Config and Lua Editing under Settings")
			print(http.Get(git_version))
			print(cur_version)
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

-- Shared Variables
local Target = nil
local CrouchBlock = false
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
				elseif vector.Distance({LocalPlayer:GetAbsOrigin()}, {Target:GetAbsOrigin()}) > vector.Distance({LocalPlayer:GetAbsOrigin()}, {Entity:GetAbsOrigin()}) then
					Target = Entity;
				end
			end
		end
		
	elseif not input.IsButtonDown(key_blockbot:GetValue()) or not Target:IsAlive() then
		Target = nil
	end

	if Target ~= nil then
		local NearPlayer_toScreen = {client.WorldToScreen(Target:GetBonePosition(5))}
		
		if select(3, Target:GetHitboxPosition(0)) < select(3, LocalPlayer:GetAbsOrigin()) and vector.Distance({LocalPlayer:GetAbsOrigin()}, {Target:GetAbsOrigin()}) < 100 then
			CrouchBlock = true
			draw.Color(255, 255, 0, 255)
		else
			draw.Color(255, 0, 0, 255)
		end
		
		draw.SetFont(font_icon)
		
		if NearPlayer_toScreen[1] ~= nil and NearPlayer_toScreen[2] ~= nil then
			draw.TextShadow(NearPlayer_toScreen[1] - select(1, draw.GetTextSize("x")) / 2, NearPlayer_toScreen[2], "x")
		end
		
	end
	
end

local function CreateMoveCallback(UserCmd)
	
	if Target ~= nil then
		local LocalAngles = {UserCmd:GetViewAngles()}
		local VecForward = {vector.Subtract( {Target:GetAbsOrigin()},  {LocalPlayer:GetAbsOrigin()} )}
		local AimAngles = {vector.Angles( VecForward )}
		local TargetSpeed = vector.Length(Target:GetPropFloat("localdata", "m_vecVelocity[0]"), Target:GetPropFloat("localdata", "m_vecVelocity[1]"), Target:GetPropFloat("localdata", "m_vecVelocity[2]"))
		
		if CrouchBlock then
			if cob_blockbot_mode:GetValue() == 0 then
				UserCmd:SetForwardMove( ( (math.sin(math.rad(LocalAngles[2]) ) * VecForward[2]) + (math.cos(math.rad(LocalAngles[2]) ) * VecForward[1]) ) * 10 )
				UserCmd:SetSideMove( ( (math.cos(math.rad(LocalAngles[2]) ) * -VecForward[2]) + (math.sin(math.rad(LocalAngles[2]) ) * VecForward[1]) ) * 10 )
			elseif cob_blockbot_mode:GetValue() == 1 then
				UserCmd:SetForwardMove( ( (math.sin(math.rad(LocalAngles[2]) ) * VecForward[2]) + (math.cos(math.rad(LocalAngles[2]) ) * VecForward[1]) ) * 200 )
				UserCmd:SetSideMove( ( (math.cos(math.rad(LocalAngles[2]) ) * -VecForward[2]) + (math.sin(math.rad(LocalAngles[2]) ) * VecForward[1]) ) * 200 )
			end
		else
			local DiffYaw = AimAngles[2] - LocalAngles[2]

			if DiffYaw > 180 then
				DiffYaw = DiffYaw - 360
			elseif DiffYaw < -180 then
				DiffYaw = DiffYaw + 360
			end
			
			if TargetSpeed > 285 and chb_blockbot_retreat:GetValue() then
				UserCmd:SetForwardMove(-math.abs(TargetSpeed))
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
	
end

callbacks.Register("Draw", DrawingCallback)
callbacks.Register("CreateMove", CreateMoveCallback)