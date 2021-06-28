using ArchGDAL
const AG = ArchGDAL

## COMPOSITE ##
dataset = AG.read("data/iucn_habitatclassification_composite_lvl1_ver004.tif")
# bands of informations
AG.nraster(dataset)
# georeferencing
gt = AG.getgeotransform(dataset)
#origin
p = AG.getproj(dataset)

data = AG.read(dataset, 1, 0, 0, 4, 4)

# cf question - what does this correspond to ?
habitats = unique(AG.read(dataset))

## FRAC ###
dataset_lvl2_forest = AG.read("data/lvl2_frac_1km_ver004/iucn_habitatclassification_fraction_lvl2__104_Forest – Temperate__ver004.tif")
data = AG.read(dataset_lvl2_forest, 1, 0, 0, 100, 100)
habitats = unique(AG.read(dataset_lvl2_forest))
