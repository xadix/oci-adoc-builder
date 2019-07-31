# oci-adoc-builder

```bash
docker login docker.io

make build-ocimage
make run-ocimage-shell
make push-ocimage
```

```bash
make run-ocimage-shell-root container_run_args+=" --volume=${HOME}/d/gitlab.com/iwana-pub/templates/adoc:/var/tmp/adoc"
```

```bash
git tag v$(date +%Y%m%d%H%M%S)
git push --tags
git show-ref
```
