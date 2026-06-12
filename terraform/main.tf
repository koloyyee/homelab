terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.4.0"
    }
  }
}

provider "docker" {
  host = "ssh://loyyeeko@lab"
}

# 1. Network & Volumes
resource "docker_network" "proxy_net" {
  name = "proxy_network"
}

resource "docker_volume" "proxy_data" {
  name = "proxy_data"
}

resource "docker_volume" "proxy_letsencrypt" {
  name = "proxy_letsencrypt"
}

resource "docker_volume" "immich_db" {
  name = "immich_postgres_data"
}

# 2. Edge Gateway 

resource "docker_container" "nginx_proxy" {
  name    = "nginx-proxy-manager"
  image   = "jc21/nginx-proxy-manager:latest"
  restart = "unless-stopped"

  ports {
    internal = 80
    external = 80
  }
  ports {
    internal = 443
    external = 443
  }
  ports {
    internal = 81
    external = 81
  }


  volumes {
    volume_name    = docker_volume.proxy_data.name
    container_path = "/data"
  }

  volumes {
    volume_name    = docker_volume.proxy_letsencrypt.name
    container_path = "/etc/letsencrypt"
  }
  networks_advanced {
    name = docker_network.proxy_net.name
  }
}

# 3. Calibre-Web for Ebooks
resource "docker_container" "calibre_web" {
  name    = "calibre-web"
  image   = "lscr.io/linuxserver/calibre-web:latest"
  restart = "unless-stopped"

  env = [
    "PUID=1000",
    "PGID=1000",
    "TZ=America/Toronto",
    "DOCKER_MODS=linuxserver/mods:universal-calibre"
  ]

  volumes {
    host_path      = "/home/loyyeeko/media/calibre-config"
    container_path = "/config"
  }

  volumes {
    host_path      = "/home/loyyeeko/media/books"
    container_path = "/books"
  }
  networks_advanced {
    name = docker_network.proxy_net.name
  }
}

# 4. Immich for Photo Storage
# 4. Immich for Photo Storage
resource "docker_container" "immich_postgres" {
  name    = "immich-postgres"
  image   = "tensorchord/pgvecto-rs:pg14-v0.2.0"
  restart = "unless-stopped"

  env = [
    "POSTGRES_USER=immich",
    "POSTGRES_PASSWORD=S3cuRe_photo_p@$$",
    "POSTGRES_DB=immich"
  ]

  volumes {
    volume_name    = docker_volume.immich_db.name
    container_path = "/var/lib/postgresql/data"
  }

  networks_advanced {
    name = docker_network.proxy_net.name
  }
}

resource "docker_container" "immich_redis" {
  name    = "redis"
  image   = "redis:6.2-alpine"
  restart = "unless-stopped"
  networks_advanced {
    name = docker_network.proxy_net.name
  }
}

resource "docker_container" "immich_server" {
  name    = "immich-server"
  image   = "ghcr.io/immich-app/immich-server:v1.106.4"
  restart = "unless-stopped"

  env = [
    "DB_HOSTNAME=immich-postgres",
    "DB_USERNAME=immich",
    "DB_PASSWORD=S3cuRe_photo_p@$$",
    "DB_DATABASE_NAME=immich",
    "IMMICH_MEDIA_LOCATION=/usr/src/app/upload"
  ]

  volumes {
    host_path      = "/home/loyyeeko/media/photos"
    container_path = "/usr/src/app/upload"
  }
  networks_advanced {
    name = docker_network.proxy_net.name
  }

  depends_on = [
    docker_container.immich_postgres,
    docker_container.immich_redis
  ]
}
