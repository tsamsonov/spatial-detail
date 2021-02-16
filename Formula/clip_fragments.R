library(sf)
library(geobuffer)
library(tidyverse)
library(mapview)
library(gdalUtils)
library(glue)
library(stringi)

# setwd('/Volumes/Data/Spatial/TOPO/')

scales = c('1000', '0500', '0200')
fragments = tibble(
  name_ru = c('Москва', 'Элиста', 'Воркута', 'Грозный', 'Великий Устюг', 
    'Петрозаводск', 'Воронеж', 'Уфа', 'Салехард', 'Нижневартовск',
    'Владивосток', 'Краснодар', 'Рубцовск', 'Петропавловск-Камчатский', 'Лесосибирск', 
    'Мурманск', 'Алдан', 'Березники', 'Чита', 'Комсомольск-на-Амуре',
    'Тюмень', 'Ульяновск',  'Кызыл', 'Ухта', 'Братск'),
  name_en = gsub('ʹ', '', gsub('·', '', stri_trans_general(name_ru, "russian-latin/bgn")))
) %>% 
  arrange(name_en)

cities = st_read('/Volumes/Data/Spatial/TOPO/Russia_8000.gdb', 'poppnt_8mln') %>% 
  st_transform(4326)
pts = cities %>% dplyr::filter(name_2 %in% fragments$name_ru)

# mapview(pts)

wkt = 'PROJCS["Lambert_Azimuthal_Equal_Area",GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137.0,298.257223563]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433],METADATA["World",-180.0,-90.0,180.0,90.0,0.0,0.0174532925199433,0.0,1262]],PROJECTION["Lambert_Azimuthal_Equal_Area"],PARAMETER["False_Easting",0.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",{lon}],PARAMETER["Latitude_Of_Origin",{lat}],UNIT["Meter",1.0]]' 

lc_in = '/Volumes/Data/Spatial/LandCover/Copernicus/VRTS/DISCRETE.vrt'
lc_out = '/Volumes/Data/Spatial/LandCover/Copernicus/Fragments/{name}.tif'
lc_prj_out = '/Volumes/Data/Spatial/LandCover/Copernicus/Fragments_prj/{name}.tif'

# for (scale in scales) {
#   scale_int = as.integer(scale)
  # dir.create(glue('/Volumes/Data/Spatial/TOPO/Fragments/{scale_int}'))
  for (i in 1:nrow(fragments)) {
    pt = dplyr::filter(pts, name_2 == fragments[[i, 'name_ru']])
    name = fragments[[i, 'name_en']]
    box = st_bbox(geobuffer_pts(pt, dist_m = 50000, output = 'sf'))
    lon = st_coordinates(pt)[,1]
    lat = st_coordinates(pt)[,2]
    prj = glue(wkt)
    # db_in = glue('/Volumes/Data/Spatial/TOPO/Russia_{scale}.gdb')
    # db_out = glue('/Volumes/Data/Spatial/TOPO/Fragments/{scale_int}/{name}_{scale}.gpkg')
    # ogr2ogr(db_in, db_out, spat = box, clipsrc = box, skipfailures = TRUE, 
    #         t_srs = prj, a_srs = prj, overwrite = TRUE)
    gdal_translate(lc_in, glue(lc_out), projwin = box[c(1,4,3,2)])
    
    gdalwarp(lc_in, glue(lc_prj_out), t_srs = prj, te = box, te_srs = 'EPSG:4326', tr = c(100, 100))
  }
# }


