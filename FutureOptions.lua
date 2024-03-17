local TOOLTIP_OPTIONS = {
  {
    type = "checkbox",
    text = BAGANATOR_L_SHOW_INVENTORY_IN_TOOLTIPS,
    option = "show_inventory_tooltips",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_SHOW_CURRENCY_TOOLTIPS,
    option = "show_currency_tooltips",
    check = function() return C_CurrencyInfo ~= nil end,
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_PRESS_SHIFT_TO_SHOW_TOOLTIPS,
    option = "show_tooltips_on_shift",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_SHOW_EQUIPPED_ITEMS_IN_INVENTORY_TOOLTIPS,
    option = "show_equipped_items_in_tooltips",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_SHOW_GUILD_BANKS_IN_INVENTORY_TOOLTIPS,
    option = "show_guild_banks_in_tooltips",
    check = NotIsEraCheck,
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_ONLY_USE_SAME_CONNECTED_REALMS,
    option = "tooltips_connected_realms_only",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_ONLY_USE_SAME_FACTION_CHARACTERS,
    option = "tooltips_faction_only",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_SORT_BY_CHARACTER_NAME,
    option = "tooltips_sort_by_name",
  },
  {
    type = "slider",
    min = 1,
    max = 40,
    lowText = "1",
    highText = "40",
    valuePattern = BAGANATOR_L_X_CHARACTERS_SHOWN,
    option = "tooltips_character_limit",
  },
}
