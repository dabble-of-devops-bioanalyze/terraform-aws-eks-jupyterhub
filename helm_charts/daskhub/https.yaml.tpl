jupyterhub:
  proxy:
    https:
      enabled: true
      hosts:
        - "${daskhub_subdomain}.${daskhub_domain}"
      letsencrypt:
        contactEmail: "${letsencrypt_email}"