jupyterhub:
  proxy:
    secretToken: "${proxy_secret}"
  hub:
    services:
      dask-gateway:
        apiToken: "${gateway_secret}"

dask-gateway:
  gateway:
    auth:
      jupyterhub:
        apiToken: "${gateway_secret}"