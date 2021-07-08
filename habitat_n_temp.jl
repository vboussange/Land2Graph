using PyPlot
using ArchGDAL
const AG = ArchGDAL
cd(@__DIR__)
## Forest data ##
dataset_forest = AG.read("./data/lvl1_frac_1km_ver004/iucn_habitatclassification_fraction_lvl1__100_Forest__ver004.tif")
mydiskarray_forest = AG.getband(dataset_forest,1)
proj_forest = AG.getproj(dataset_forest)
gt_forest = AG.getgeotransform(dataset_forest) 

clf()
plt.imshow(mydiskarray_forest[:,:]')
gcf()

dataset_temp = AG.read("./data/chelsa/CHELSA_bio1_reprojected.tif")
mydiskarray_temp = AG.getband(dataset_temp,1)
proj_temp = AG.getproj(dataset_temp)
gt_temp = AG.getgeotransform(dataset_temp) 

clf()
plt.imshow(mydiskarray_temp[:,:]')
plt.colorbar()
gcf()