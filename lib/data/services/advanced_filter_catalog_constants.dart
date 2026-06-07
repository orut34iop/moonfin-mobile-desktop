class AdvancedFilterCatalogConstants {
  static const movieType = 'Movie';
  static const seriesType = 'Series';
  static const mediaTypes = [movieType, seriesType];
  static const pageSize = 1000;
  static const embyLibraryIdField = '_AdvancedFilterEmbyLibraryId';
  static const embyLibraryNameField = '_AdvancedFilterEmbyLibraryName';
  static const itemFields =
      'Type,UserData,PrimaryImageAspectRatio,SortName,CommunityRating,'
      'OfficialRating,RunTimeTicks,ProductionYear,PremiereDate,Genres,'
      'ProductionLocations,ParentId,ImageTags,BackdropImageTags,ParentBackdropItemId,'
      'ParentBackdropImageTags,ParentThumbItemId,ParentThumbImageTag,SeriesId,'
      'SeriesPrimaryImageTag,PrimaryImageTag,PrimaryImageItemId';

  const AdvancedFilterCatalogConstants._();
}
