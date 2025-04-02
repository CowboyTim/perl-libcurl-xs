group "default" {
  targets = ["pkg-armhf"]
}
group "release" {
  targets = ["pkg-armhf"]
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

target "pkg-armhf" {
  inherits = ["pkg"]
  platforms = [
    "linux/armhf"
  ]
  args = {
    ARCH = "linux/armhf"
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
