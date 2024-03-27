# build as:
# sudo docker build  --tag abarth/julia-gher:$(date --utc +%Y-%m-%dT%H%M)  --tag abarth/julia-gher:latest .


FROM jupyterhub/singleuser:4.1

MAINTAINER Alexander Barth <a.barth@ulg.ac.be>

EXPOSE 8888

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        emacs-nox \
        g++ \
        gcc \
        gfortran \
        git \
        less \
        libarpack2-dev \
        libnetcdf-dev \
        libnetcdff-dev \
        libnlopt0 \
        libopenmpi-dev \
        make \
        netcdf-bin \
        openmpi-bin \
        perl \
        subversion \
        tmux \
        unzip


ENV JUPYTER=/opt/conda/bin/jupyter
ENV PYTHON=/opt/conda/bin/python
ENV LD_LIBRARY_PATH=/opt/conda/lib/

RUN conda install -y ipywidgets matplotlib
RUN conda install -c conda-forge jupyterlab-git
RUN conda install -c conda-forge motuclient==1.8.6

# Install julia
ADD install_julia.sh .
RUN bash install_julia.sh; rm install_julia.sh

# # Install Pluto
# RUN git clone https://github.com/fonsp/pluto-on-jupyterlab
# RUN cd pluto-on-jupyterlab && \
#     git checkout ea3184d && \
#     julia --eval "using Pkg; Pkg.Registry.update(); Pkg.instantiate();"
# RUN chown -R jovyan /home/jovyan/.julia

# RUN jupyter labextension install @jupyterlab/server-proxy && \
#     jupyter lab build && \
#     jupyter lab clean && \
#     cd pluto-on-jupyterlab && pip install . --no-cache-dir && \
#     rm -rf ~/.cache

# Emacs configuration
RUN wget -O /usr/share/emacs/site-lisp/julia-mode.el https://raw.githubusercontent.com/JuliaEditorSupport/julia-emacs/master/julia-mode.el

# avoid warning
# curl: /opt/conda/lib/libcurl.so.4: no version information available (required by curl)
RUN mv -i /opt/conda/lib/libcurl.so.4 /opt/conda/lib/libcurl.so.4-conda

# remove unused kernel
#RUN rm -R /opt/conda/share/jupyter/kernels/python3

# install packages as user (to that the user can temporarily update them if necessary)
# and precompilation

USER jovyan

ENV LD_LIBRARY_PATH=
ENV JULIA_PACKAGES="CSV DataAssim DIVAnd DataStructures FFTW FileIO Glob HTTP IJulia ImageIO Images Interact Interpolations JSON MAT Missings NCDatasets PackageCompiler PhysOcean PyCall PyPlot PythonPlot Roots SpecialFunctions StableRNGs VideoIO GeoDatasets GeoMapping DINCAE Pluto PlutoUI CUDA Downloads URIs"

RUN julia --eval 'using Pkg; Pkg.add(split(ENV["JULIA_PACKAGES"]))'
RUN julia --eval 'using Pkg; Pkg.add(url="https://github.com/gher-ulg/OceanPlot.jl")'
RUN julia --eval 'using Pkg; Pkg.add(url="https://github.com/Alexander-Barth/WebDAV.jl")'
RUN julia --eval 'using Pkg; Pkg.add(url="https://github.com/Alexander-Barth/ROMS.jl")'
RUN julia --eval 'using Pkg; Pkg.add(url="https://github.com/gher-uliege/DINCAE_utils.jl")'

ADD emacs /home/jovyan/.emacs

RUN julia -e 'using IJulia; IJulia.installkernel("Julia with 4 CPUs",env = Dict("JULIA_NUM_THREADS" => "4"))'

# Pre-compiled image with PackageCompiler
# ADD precompile_script.jl .
# ADD make_sysimg.sh .
# RUN ./make_sysimg.sh
# RUN mkdir -p /home/jovyan/.local
# RUN mv sysimg_custom.so precompile_script.jl make_sysimg.sh  trace_compile.jl  /home/jovyan/.local
# RUN rm -f test.xml Water_body_Salinity.3Danl.nc Water_body_Salinity.4Danl.cdi_import_errors_test.csv Water_body_Salinity.4Danl.nc Water_body_Salinity2.4Danl.nc
# RUN julia -e 'using IJulia; IJulia.installkernel("Julia-precompiled", "--sysimage=/home/jovyan/.local/sysimg_custom.so")'
# RUN julia -e 'using IJulia; IJulia.installkernel("Julia-precompiled, 4 CPUs", "--sysimage=/home/jovyan/.local/sysimg_custom.so",env = Dict("JULIA_NUM_THREADS" => "4"))'

USER root

# Install DINEOF
RUN cd /root && \
    git clone https://github.com/Aida-Alvera/DINEOF && \
    cd DINEOF && \
    cp config.mk.template config.mk && \
    make && \
    cp dineof /usr/local/bin

# PyPlot issue
# ImportError("/opt/julia-1.8.3/bin/../lib/julia/libstdc++.so.6: version `GLIBCXX_3.4.30' not found (required by /opt/conda/lib/python3.10/site-packages/contourpy/_contourpy.cpython-310-x86_64-linux-gnu.so)")
#RUN rm /opt/julia-1.8.3//lib/julia/libstdc++.so.6  /opt/julia-1.8.3/lib/julia/libstdc++.so.6.0.29
#RUN jupyter-kernelspec remove -y -f python3
USER jovyan

RUN jupyter-kernelspec list
ENV JUPYTER_ENABLE_LAB yes
