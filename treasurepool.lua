addon.name      = 'TreasurePool';
addon.author    = 'Shiyo';
addon.version   = '1.0.0.0';
addon.desc      = 'Displays your current treasure pool.';
addon.link      = 'https://ashitaxi.com/';

require('common');
local fonts = require('fonts');
local settings = require('settings');

local windowWidth = AshitaCore:GetConfigurationManager():GetFloat('boot', 'ffxi.registry', '0001', 1024);
local windowHeight = AshitaCore:GetConfigurationManager():GetFloat('boot', 'ffxi.registry', '0002', 768);

local default_settings = T{
	font = T{
        visible = true,
        font_family = 'Courier',
        font_height = 15,
        color = 0xFFFFFFFF,
        position_x = 76,
        position_y = 1361,
		background = T{
            visible = true,
            color = 0x80000000,
		}
    }
};

local treasurepool = T{
	settings = settings.load(default_settings)
};

local UpdateSettings = function()
    if (treasurepool.font ~= nil) then
        treasurepool.font:destroy();
    end
    treasurepool.font = fonts.new(treasurepool.settings.font);
end

local function GetTreasureData()
    local outTable = T{};
    for i = 0,9 do
        local treasureItem = AshitaCore:GetMemoryManager():GetInventory():GetTreasurePoolItem(i);
        if treasureItem and (treasureItem.ItemId > 0) then
            local resource = AshitaCore:GetResourceManager():GetItemById(treasureItem.ItemId);
            outTable:append({ Item=treasureItem, Resource = resource}); --This creates a table entry with both the resource and item.  This is all you care about.
            --outTable[#outTable + 1] = { Item=treasureItem, Resource = resource.Name };
        end
    end
    return outTable;
end

ashita.events.register('load', 'load_cb', function ()
    treasurepool.font = fonts.new(treasurepool.settings.font);
    settings.register('settings', 'settingchange', UpdateSettings);
end);


ashita.events.register('d3d_present', 'present_cb', function ()

    local fontObject = treasurepool.font;
    if (fontObject.position_x > windowWidth) then
      fontObject.position_x = 0;
    end
    if (fontObject.position_y > windowHeight) then
      fontObject.position_y = 0;
    end
    if (fontObject.position_x ~= treasurepool.settings.font.position_x) or (fontObject.position_y ~= treasurepool.settings.font.position_y) then
        treasurepool.settings.font.position_x = fontObject.position_x;
        treasurepool.settings.font.position_y = fontObject.position_y;
        settings.save()
    end

    local treasurePool = GetTreasureData();
    local treasureText = '';
    local firstLine = true;
    for _,entry in pairs(treasurePool) do
        if not firstLine then
            treasureText = treasureText .. '\n';
        end
        local name = AshitaCore:GetMemoryManager():GetEntity():GetName(entry.Item.WinningEntityTargetIndex);
        if (entry.Item.WinningLot == 0) then
            name = '';
        elseif (type(name) ~= 'string') or (string.len(name) < 3) then
            name = 'Unknown';
        end
        local individualLine = string.format('%-24s %4u:%s', entry.Resource.Name[1], entry.Item.WinningLot, name);
        treasureText = treasureText .. individualLine;
        firstLine = false;
    end

    treasurepool.font.text = treasureText;
end);

ashita.events.register('unload', 'unload_cb', function ()
    if (treasurepool.font ~= nil) then
        treasurepool.font:destroy();
    end
end);

