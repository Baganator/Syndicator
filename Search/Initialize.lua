function Syndicator.Search.Initialize()
  Syndicator.Search.InitializeSearchEngine()

  SlashCmdList["SyndicatorSearch"] = Syndicator.Search.RunMegaSearchAndPrintResults
  SLASH_SyndicatorSearch1 = "/baganatorsearch"
  SLASH_SyndicatorSearch2 = "/bgrs"
  SLASH_SyndicatorSearch3 = "/syndicatorsearch"
  SLASH_SyndicatorSearch4 = "/syns"
end
