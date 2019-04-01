## rayshader package: https://github.com/tylermorganwall/rayshader 
## Reference: https://www.davidsolito.com/post/a-rayshader-base-tutortial-bonus-hawaii/
## and https://wcmbishop.github.io/rayshader-demo/
## You need download one your own raster or grid file (.xyz or .grd), e.g. from Etopo1

library(raster)
library(sp)
library(rayshader)
library(data.table)
library(magrittr)

etd <- fread("EA1000m2011.xyz")
setnames(etd,1:3,c("longitude","latitude","z")) %>% setkey(longitude,latitude)

dt<- etd[longitude>=109.5 & longitude<130.5 & latitude>=17.5 & latitude<30.5,]

r <- rasterFromXYZ(dt, crs=sp::CRS(paste0("+init=epsg:", as.character(4326))))

emat <- matrix(extract(r, extent(r), buffer = 100), nrow = ncol(r), ncol = nrow(r))

zscal = 30.0
emat  %>%
  sphere_shade(sunangle = 35, texture = "imhof1", zscale = zscal) %>%
  plot_map()

amb_shadex <- ambient_shade(emat, zscale = zscal)
ray_shadex <- ray_shade(emat,  sunangle = 35, zscale = zscal)

emat  %>%
  sphere_shade(sunangle = 35, texture = "bw", zscale = zscal) %>%
  add_shadow(ray_shadex, 0.7) %>%
  #add_overlay(overlay_img, alphalayer = 0.5) %>%
  plot_3d(heightmap = emat, zscale = zscal, lineantialias = TRUE)

render_water(emat, zscale = zscal, wateralpha = 0.3, waterlinecolor = "turquoise4", watercolor = "turquoise4")
render_camera(theta = 2.5, phi = 55, zoom = 0.8, fov = 75)
render_snapshot("Taiwan_sea_depth3D.png")
render_snapshot()  
save_3dprint("Taiwan_sea_depth3D.stl", maxwidth = 150, unit = "mm") ## For 3D printer only

rgl::rgl.clear()
