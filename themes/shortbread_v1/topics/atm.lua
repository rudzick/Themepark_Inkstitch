-- ---------------------------------------------------------------------------
--
-- Theme: shortbread_v1
-- Topic: atm
--
-- ---------------------------------------------------------------------------

local themepark, theme, cfg = ...

themepark:add_table{
    name = 'atm',
    ids_type = 'any',
    geom = 'point',
    columns = themepark:columns({
        { column = 'tags', type = 'jsonb' },
    }),
    tags = { },
    tiles = {
        minzoom = 9,
    },
}

themepark:add_table{
    name = 'atm_polygons',
    ids_type = 'way',
    geom = 'polygon',
    columns = themepark:columns({
        { column = 'tags', type = 'jsonb' },
        { column = 'piageom', type = 'point' },
    }),
    tags = { },
    tiles = {
    minzoom = 9,
	},
}
themepark:add_table{
    name = 'cash_withdrawal',
    ids_type = 'any',
    geom = 'point',
    columns = themepark:columns({
        { column = 'tags', type = 'jsonb' },
    }),
    tags = { },
    tiles = {
        minzoom = 9,
    },
}

themepark:add_table{
    name = 'cash_withdrawal_polygons',
    ids_type = 'way',
    geom = 'polygon',
    columns = themepark:columns({
        { column = 'tags', type = 'jsonb' },
        { column = 'piageom', type = 'point' },
    }),
    tags = { },
    tiles = {
    minzoom = 9,
	},
}

-- ---------------------------------------------------------------------------

local function has_atm(tags)
    return tags.atm
        and tags.atm ~= 'no'
        and tags.atm ~= 'unknown'
end

themepark:add_proc('node', function(object, data)
    if object.tags.amenity ~= 'atm' and not has_atm(object.tags) then
        return
    end

    themepark:insert('atm', {
        geom = object:as_point(),
        tags = object.tags,
    })
end)

themepark:add_proc('way', function(object, data)
    if not object.is_closed or not has_atm(object.tags) then
        return
    end

    local geom = object:as_polygon()
    themepark:insert('atm_polygons', {
        geom = geom,
        tags = object.tags,
        piageom = geom:pole_of_inaccessibility()
    })
end)

-- ---------------------------------------------------------------------------
-- Explicitly tagged cash withdrawal (cash_withdrawal=*)
-- ---------------------------------------------------------------------------

local function has_cash_withdrawal(tags)
    return tags.cash_withdrawal
        and tags.cash_withdrawal ~= 'no'
        and tags.cash_withdrawal ~= 'unknown'
end

themepark:add_proc('node', function(object, data)
    if not has_cash_withdrawal(object.tags) then
        return
    end

    themepark:insert('cash_withdrawal', {
        geom = object:as_point(),
        tags = object.tags,
    })
end)

themepark:add_proc('way', function(object, data)
    if not object.is_closed or not has_cash_withdrawal(object.tags) then
        return
    end

    local geom = object:as_polygon()
    themepark:insert('cash_withdrawal_polygons', {
        geom = geom,
        tags = object.tags,
        piageom = geom:pole_of_inaccessibility()
    })
end)

-- ---------------------------------------------------------------------------
-- Implicit cash withdrawal for shops of known chains
-- https://www.hanseaticbank.de/klarmacher/bezahlen/geld-abheben-im-supermarkt-so-funktioniert-cashback-bei-rewe-lidl-co
--
-- name:     brand/operator name (lower case)
-- wikidata: brand/operator Wikidata ID (lower case)
-- aliases:  further brand/operator names (lower case)
-- minimum:  value for cash_withdrawal:purchase_minimum (nil = not set)
--
-- Order matters: The first matching entry wins (e.g. 'aldi nord' and
-- 'aldi süd' must come before 'aldi').
-- ---------------------------------------------------------------------------

local cash_withdrawal_chains = {
    { name = 'edeka',                 wikidata = 'q701755',   minimum = '20' },
    { name = 'rewe',                  wikidata = 'q16968817', minimum = 'no' },
    { name = 'aldi nord',             wikidata = 'q41171373', minimum = '1' },
    { name = 'aldi süd',              wikidata = 'q41171672', minimum = '5' },
    { name = 'aldi',                  wikidata = 'q125054' },
    { name = 'dm',                    wikidata = 'q266572',   minimum = 'no' },
    { name = 'netto marken-discount', wikidata = 'q879858',   minimum = '10',
      aliases = { 'netto' } },
    { name = 'denns biomarkt',        wikidata = 'q48883773', minimum = '20',
      aliases = { 'denns' } },
    { name = 'famila',                wikidata = 'q1395108',  minimum = '10' },
    { name = 'kaufland',              wikidata = 'q685967',   minimum = '10' },
    { name = 'lidl',                  wikidata = 'q151954',   minimum = '0.99' },
    { name = 'markant',               wikidata = 'q57523365', minimum = '10' },
    { name = 'norma',                 wikidata = 'q450180',   minimum = '1' },
    { name = 'np-markt',              wikidata = 'q15836148', minimum = '10' },
    { name = 'penny',                 wikidata = 'q284688',   minimum = 'no' },
    { name = 'tegut',                 wikidata = 'q1547993',  minimum = 'no' },
    { name = 'wasgau',                wikidata = 'q2536857',  minimum = '20' },
}

local function lower_or_empty(value)
    if value then
        return string.lower(value)
    end
    return ''
end

local function chain_matches(chain, brand, operator, brandwikidata, operatorwikidata)
    if brand == chain.name or operator == chain.name
        or brandwikidata == chain.wikidata or operatorwikidata == chain.wikidata then
        return true
    end
    for _, alias in ipairs(chain.aliases or {}) do
        if brand == alias or operator == alias then
            return true
        end
    end
    return false
end

-- Returns a copy of the tags with the implicit cash_withdrawal tags added
-- if the object is a shop of a known chain, nil otherwise.
local function implicit_cash_withdrawal_tags(tags)
    if tags.cash_withdrawal or not tags.shop
        or tags.shop == 'no' or tags.shop == 'unknown' then
        return nil
    end

    local brand = lower_or_empty(tags.brand)
    local operator = lower_or_empty(tags.operator)
    local brandwikidata = lower_or_empty(tags['brand:wikidata'])
    local operatorwikidata = lower_or_empty(tags['operator:wikidata'])

    for _, chain in ipairs(cash_withdrawal_chains) do
        if chain_matches(chain, brand, operator, brandwikidata, operatorwikidata) then
            local t = {}
            for k, v in pairs(tags) do
                t[k] = v
            end
            t.cash_withdrawal = 'implicit'
            t['cash_withdrawal:purchase_required'] = 'yes'
            t['cash_withdrawal:purchase_minimum'] = chain.minimum
            t['cash_withdrawal:limit'] = '200'
            return t
        end
    end

    return nil
end

themepark:add_proc('node', function(object, data)
    local tags = implicit_cash_withdrawal_tags(object.tags)
    if not tags then
        return
    end

    themepark:insert('cash_withdrawal', {
        geom = object:as_point(),
        tags = tags,
    })
end)

themepark:add_proc('way', function(object, data)
    if not object.is_closed then
        return
    end

    local tags = implicit_cash_withdrawal_tags(object.tags)
    if not tags then
        return
    end

    local geom = object:as_polygon()
    themepark:insert('cash_withdrawal_polygons', {
        geom = geom,
        tags = tags,
        piageom = geom:pole_of_inaccessibility()
    })
end)

-- ---------------------------------------------------------------------------
