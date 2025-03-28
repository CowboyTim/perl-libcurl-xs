group "default" {
  targets = ["pkg"]
}
group "release" {
  targets = ["pkg"]
}
target "pkg" {
  pull = true
  name = "pkg"
  target = "pkg"
  matrix = {
    env = ["release"]
  }
  progress = ["plain", "tty"]
  output = [
    "type=local,dest=dist"
  ]
  buildkit = true
  context = "."
  dockerfile = "Dockerfile"
  networks = ["host"]
  platforms = [
    "linux/arm/v6"
  ]
}
