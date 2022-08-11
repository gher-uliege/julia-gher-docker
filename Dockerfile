# build as:
# sudo docker build  --tag abarth/julia-gher:$(date --utc +%Y-%m-%dT%H%M)  --tag abarth/julia-gher:latest .


FROM jupyterhub/singleuser:2.0

MAINTAINER Alexander Barth <a.barth@ulg.ac.be>

EXPOSE 8888

USER root

RUN apt-get update
RUN apt-get install -y libnetcdf-dev netcdf-bin unzip
RUN apt-get install -y ca-certificates curl libnlopt0 make gcc 
RUN apt-get install -y emacs-nox git g++
RUN apt-get install -y gfortran make perl libnetcdff-dev libopenmpi-dev openmpi-bin subversion

ENV JUPYTER=/opt/conda/bin/jupyter
ENV PYTHON=/opt/conda/bin/python
ENV LD_LIBRARY_PATH=/opt/conda/lib/

RUN conda install -y ipywidgets matplotlib
RUN conda install -c conda-forge jupyterlab-git
RUN conda install -c conda-forge motuclient==1.8.6

RUN wget -O /usr/share/emacs/site-lisp/julia-mode.el https://raw.githubusercontent.com/JuliaEditorSupport/julia-emacs/master/julia-mode.el

# Install julia
ADD install_julia.sh .
RUN bash install_julia.sh; rm install_julia.sh

# install packages as user (to that the user can temporarily update them if necessary)
# and precompilation

USER jovyan

ENV LD_LIBRARY_PATH=
ENV JULIA_PACKAGES="CSV DataAssim DIVAnd DataStructures FFTW FileIO Glob HTTP IJulia ImageIO Images Interact Interpolations JSON Knet MAT Missings NCDatasets PackageCompiler PhysOcean PyCall PyPlot Roots SpecialFunctions StableRNGs VideoIO GeoDatasets"

RUN julia --eval 'using Pkg; Pkg.add(split(ENV["JULIA_PACKAGES"]))'

RUN julia --eval 'using Pkg; Pkg.add(url="https://github.com/gher-ulg/OceanPlot.jl")'
RUN julia --eval 'using Pkg; Pkg.add(url="https://github.com/Alexander-Barth/WebDAV.jl")'
RUN julia --eval 'using Pkg; Pkg.add(url="https://github.com/Alexander-Barth/GeoMapping.jl")'
RUN julia --eval 'using Pkg; Pkg.add(url="https://github.com/Alexander-Barth/ROMS.jl")'

ADD emacs /home/jovyan/.emacs

USER root
# avoid warning
# curl: /opt/conda/lib/libcurl.so.4: no version information available (required by curl)
RUN mv -i /opt/conda/lib/libcurl.so.4 /opt/conda/lib/libcurl.so.4-conda

# remove unused kernel
#RUN rm -R /opt/conda/share/jupyter/kernels/python3

USER jovyan

#RUN julia -e 'using IJulia; IJulia.installkernel("Julia with 4 CPUs",env = Dict("JULIA_NUM_THREADS" => "4"))'


# Pre-compiled image with PackageCompiler
# ADD precompile_script.jl .
# ADD make_sysimg.sh .
# RUN ./make_sysimg.sh
# RUN mkdir -p /home/jovyan/.local
# RUN mv sysimg_custom.so precompile_script.jl make_sysimg.sh  trace_compile.jl  /home/jovyan/.local
# RUN rm -f test.xml Water_body_Salinity.3Danl.nc Water_body_Salinity.4Danl.cdi_import_errors_test.csv Water_body_Salinity.4Danl.nc Water_body_Salinity2.4Danl.nc
# RUN julia -e 'using IJulia; IJulia.installkernel("Julia-precompiled", "--sysimage=/home/jovyan/.local/sysimg_custom.so")'
# RUN julia -e 'using IJulia; IJulia.installkernel("Julia-precompiled, 4 CPUs", "--sysimage=/home/jovyan/.local/sysimg_custom.so",env = Dict("JULIA_NUM_THREADS" => "4"))'


#USER root
#RUN jupyter-kernelspec remove -y -f python3
RUN jupyter-kernelspec list
#USER jovyan

#ENV JUPYTER_ENABLE_LAB yes



