
-- Some parts copied and edited from player.lua in default mod.

-- Player stats and animations
local player_anim = {}
local player_sneak = {}
local ANIM_STAND = 1
local ANIM_SIT = 2
local ANIM_LAY = 3
local ANIM_WALK  = 4
local ANIM_WALK_MINE = 5
local ANIM_MINE = 6
local ANIM_RUN = 7
-- Called when a player's appearance needs to be updated
minetest.register_on_joinplayer(function ( pl )
	local name = pl:get_player_name()

	player_anim[name] = 0 -- Animation will be set further below immediately
	player_sneak[name] = false
	prop = {
		mesh = "character.b3d",
		textures = {"character.png", },
		visual = "mesh",
		visual_size = {x=1, y=1},
	}
	pl:set_properties(prop)
end)

local bone_pos = {
    Armature_Head = { x=0, y=6.75, z=0 };
    Armature_Arm_Left = { x=-3.9, y=6.5, z=0 };
    Armature_Arm_Right = { x=3.9, y=6.5, z=0 };
    Armature_Leg_Left = { x=-1.15, y=0, z=0 };
    Armature_Leg_Right = { x=1.15, y=0, z=0 };
};

local HEAD = "Armature_Head";
local LARM = "Armature_Arm_Left";
local RARM = "Armature_Arm_Right";
local LLEG = "Armature_Leg_Left";
local RLEG = "Armature_Leg_Right";

local function rotbone ( player, bone, x, y, z )
    player:set_bone_position(bone, bone_pos[bone], { x=x, y=y, z=z });
end

local step = 0;
local FULL_STEP = 40;

local anims = {

    [ANIM_STAND] = function ( player )
        rotbone(player, LARM, 180, 0, 0);
        rotbone(player, RARM, 180, 0, 0);
        rotbone(player, LLEG, 0, 0, 0);
        rotbone(player, RLEG, 0, 0, 0);
    end;

    [ANIM_WALK] = function ( player )
        local m = step / FULL_STEP;
        local r = math.sin(m * math.rad(360));
        rotbone(player, LARM, (r * 30) + 180, 0, 0);
        rotbone(player, RARM, (r * -30) + 180, 0, 0);
        rotbone(player, LLEG, (r * 30), 0, 0);
        rotbone(player, RLEG, (r * -30), 0, 0);
    end;

    [ANIM_MINE] = function ( player )
        local m = step / FULL_STEP;
        local r2 = math.sin((m*3) * math.rad(360));
        local look = math.deg(player:get_look_pitch());
        rotbone(player, LARM, 180, 0, 0);
        rotbone(player, RARM, (r2 * -15) + 270 + look, 20, 0);
        rotbone(player, LLEG, 0, 0, 0);
        rotbone(player, RLEG, 0, 0, 0);
    end;

    [ANIM_WALK_MINE] = function ( player )
        local m = step / FULL_STEP;
        local r = math.sin(m * math.rad(360));
        local r2 = math.sin((m/2) * math.rad(360));
        local look = math.deg(player:get_look_pitch());
        rotbone(player, LARM, (r * 30) + 180, 0, 0);
        rotbone(player, RARM, (r2 * -15) + 270 + look, 20, 0);
        rotbone(player, LLEG, (r * 30), 0, 0);
        rotbone(player, RLEG, (r * -30), 0, 0);
    end;

    [ANIM_RUN] = function ( player )
        local m = step / FULL_STEP;
        local r = math.sin(m * math.rad(360));
        rotbone(player, LARM, (r * 60) + 180, 0, 0);
        rotbone(player, RARM, (r * -60) + 180, 0, 0);
        rotbone(player, LLEG, (r * 60), 0, 0);
        rotbone(player, RLEG, (r * -60), 0, 0);
    end;

};

local function player_animate ( player, anim )
    if (not anims[anim]) then return; end
    anims[anim](player);
    rotbone(player, HEAD, math.deg(player:get_look_pitch()), 0, 0);
    step = step + 1;
    if (step > FULL_STEP) then step = 0; end
end

-- Check each player and apply animations
minetest.register_globalstep(function ( dtime )
	for _, pl in pairs(minetest.get_connected_players()) do
		local name = pl:get_player_name()
		local controls = pl:get_player_control()
		local walking = false
		local animation_speed_mod = animation_speed

		-- Determine if the player is walking
		if controls.up or controls.down or controls.left or controls.right then
			walking = true
		end

		-- Determine if the player is sneaking, and reduce animation speed if so
		if controls.sneak and pl:get_hp() ~= 0 and (walking or controls.LMB) then
			animation_speed_mod = animation_speed_mod / 2
			-- Refresh player animation below if sneak state changed
			if not player_sneak[name] then
				player_anim[name] = 0
				player_sneak[name] = true
			end
		else
			-- Refresh player animation below if sneak state changed
			if player_sneak[name] then
				player_anim[name] = 0
				player_sneak[name] = false
			end
		end

		-- Apply animations based on what the player is doing
		if pl:get_hp() == 0 then
			if player_anim[name] ~= ANIM_LAY then
				player_anim[name] = ANIM_LAY
			end
		elseif walking and controls.LMB then
			if player_anim[name] ~= ANIM_WALK_MINE then
				player_anim[name] = ANIM_WALK_MINE
			end
		elseif walking then
			if player_anim[name] ~= ANIM_WALK then
				player_anim[name] = ANIM_WALK
			end
		elseif controls.LMB then
			if player_anim[name] ~= ANIM_MINE then
				player_anim[name] = ANIM_MINE
			end
		elseif player_anim[name] ~= ANIM_STAND then
			player_anim[name] = ANIM_STAND
		end
        player_animate(pl, player_anim[name])
	end
end);

-- END
