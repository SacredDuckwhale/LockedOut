--[[
    This file handles world boss information.
--]]
local addonName, _ = ...;

-- libraries
local addon = LibStub( "AceAddon-3.0" ):GetAddon( addonName );
local L     = LibStub( "AceLocale-3.0" ):GetLocale( addonName, false );

-- Upvalues
local next = -- variables
      next   -- lua functions

-- cache blizzard function/globals
local EJ_GetCurrentTier, EJ_SelectTier, EJ_GetInstanceByIndex, EJ_GetEncounterInfoByIndex, IsQuestFlaggedCompleted,
        READY_CHECK_READY_TEXTURE, IsQuestActive =          -- variables 
      EJ_GetCurrentTier, EJ_SelectTier, EJ_GetInstanceByIndex, EJ_GetEncounterInfoByIndex, IsQuestFlaggedCompleted,
        READY_CHECK_READY_TEXTURE, C_TaskQuest.IsActive     -- blizzard api

-- Blizzard api cannot link npc id's to world quests, so we have to hardcode
local WORLD_BOSS_LIST = {
---[[
    -- Pandaria
    { instanceID=322, bossID=691,  questID=32099, bossName="Sha of Anger", },
    { instanceID=322, bossID=725,  questID=32098, bossName="Salyis's Warband" },
    { instanceID=322, bossID=814,  questID=32518, bossName="Nalak, The Storm Lord", },
    { instanceID=322, bossID=826,  questID=32519, bossName="Oondasta",  },
    { instanceID=322, bossID=857,  questID=33117, bossName="Celestials" }, -- bossName="Chi-Ji, The Red Crane", }, remapped name
    { instanceID=322, bossID=858,  questID=33117, bossName="Yu'lon, The Jade Serpent", }, -- mapped so i don't chase missing mappings
    { instanceID=322, bossID=859,  questID=33117, bossName="Niuzao, The Black Ox", }, -- mapped so i don't chase missing mappings
    { instanceID=322, bossID=860,  questID=33117, bossName="Xuen, The White Tiger", }, -- mapped so i don't chase missing mappings
    { instanceID=322, bossID=861,  questID=33118, bossName="Ordos, Fire-God of the Yaungol", },
    
    -- Draenor
    { instanceID=557, bossID=1211, questID=37462, bossName="Tarlna the Ageless" },
    { instanceID=557, bossID=1262, questID=37464, bossName="Rukhmar" },
    { instanceID=557, bossID=1291, questID=37462, bossName="Drov the Ruiner" },
    { instanceID=557, bossID=1452, questID=39380, bossName="Supreme Lord Kazzak" },

    -- Broken Isles
    { instanceID=822, bossID=1749, questID=42270, bossName="Nithogg" },
    { instanceID=822, bossID=1756, questID=42269, bossName="The Soultakers" },
    { instanceID=822, bossID=1763, questID=42779, bossName="Shar'thos" },
    { instanceID=822, bossID=1769, questID=43192, bossName="Levantus" },
    { instanceID=822, bossID=1770, questID=42819, bossName="Humongris" },
    { instanceID=822, bossID=1774, questID=43193, bossName="Calamir" },
    { instanceID=822, bossID=1783, questID=43513, bossName="Na'zak the Fiend" },
    { instanceID=822, bossID=1789, questID=43448, bossName="Drugon the Frostblood" },
    { instanceID=822, bossID=1790, questID=43512, bossName="Ana-Mouz" },
    { instanceID=822, bossID=1795, questID=43985, bossName="Flotsam" },
    { instanceID=822, bossID=1796, questID=44287, bossName="Withered J'im" },
    { instanceID=822, bossID=1883, questID=46947, bossName="Brutallus" },
    { instanceID=822, bossID=1884, questID=46948, bossName="Malificus" },
    { instanceID=822, bossID=1885, questID=46945, bossName="Si'vash" },
    { instanceID=822, bossID=1956, questID=47061, bossName="Apocron" },

    -- Argus
    { instanceID=959, bossID=2010, questID=49169, bossName="Matron Folnuna" },
    { instanceID=959, bossID=2011, questID=49167, bossName="Mistress Alluradel" },
    { instanceID=959, bossID=2012, questID=49166, bossName="Inquisitor Meto" },
    { instanceID=959, bossID=2013, questID=49170, bossName="Occularus" },
    { instanceID=959, bossID=2014, questID=49171, bossName="Sotanathor" },
    { instanceID=959, bossID=2015, questID=49168, bossName="Pit Lord Vilemus" }
--]]
}

function CheckForMissingMappings()
    -- get current tier setting so we don't step on what's currently set
    local showRaid = true;
    local currentTierId = EJ_GetCurrentTier();

    local worldBosses = {};
    
    -- world bosses started with Pandaria - so start with that one and skip the ones before it.
    for tierId = 5, EJ_GetNumTiers() do
        EJ_SelectTier( tierId );
        
        -- the world bosses are under the first instance for all (Pandaria, Draenor, Broken Isles)
        -- so just stick with getting the instance back for the first
        local instanceId, instanceName = EJ_GetInstanceByIndex( 1, showRaid );
        EJ_SelectInstance( instanceId );

        local bossIndex = 1;
        local bossName, _, bossID = EJ_GetEncounterInfoByIndex( bossIndex );
        while bossId do
            worldBosses[ bossId ] = {}
            worldBosses[ bossId ].instanceId = instanceId;
            worldBosses[ bossId ].bossName = bossName;

            bossIndex = bossIndex + 1;
            bossName, _, bossID = EJ_GetEncounterInfoByIndex( bossIndex );
        end -- while bossId
    end -- for tierId = 5, EJ_GetNumTiers()

    -- set it back to the current tier
    EJ_SelectTier( currentTierId );    

    local found = false;
    for bossId, bossData in next, worldBosses do
        if( WORLD_BOSS_LIST[ bossId ] == nil ) then
            print( 'unmapped boss found: [' .. bossId .. '] = { instanceId=' .. bossData.instanceId .. ', questID=0, bossName="' .. bossData.bossName .. '" }' );
            found = true;
        end -- if( WORLD_BOSS_LIST[ bossId ] == nil )
    end; -- for bossId, bossData in next, worldBosses
    
    if( not found ) then
        print( "no mappping issues found" );
    end -- if( not found )
end -- CheckForMissingMappings()

local BOSS_KILL_TEXT = "|T" .. READY_CHECK_READY_TEXTURE .. ":0|t";
function addon:Lockedout_BuildWorldBoss( realmName, charNdx )
    local worldBosses = {};

    local calculatedResetDate = self:getWeeklyLockoutDate();
    for _, bossData in next, WORLD_BOSS_LIST do
        local questCompleted = IsQuestFlaggedCompleted( bossData.questID );
        local questShowUncompleted = ( IsQuestActive( bossData.questID ) ) and ( not self.config.profile.worldBoss.showKilledOnly );
        if( questCompleted ) or ( questShowUncompleted ) then
            local displayText = questCompleted and BOSS_KILL_TEXT or "";

            worldBosses[ bossData.instanceID .. "|" .. bossData.bossID ] = {
                                                questID = bossData.questID,
                                                displayText = displayText,
                                                resetDate = calculatedResetDate
                                             }
            self:debug( "adding: ", self:getWorldBossName( bossData.instanceID, bossData.bossID ) );
        end
    end

    LockoutDb[ realmName ][ charNdx ].worldBosses = worldBosses;
end -- Lockedout_BuildInstanceLockout()

