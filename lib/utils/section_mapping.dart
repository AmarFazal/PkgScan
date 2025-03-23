enum SectionType { mainInfo, manualImages, onlinePulledListings, otherInfo, scrapeData }

Map<String, SectionType> sectionMapping = {
  'Main Information': SectionType.mainInfo,
  'Manual Images': SectionType.manualImages,
  'Online Pulled Listings': SectionType.onlinePulledListings,
  'Other Information': SectionType.otherInfo,
  'Scrape Data': SectionType.scrapeData,
};
