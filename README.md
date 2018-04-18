# Docker image for mapserver master

Here is a sample Dockerfile for using it:
```
FROM camptocamp/tinyows

COPY tinyows.xml /etc/mapserver/
```

The main configuration file should be `/etc/mapserver/tinyows.xml`.

Or you can use the image as is and mount volumes to customize it.

Only tags for minor releases exist, not tag for bug fixes.

## Tunings

You can use the following environment variables (when starting the container)
to tune it:
* MAX_REQUESTS_PER_PROCESS: To work around memory leaks (defaults to 1000)
