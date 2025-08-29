# define the standard colors
ifneq ($(findstring xterm,${TERM}),)
	# check if the terminal supports color
	override COLOR_BLACK := $(shell tput -Txterm setaf 0)
	override COLOR_RED := $(shell tput -Txterm setaf 1)
	override COLOR_GREEN := $(shell tput -Txterm setaf 2)
	override COLOR_BLUE := $(shell tput -Txterm setaf 4)
	override COLOR_CYAN := $(shell tput -Txterm setaf 6)
	override COLOR_WHITE := $(shell tput -Txterm setaf 7)
	override COLOR_RESET := $(shell tput -Txterm sgr0)
else
	override COLOR_BLACK := ""
	override COLOR_RED := ""
	override COLOR_GREEN := ""
	override COLOR_BLUE := ""
	override COLOR_CYAN := ""
	override COLOR_WHITE := ""
	override COLOR_RESET := ""
endif

IMAGE_NAME ?= dockertrainsam
TAG ?= latest
DOCKERFILE ?= docker/Dockerfile.dgx
CONTEXT ?= .

.PHONY: builddocker
builddocker:
	@set -e; \
	docker build -f $(DOCKERFILE) -t $(IMAGE_NAME):$(TAG) $(CONTEXT)
	echo "${COLOR_CYAN}finished building docker image ${IMAGE_NAME}:${TAG} ${COLOR_RESET}"

CONTAINER_NAME ?= trainsam
DATA_PATH ?= .

.PHONY: rundocker
rundocker:
	@set -e; \
	# allow GUI in container to reach host.
	xhost +local:docker; \
	docker run -it \
	    --env="DISPLAY=${DISPLAY}" \
	    --env="QT_X11_NO_MITSHM=1" \
	    --gpus all \
	    --ipc=host \
	    --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
	    --volume="/usr/local:/usr/local" \
	    --volume="$(shell pwd)/..:/root/code:rw" \
	    --volume="${DATA_PATH}:/root/data:rw" \
	    --volume="/dev/shm:/dev/shm:rw" \
	    --name=${CONTAINER_NAME} \
	    ${IMAGE_NAME}; \
	echo "${COLOR_CYAN}finished building docker container ${CONTAINER_NAME}${COLOR_RESET}"

.PHONY: execdocker
execdocker:
	@set -e; \
	if [ -n "$$(docker ps -q -f name=^/${CONTAINER_NAME}$$)" ]; then \
	    echo "${COLOR_CYAN}container ${CONTAINER_NAME} is already running. Executing into it..${COLOR_RESET}"; \
	else \
	    if [ -n "$$(docker ps -aq -f name=^/${CONTAINER_NAME}$$)" ]; then \
	        echo "${COLOR_CYAN}starting existing container ${CONTAINER_NAME}...${COLOR_RESET}"; \
		docker start -ai ${CONTAINER_NAME}; \
	    else \
	        echo "${COLOR_RED}container ${CONTAINER_NAME} does not exist. Stop.${COLOR_RESET}"; \
	    fi; \
	    exit 0; \
	fi; \
	docker exec -it ${CONTAINER_NAME} /bin/bash
