Syndicator.Locales = CopyTable(SYNDICATOR_LOCALES.enUS)
for key, translation in pairs(SYNDICATOR_LOCALES[GetLocale()]) do
  Syndicator.Locales[key] = translation
end
for key, translation in pairs(Syndicator.Locales) do
  _G["SYNDICATOR_L_" .. key] = translation
end
