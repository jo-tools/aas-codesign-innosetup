#!/bin/sh
#
# build.sh <VERSION> [--push]
#
# Builds the Docker Image for linux/amd64 and linux/arm64 locally:
#   ${DOCKERIMAGE}:<VERSION>-amd64
#   ${DOCKERIMAGE}:<VERSION>-arm64
#
# Only with --push:
#   pushes both images and creates the multi arch tags
#   ${DOCKERIMAGE}:<VERSION> and ${DOCKERIMAGE}:latest

set -eu

DOCKERIMAGE=jotools/innosetup
VERSION=${1:-}
PUSH=${2:-}

if [ -z "${VERSION}" ]; then
	echo "ERROR: \$VERSION is empty."
	echo "Usage: build.sh <VERSION> [--push]"
	exit 1
fi
if [ -n "${PUSH}" ] && [ "${PUSH}" != "--push" ]; then
	echo "ERROR: unknown parameter: ${PUSH}"
	echo "Usage: build.sh <VERSION> [--push]"
	exit 1
fi

cd "$(dirname "$0")"

for ARCH in amd64 arm64; do
	echo "Building ${DOCKERIMAGE}:${VERSION}-${ARCH}"
	docker buildx build --no-cache --load --platform "linux/${ARCH}" -t "${DOCKERIMAGE}:${VERSION}-${ARCH}" .

	echo "Testing ${DOCKERIMAGE}:${VERSION}-${ARCH}"
	# installed versions must match the versions defined in the Dockerfile
	if ! docker run --rm --platform "linux/${ARCH}" --entrypoint sh "${DOCKERIMAGE}:${VERSION}-${ARCH}" \
		-c 'test "$(jsign --version)" = "Jsign ${JSIGN_VERSION}" && test "$(wine "${ISCC_EXE}" --version 2>/dev/null | tr -d "\r")" = "${INNOSETUP_VERSION}"'; then
		echo "ERROR: Test failed: ${DOCKERIMAGE}:${VERSION}-${ARCH}"
		exit 1
	fi
done

if [ "${PUSH}" != "--push" ]; then
	echo "Built locally (not pushed): ${DOCKERIMAGE}:${VERSION}-amd64 ${DOCKERIMAGE}:${VERSION}-arm64"
	exit 0
fi

echo "Pushing ${DOCKERIMAGE}:${VERSION}"
docker push "${DOCKERIMAGE}:${VERSION}-amd64"
docker push "${DOCKERIMAGE}:${VERSION}-arm64"

# create multi arch tags <VERSION> and latest
docker buildx imagetools create \
	-t "${DOCKERIMAGE}:${VERSION}" \
	-t "${DOCKERIMAGE}:latest" \
	"${DOCKERIMAGE}:${VERSION}-amd64" \
	"${DOCKERIMAGE}:${VERSION}-arm64"
