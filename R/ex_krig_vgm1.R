## Kriging also used in open API of ODB, the following is a simplified code version to solve
## https://gis.stackexchange.com/questions/315750/making-data-table-using-linear-kriging-interpolation-with-variogram-in-r

longitude_for_data = c(32,68,89,145,176, -14, -42)
latitude_for_data  = c(22,98,21,13 , 16,-134,-102)
Z_for_data         = c(30,40,60,70 , 20,  40, 100)
data_to_analise    = cbind(longitude_for_data,latitude_for_data,Z_for_data)

longitude    = seq(-180,180,by=5.0)
latitude     = seq(-180,180,by=2.5)
lat_long_grid= expand.grid(longitude,latitude)

crs = NA

library(sf)
library(gstat)

data <- as.data.frame(data_to_analise)
colnames(data)[1:3] <- c("longitude", "latitude", "z")

st.sf <- st_as_sf(x = data, coords = c("longitude", "latitude"), crs=NA)
colnames(st.sf)[1] <- "z"

colnames(lat_long_grid) <- c("longitude", "latitude")
gbbx <- st_as_sf(x = lat_long_grid, coords = c("longitude", "latitude"), crs=NA) #%>% as("Spatial")

vgm1 <- gstat::variogram(z~1, st.sf)
fit1 <- gstat::fit.variogram(vgm1, model = gstat::vgm("Gau")) # fit model
krig <- gstat::krige(z~1, st.sf, gbbx, model=fit1)

out <- as.data.frame(krig)

