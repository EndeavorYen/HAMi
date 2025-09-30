#!/usr/bin/env bash
set -euo pipefail

# Interactive helper script to build and run the hami docker image.
# Usage: ./test.sh    (then follow prompts)

IMG_TAG_DEFAULT="hami:latest"

function build_image() {
	local img_tag="$1"
	echo "Building image ${img_tag} using: make docker IMG_TAG=${img_tag}"
	if ! command -v make >/dev/null 2>&1; then
		echo "Error: 'make' not found in PATH." >&2
		return 2
	fi
	git submodule update --init --recursive
    make docker IMG_TAG="${img_tag}"
}

function run_container() {
	local img_tag="$1"

	echo "正在從映像檔 ${img_tag} 執行容器"
	# 我們不再需要預先創建任何 host 目錄，因為 overrideEnv 將在容器內創建
	docker run -it --rm --gpus all \
	  -v "$(pwd)/inference.py:/app/inference.py" \
	  -e LD_PRELOAD=/k8s-vgpu/lib/nvidia/libvgpu.so.v0.0.1 \
	  --entrypoint /bin/bash "${img_tag}"
}

function prompt() {
	local msg="$1"
	local default="$2"
	local ans
	if [ -t 0 ]; then
		read -r -p "${msg}" ans || ans=""
	else
		# Non-interactive: use default
		ans="${default}"
	fi
	if [ -z "${ans}" ]; then
		echo "${default}"
	else
		echo "${ans}"
	fi
}

function show_menu() {
	echo "Select action:"
	echo "  1) build image"
	echo "  2) run container"
	echo "  3) build then run"
	echo "  q) quit"
}

while true; do
	show_menu
	choice=$(prompt "Enter choice [1/2/3/q]: " "1")
	case "${choice}" in
		1)
			img_tag=$(prompt "Image tag (default ${IMG_TAG_DEFAULT}): " "${IMG_TAG_DEFAULT}")
			echo "About to run: make docker IMG_TAG=${img_tag}"
			confirm=$(prompt "Proceed? [y/N]: " "N")
			if [[ "${confirm,,}" == "y" ]]; then
				build_image "${img_tag}"
				echo "Build finished."
			else
				echo "Cancelled."
			fi
			;;
		2)
			img_tag=$(prompt "Image tag to run (default ${IMG_TAG_DEFAULT}): " "${IMG_TAG_DEFAULT}")
			echo "About to run the container with image: ${img_tag}"
			confirm=$(prompt "Proceed? [y/N]: " "N")
			if [[ "${confirm,,}" == "y" ]]; then
				run_container "${img_tag}"
			else
				echo "Cancelled."
			fi
			;;
		3)
			img_tag=$(prompt "Image tag (default ${IMG_TAG_DEFAULT}): " "${IMG_TAG_DEFAULT}")
			echo "About to build and then run image: ${img_tag}"
			confirm=$(prompt "Proceed? [y/N]: " "N")
			if [[ "${confirm,,}" == "y" ]]; then
				build_image "${img_tag}"
				echo "Build finished. Starting container..."
				run_container "${img_tag}"
			else
				echo "Cancelled."
			fi
			;;
		q|Q)
			echo "Goodbye."
			exit 0
			;;
		*)
			echo "Invalid choice: ${choice}";;
	esac
	echo ""
done

