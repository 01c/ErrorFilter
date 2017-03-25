-- ErrorFilter
-- A World of Warcraft 1.12 AddOn for filtering out error messages.
-- GitHub repository: https://github.com/01c/errorfilter/
-- Based on RogueSpam by Allara.

-- Properties.
ErrorFilter_Version = "0.9";
ErrorFilter_Enabled = true;
ErrorFilter_FilterAll = false;
ErrorFilter_Filters = {
	ERR_ABILITY_COOLDOWN,               -- "Ability is not ready yet."
    ERR_BADATTACKPOS,                   -- "You are too far away!"
    ERR_SPELL_OUT_OF_RANGE,             -- "Out of range."
    ERR_SPELL_COOLDOWN,                 -- "Spell is not ready yet."
    ERR_OUT_OF_ENERGY,                  -- "Not enough energy"
    ERR_OUT_OF_RAGE,                    -- "Not enough rage"
    ERR_OUT_OF_MANA,                    -- "Not enough mana"
	ERR_NO_ATTACK_TARGET,               -- "There is nothing to attack."
	SPELL_FAILED_NO_COMBO_POINTS,       -- "That ability requires combo points"
	SPELL_FAILED_TARGETS_DEAD,          -- "Your target is dead"
	SPELL_FAILED_SPELL_IN_PROGRESS,	    -- "Another action is in progress"
};

-- Helper functions.
local function ColorCode(r, g, b)
	return string.format("|cff%02x%02x%02x", (r * 255), (g * 255), (b * 255));
end

local function OutputMessage(msg)
	if (DEFAULT_CHAT_FRAME) then
		DEFAULT_CHAT_FRAME:AddMessage(msg);
	end
end

-- Fields.
local cSpecial = ColorCode(0.67, 0.83, 0.45);
local cDefault = ColorCode(1, 1, 1);

local cPos = ColorCode(0, 1, 0);
local cNeg = ColorCode(1, 0, 0);
local nameRegistered = false;

-- Localizable strings.
local LOC_ERRORFILTER = "ErrorFilter";
local LOC_INIT_A = "ErrorFilter ";
local LOC_V = "v";
local LOC_INIT_B = " loaded. Type /errorfilter or /ef for options.";

local LOC_INFO_USAGE = cSpecial.."Usage: "..cDefault.."/{errorfilter | ef} {reset | enabled | all | list | add | remove}";
local LOC_INFO_RESET = " - "..cSpecial.."reset: "..cDefault.."Reset all options to default settings.";
local LOC_INFO_ENABLED_A = " - "..cSpecial.."enabled: ";
local LOC_INFO_ENABLED_B = cDefault.." Toggle functionality.";
local LOC_INFO_ALL_A = " - "..cSpecial.."all: ";
local LOC_INFO_ALL_B = cDefault.." Toggle filtering all messages, ignoring list.";
local LOC_INFO_LIST = " - "..cSpecial.."list: "..cDefault.."Shows the current filters and their ID number.";
local LOC_INFO_ADD = " - "..cSpecial.."add #message: "..cDefault.."Adds #message to the filter list.";
local LOC_INFO_REMOVE = " - "..cSpecial.."remove #id: "..cDefault.."Removes the message #id from the filter list.";

local LOC_HELP = "help";
local LOC_RESET = "reset";
local LOC_ENABLED = "enabled";
local LOC_LIST = "list";
local LOC_ALL = "all";
local LOC_ADD = "add";
local LOC_REMOVE = "remove";

local LOC_ERRORFILTER_HAS_BEEN_RESET = cSpecial.."ErrorFilter: "..cDefault.."All options were reset to default settings.";
local LOC_UNKNOWN_COMMAND = cSpecial.."ErrorFilter: "..cDefault.."Unknown command. Type /errorfilter or /ef for help.";
local LOC_CURRENT_FILTERS = "Current filters:";
local LOC_SLASH_COMMAND1 = "/errorfilter";
local LOC_SLASH_COMMAND2 = "/ef";
local LOC_ADD_USAGE = cSpecial.."Usage: "..cDefault.."/errorfilter add #message";
local LOC_ADD_EXAMPLE = cSpecial.."Example: "..cDefault.."/errorfilter add Invalid target";
local LOC_ADDED_FILTER = "ErrorFilter added filter: ";
local LOC_REMOVE_USAGE = cSpecial.."Usage: "..cDefault.."/errorfilter remove #id";
local LOC_REMOVE_EXAMPLE = cSpecial.."Example: "..cDefault.."/errorfilter remove 2";
local LOC_REMOVE_HELP = "Use /errorfilter list to see the IDs of every filter.";
local LOC_FILTER_NOT_FOUND = "ErrorFilter: filter not found.";
local LOC_REMOVED_FILTER = "Removed filter ";
local LOC_IS_NOW_SET_TO = " is now set to ";

local LOC_ON = "On";
local LOC_OFF = "Off";

-- Initialization.
function ErrorFilterInitialize()
    -- Unregister events.
	this:UnregisterEvent("UNIT_NAME_UPDATE");
	this:UnregisterEvent("PLAYER_ENTERING_WORLD");
    
    -- Localization.
	if (GetLocale() == "frFR") then
        -- French localization here.
		LOC_ERRORFILTER = "ErrorFilter(FR)";
	elseif (GetLocale() == "deDE") then
        -- German localization here.
		LOC_ERRORFILTER = "ErrorFilter(DE)";
	end
	
	-- Support for myAddOns.
	if (myAddOnsList) then
		myAddOnsList.ErrorFilter = {
			name = "ErrorFilter",
			description = "",
			version = ErrorFilter_Version,
			frame = "ErrorFilterFrame",
			category = MYADDONS_CATEGORY_CLASS
		};
	end
	
    -- Setup message.
	OutputMessage(cSpecial..LOC_INIT_A..cDefault..LOC_V..ErrorFilter_Version..cSpecial..LOC_INIT_B);
end

function ErrorFilterOnLoad()
	-- Register events.
	this:RegisterEvent("UNIT_NAME_UPDATE");
	this:RegisterEvent("PLAYER_ENTERING_WORLD");

	-- Add slash command.
	SlashCmdList["ERRORFILTERCOMMAND"] = ErrorFilterSlashHandler;
	SLASH_ERRORFILTERCOMMAND1 = LOC_SLASH_COMMAND1;
	SLASH_ERRORFILTERCOMMAND2 = LOC_SLASH_COMMAND2;
	
	-- Extend UIErrorsFrame_OnEvent function.
	Base_UIErrorsFrame_OnEvent = UIErrorsFrame_OnEvent;
	UIErrorsFrame_OnEvent = ApplyFilter;
end

function ErrorFilterOnEvent()
	-- Player loaded completely, time to initialize.
	if (event == "UNIT_NAME_UPDATE" and arg1 == "player") or (event=="PLAYER_ENTERING_WORLD") then
		if (nameRegistered) then
			return;
		end
		local playerName = UnitName("player");
		if (playerName ~= UNKNOWNBEING and playerName ~= "Unknown Entity" and playerName ~= nil ) then
			nameRegistered = true;
			ErrorFilterInitialize();
		end
	end
end

local function GetBooleanStatus(value)
    if (value) then
        return cSpecial.."["..cPos..LOC_ON..cSpecial.."]";
    else
        return cSpecial.."["..cNeg..LOC_OFF..cSpecial.."]";
    end
end

function ErrorFilterSlashHandler(msg, arg1, arg2)
	local omsg = msg;
	if (msg) then
		msg = string.lower(msg);
		-- No command.
		if (msg == "" or msg == LOC_HELP) then
            OutputMessage(LOC_INFO_USAGE);
			OutputMessage(LOC_INFO_RESET);
			OutputMessage(LOC_INFO_ENABLED_A..GetBooleanStatus(ErrorFilter_Enabled)..LOC_INFO_ENABLED_B);
            OutputMessage(LOC_INFO_ALL_A..GetBooleanStatus(ErrorFilter_FilterAll)..LOC_INFO_ALL_B);
			OutputMessage(LOC_INFO_LIST);
			OutputMessage(LOC_INFO_ADD);
			OutputMessage(LOC_INFO_REMOVE);
		-- Reset.
		elseif (msg == LOC_RESET) then
            ErrorFilter_Enabled = true;
            ErrorFilter_FilterAll = false;
            ErrorFilter_Filters = {
                ERR_ABILITY_COOLDOWN,               -- "Ability is not ready yet."
                ERR_BADATTACKPOS,                   -- "You are too far away!"
                ERR_SPELL_OUT_OF_RANGE,             -- "Out of range."
                ERR_SPELL_COOLDOWN,                 -- "Spell is not ready yet."
                ERR_OUT_OF_ENERGY,                  -- "Not enough energy"
                ERR_OUT_OF_RAGE,                    -- "Not enough rage"
                ERR_OUT_OF_MANA,                    -- "Not enough mana"
                ERR_NO_ATTACK_TARGET,               -- "There is nothing to attack."
                SPELL_FAILED_NO_COMBO_POINTS,       -- "That ability requires combo points"
                SPELL_FAILED_TARGETS_DEAD,          -- "Your target is dead"
                SPELL_FAILED_SPELL_IN_PROGRESS,	    -- "Another action is in progress"
            };
            OutputMessage(LOC_ERRORFILTER_HAS_BEEN_RESET);
		-- Enabled.
		elseif (msg == LOC_ENABLED) then
            ErrorFilter_Enabled = not ErrorFilter_Enabled;
            OutputMessage(cSpecial..LOC_ENABLED..cDefault..LOC_IS_NOW_SET_TO..GetBooleanStatus(ErrorFilter_Enabled));
		-- All.
		elseif (msg == LOC_ALL) then
            ErrorFilter_FilterAll = not ErrorFilter_FilterAll;
            OutputMessage(cSpecial..LOC_ALL..cDefault..LOC_IS_NOW_SET_TO..GetBooleanStatus(ErrorFilter_FilterAll));
		-- List filters.
		elseif (msg == LOC_LIST) then
			OutputMessage(cDefault..LOC_CURRENT_FILTERS);
			for key, text in ErrorFilter_Filters do
				OutputMessage(cSpecial.."  "..key..cDefault.." - \""..text.."\"");
			end
        -- Add.
		elseif (string.sub(msg, 1, string.len(LOC_ADD)) == LOC_ADD) then
			if (string.sub(msg, 1, (string.len(LOC_ADD) + 1)) ~= (LOC_ADD.." ")) then
				OutputMessage(LOC_ADD_USAGE);
				OutputMessage(LOC_ADD_EXAMPLE);
			else
				str = string.sub(omsg, (string.len(LOC_ADD) + 2), -1);
				table.insert(ErrorFilter_Filters, str);
				OutputMessage(cSpecial..LOC_ADDED_FILTER..cDefault..str);
			end
        -- Remove.
		elseif (string.sub(msg, 1, string.len(LOC_REMOVE)) == LOC_REMOVE) then
			if (string.sub(msg, 1, (string.len(LOC_REMOVE) + 1)) ~= (LOC_REMOVE.." ")) then
				OutputMessage(LOC_REMOVE_USAGE);
				OutputMessage(LOC_REMOVE_EXAMPLE);
				OutputMessage(LOC_REMOVE_HELP);
			else
				str = string.sub(omsg, (string.len(LOC_REMOVE) + 2), -1);
				for key, text in ErrorFilter_Filters do
					if (key == tonumber(str)) then
						table.remove(ErrorFilter_Filters, key);
						OutputMessage(cSpecial..LOC_REMOVED_FILTER..cDefault..text);
						return;
					end
				end
				OutputMessage(LOC_FILTER_NOT_FOUND);
			end
		-- Unknown command.
		else
			OutputMessage(LOC_UNKNOWN_COMMAND);
		end
	end
end

function ApplyFilter(event, message, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    if (ErrorFilter_Enabled) then
        if (ErrorFilter_FilterAll) then
            return;    
        else
            for key, text in ErrorFilter_Filters do
                if (text and message) then if (message == text) then return; end end
            end
        end
    end
    
	-- Run base function.
	Base_UIErrorsFrame_OnEvent(event, message, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9);
end