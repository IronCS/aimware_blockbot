local font_icon = draw.CreateFont("Webdings", 30, 30)
local font_warning = draw.CreateFont("Verdana", 15, 15)

-- Script --------
local cur_scriptname = GetScriptName()
local cur_version = "1.3.2"
local git_version = "https://raw.githubusercontent.com/itisluiz/aimware_blockbot/master/version.txt"
local git_repository = "https://raw.githubusercontent.com/itisluiz/aimware_blockbot/master/blockbot.lua"
local app_awusers = "http://api.shadyretard.io/awusers"
------------------

-- UI Elements --
local ref_msc_auto_other = gui.Reference("MISC", "AUTOMATION", "Other")

local txt_header = gui.Text( ref_msc_auto_other, "● Block Bot")
local key_blockbot = gui.Keybox(ref_msc_auto_other, "msc_blockbot", "On Key", 0)
local cob_blockbot_mode = gui.Combobox(ref_msc_auto_other, "msc_blockbot_mode", "Mode", "Match Speed", "Maximum Speed")
local chb_blockbot_retreat = gui.Checkbox(ref_msc_auto_other, "chb_blockbot_retreat", " Retreat on BunnyHop", 0)
-----------------

-- Check for updates
local function git_update()
	if cur_version ~= http.Get(git_version) then
		local this_script = file.Open(cur_scriptname, "w")
		this_script:Write(http.Get(git_repository))
		this_script:Close()
		print("[Lua Scripting] " .. cur_scriptname .. " has updated itself from version " .. cur_version .. " to " .. http.Get(git_version))
		print("[Lua Scripting] Please reload " .. cur_scriptname)
	else
		print("[Lua Scripting] " .. cur_scriptname .. " is up-to-date")
	end
end

-- Shared Variables
local Target = nil
local CrouchBlock = false
local LocalPlayer = nil

local awusers = {}

local function OnFrameMain()

	LocalPlayer = entities.GetLocalPlayer()
	
	if not gui.GetValue("lua_allow_http") then
		return
	end
	
	if LocalPlayer == nil or engine.GetServerIP() == nil then
		return
	end
	
	if (key_blockbot:GetValue() == nil or key_blockbot:GetValue() == 0) or not LocalPlayer:IsAlive() then
		return
	end
	
	if input.IsButtonDown(key_blockbot:GetValue()) and Target == nil then
		
		for Index, Entity in pairs(entities.FindByClass("CCSPlayer")) do
			if Entity:GetIndex() ~= LocalPlayer:GetIndex() and Entity:IsAlive() then
				local EntityID = client.GetPlayerInfo(Entity:GetIndex())["SteamID"]
				local isPleb = true
				
				for Index, SteamID in pairs(awusers) do	
					if SteamID == EntityID then
						isPleb = false
						break		
					end
				end
				
				if isPleb then
					if Target == nil then
						Target = Entity;
					elseif vector.Distance({LocalPlayer:GetAbsOrigin()}, {Target:GetAbsOrigin()}) > vector.Distance({LocalPlayer:GetAbsOrigin()}, {Entity:GetAbsOrigin()}) then
						Target = Entity;
					end
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
			CrouchBlock = false
			draw.Color(255, 0, 0, 255)
		end
		
		draw.SetFont(font_icon)
		
		if NearPlayer_toScreen[1] ~= nil and NearPlayer_toScreen[2] ~= nil then
			draw.TextShadow(NearPlayer_toScreen[1] - select(1, draw.GetTextSize("x")) / 2, NearPlayer_toScreen[2], "x")
		end
		
	end
	
end

local function OnCreateMoveMain(UserCmd)
	
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

function handleGet(content)
	if (content == nil) then
		return
    end
	
	awusers = {}
	for stringindex in content:gmatch("([^\t]*)") do
		table.insert(awusers, stringindex)
	end
end

local char_to_hex = function(c)
    return string.format("%%%02X", string.byte(c))
end

function urlencode(url) -- Straight up stolen from ShadyRetard, thanks for all the help.
    if url == nil then
        return
    end
    url = url:gsub("\n", "\r\n")
    url = url:gsub("([^%w ])", char_to_hex)
    url = url:gsub(" ", "+")
    return url
end

-- Had to add this because everyone is retarded
local function OnFrameWarning()
	if math.floor(common.Time()) % 2 > 0 then
		draw.Color(255, 255, 255, 255)
	else
		draw.Color(255, 0, 0, 255)
	end
	draw.SetFont(font_warning)
	draw.Text(0, 0, "[Lua Scripting] Please enable Lua HTTP and Lua script/config and reload script")
end

local function OnEventMain(GameEvent)
	
	if client.GetLocalPlayerIndex() == nil then
		return
	end
	
	local LocalSteamID = client.GetPlayerInfo(client.GetLocalPlayerIndex())["SteamID"]
	
	if GameEvent:GetName() == "round_prestart" then
		http.Get(app_awusers .. "?steamid=" .. urlencode(LocalSteamID), handleGet)
	end

end

if gui.GetValue("lua_allow_http") and gui.GetValue("lua_allow_cfg") then
	git_update()
	
	callbacks.Register("Draw", OnFrameMain)
	callbacks.Register("CreateMove", OnCreateMoveMain)
	callbacks.Register("FireGameEvent", OnEventMain)
	
	client.AllowListener("round_prestart")
else
	print("[Lua Scripting] Please enable Lua HTTP and Lua script/config and reload script")
	callbacks.Register("Draw", OnFrameWarning)
end
