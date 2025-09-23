# Docker Bake file for Faustedition multi-stage build

variable "REGISTRY" {
  default = "thvitt"
}

variable "TAG" {
  default = "latest"
}

variable "MACROGEN_RENDER_TIMEOUT" {
  default = ""
}

group "default" {
  targets = ["www", "exist", "macrogen", "downloadserver"]
}

group "all" {
  targets = ["build", "www", "exist", "macrogen-build", "macrogen", "downloadserver"]
}

target "build" {
  dockerfile = "Dockerfile"
  target = "build"
  tags = ["${REGISTRY}/faustedition-build:${TAG}"]
  args = {
    MACROGEN_RENDER_TIMEOUT = "${MACROGEN_RENDER_TIMEOUT}"
  }
  platforms = ["linux/amd64"]
  output = ["type=docker"]
  call = "build"
  args-map = {
    "--security-opt" = "apparmor=unconfined"
  }
}

target "www" {
  dockerfile = "Dockerfile"
  target = "www"
  tags = [
    "${REGISTRY}/faustedition-www:${TAG}",
    "${REGISTRY}/faustedition-www:latest"
  ]
  labels = {
    "org.containers.image.authors" = "Thorsten Vitt <thorsten.vitt@uni-wuerzburg.de>, Faustedition <info@faustedition.net>"
    "org.opencontainers.image.url" = "https://faustedition.net/"
    "org.opencontainers.image.source" = "https://github.com/faustedition/faust-gen-docker"
    "org.opencontainers.image.title" = "Faustedition Web-Frontend"
  }
}

target "exist" {
  dockerfile = "Dockerfile"
  target = "exist"
  tags = [
    "${REGISTRY}/faustedition-exist:${TAG}",
    "${REGISTRY}/faustedition-exist:latest"
  ]
  labels = {
    "org.containers.image.authors" = "Thorsten Vitt <thorsten.vitt@uni-wuerzburg.de>, Faustedition <info@faustedition.net>"
    "org.opencontainers.image.url" = "https://faustedition.net/"
    "org.opencontainers.image.source" = "https://github.com/faustedition/faust-gen-docker"
    "org.opencontainers.image.title" = "Faustedition eXist Database"
  }
}

target "macrogen-build" {
  dockerfile = "Dockerfile"
  target = "macrogen-build"
  tags = ["${REGISTRY}/faustedition-macrogen-build:${TAG}"]
  labels = {
    "org.containers.image.authors" = "Thorsten Vitt <thorsten.vitt@uni-wuerzburg.de>, Faustedition <info@faustedition.net>"
    "org.opencontainers.image.url" = "https://faustedition.net/"
    "org.opencontainers.image.source" = "https://github.com/faustedition/faust-gen-docker"
    "org.opencontainers.image.title" = "Faustedition Macrogenesis Build Stage"
  }
}

target "macrogen" {
  dockerfile = "Dockerfile"
  target = "macrogen"
  tags = [
    "${REGISTRY}/faustedition-macrogen:${TAG}",
    "${REGISTRY}/faustedition-macrogen:latest"
  ]
  labels = {
    "org.containers.image.authors" = "Thorsten Vitt <thorsten.vitt@uni-wuerzburg.de>, Faustedition <info@faustedition.net>"
    "org.opencontainers.image.url" = "https://faustedition.net/"
    "org.opencontainers.image.source" = "https://github.com/faustedition/faust-gen-docker"
    "org.opencontainers.image.title" = "Faustedition Macrogenesis Subgraph Service"
  }
}

target "downloadserver" {
  dockerfile = "Dockerfile"
  target = "downloadserver"
  tags = [
    "${REGISTRY}/faustedition-downloads:${TAG}",
    "${REGISTRY}/faustedition-downloads:latest"
  ]
  labels = {
    "org.containers.image.authors" = "Thorsten Vitt <thorsten.vitt@uni-wuerzburg.de>, Faustedition <info@faustedition.net>"
    "org.opencontainers.image.url" = "https://faustedition.net/"
    "org.opencontainers.image.source" = "https://github.com/faustedition/faust-gen-docker"
    "org.opencontainers.image.title" = "Faustedition Facsimile Download Server"
  }
}
