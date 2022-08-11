
## Build

```
sudo docker build --no-cache  --tag abarth/julia-gher:$(date --utc +%Y-%m-%dT%H%M)  --tag abarth/julia-gher:latest .
docker push abarth/divand-jupyterhub:latest
```

Link to registery:

https://hub.docker.com/repository/docker/abarth/julia-gher

