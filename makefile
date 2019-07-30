################################################################################
# variables
################################################################################

build_dir=build
context_dir=context

cache_clean=false
cache_enabled=true

os_name=alpine
os_version=3.10

git_changes=$(shell [[ -z $$(git status -s) ]] && echo "s" || echo "m")
git_commits_hash=$(shell git rev-list HEAD | md5sum | cut -c 1-4)
git_commits=$(shell git rev-list --count HEAD)
git_suffix=$(git_commits)$(git_changes)-$(git_commits_hash)

dockerfile=Dockerfile.$(os_name)
ocimage_registry=docker.io
ocimage_name=iwana/adoc-builder
ocimage_tag=$(git_suffix)

container_name_prefix=oci-adoc_builder-

docker_build_cmd=DOCKER_BUILDKIT=1 docker image build
docker_build_args= \
	--progress plain \
	--force-rm \
	--network host \
	--build-arg "os_name=$(os_name)" \
	--build-arg "os_version=$(os_version)" \
	--build-arg "cache_clean=$(cache_clean)" \
	--build-arg "cache_enabled=$(cache_enabled)" \

docker_build=$(docker_build_cmd) $(docker_build_args)
dockerfile_translate=sed -E 's|^\s*RUN\s+|RUN --mount=type=cache,id=$(os_name)-$(os_version)-var-cache,target=/var/cache/ |g'

################################################################################
# rules
################################################################################

.PHONY: ALWAYS

define newline


endef

$(build_dir)/:
	mkdir $(@)

dockerfile_translated=$(build_dir)/$(notdir $(dockerfile)).translated

$(dockerfile_translated): $(dockerfile) | build/
	cat $(dockerfile) | $(dockerfile_translate) > $(dockerfile_translated)

ocimage_tags = \
	$(ocimage_registry)/$(ocimage_name):latest \
	$(ocimage_registry)/$(ocimage_name):$(ocimage_tag) \

ocimage_tags_staging = \
	stage.null/$(ocimage_name):latest \
	stage.null/$(ocimage_name):$(ocimage_tag) \

build-ocimage: $(dockerfile_translated) | context/
	$(docker_build) \
		$(foreach tag,$(ocimage_tags),--tag $(tag)) \
		$(foreach tag,$(ocimage_tags_staging),--tag $(tag)) \
		--file $(dockerfile_translated) $(context_dir)/

push-ocimage: build-ocimage
	$(foreach tag,$(ocimage_tags),docker push $(tag)$(newline))

container_run_args= \
	--rm \
	--volume /etc/localtime:/etc/localtime:ro \
	--volume cache-$(os_name)-$(os_version)-var-cache:/var/cache \
	--name $(container_name_prefix)$(@) \

run-ocimage: build-ocimage
	docker container run $(container_run_args) -it $(lastword $(ocimage_tags_staging))

run-ocimage-shell: build-ocimage
	docker container run $(container_run_args) -it $(lastword $(ocimage_tags_staging)) busybox sh

run-ocimage-shell-root: build-ocimage
	docker container run $(container_run_args) -it --user root:root --privileged $(lastword $(ocimage_tags_staging)) busybox sh

################################################################################
# ...
################################################################################
