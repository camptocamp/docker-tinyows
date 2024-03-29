# Docker image for TinyOWS

Here is a sample Dockerfile for using it:

```
FROM camptocamp/tinyows

COPY tinyows.xml /etc/mapserver/
```

The main configuration file should be `/etc/mapserver/tinyows.xml`.

Or you can use the image as is and mount volumes to customize it.

Only tags for minor releases exist, not tag for bug fixes.

## Tuning

You can use the following environment variables (when starting the container)
to tune it:

- `MAX_REQUESTS_PER_PROCESS`: To work around memory leaks (defaults to `1000`)
- `TINYOWS_CATCH_SEGV`: `1` to enable catchsegv

## Contributing

Install the pre-commit hooks:

```bash
pip install pre-commit
pre-commit install --allow-missing-config
```
