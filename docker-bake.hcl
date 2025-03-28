group "default" {
  targets = ["pkg"]
}
group "release" {
  targets = ["pkg"]
}
target "pkg" {
  pull = true
  target = "pkg"
  progress = ["plain", "tty"]
  output = [
    "type=local,dest=dist"
  ]
  buildkit = true
  context = "."
  dockerfile = "Dockerfile"
  networks = ["host"]
}

target "pkg-armv6" {
  inherits = ["pkg"]
  platforms = [
    "linux/arm/v6"
  ]
  args = {
    ARCH = "linux/arm/v6"
  }
}

target "pkg-amd64" {
  inherits = ["pkg"]
  platforms = [
    "linux/amd64"
  ]
  args = {
    ARCH = "linux/amd64"
  }
}

targt "pkg-all" {
  inherits = ["pkg-cross"]
  name = "pkg"
  matrix = {
    env = ["release", "debug"]
  }
  outputs = [
    "type=local,dest=dist"
  ]
}
