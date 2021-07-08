using PyPlot
cd(@__DIR__)
using Pkg; Pkg.activate("../.")
using ArchGDAL; const AG = ArchGDAL
dataset_temp = AG.read("../data/chelsa/CHELSA_bio1_1981-2010_V.2.1.tif")
dataset_prec = AG.read("../data/chelsa/CHELSA_bio12_1981-2010_V.2.1.tif")


# data = AG.read(dataset_prec, 1, 0, 0, 43200, 20880) .|> Float32 #x, y , window size
# AG.imread("../data/chelsa/CHELSA_bio1_1981-2010_V.2.1.tif")

## precipitations
band_prec = AG.getband(dataset_prec,1)

colorinterp =AG.getcolorinterp(band_prec)
unit =AG.getunittype(band_prec)
AG.blocksize(band_prec)
ArchGDAL.getscale(band_prec)
AG.getnodatavalue(band_prec)
AG.getoffset(band_prec)

band_prec[:,:] .= 

clf()
plt.imshow(band_prec[:,:]')
plt.colorbar()
gcf()



## temperature
band_temp_ar = AG.read(dataset_temp,1) # This is straightaway an array
band_temp = AG.getband(dataset_temp,1) # This is an array from diskarrays, so performs better!

colorinterp =AG.getcolorinterp(band_temp)
unit =AG.getunittype(band_temp)
AG.blocksize(band_temp)
scale = ArchGDAL.getscale(band_temp)
offset = AG.getoffset(band_temp)
AG.getnodatavalue(band_temp)


clf()
plt.imshow(band_temp'.* scale .+ offset)
plt.colorbar()
gcf()
