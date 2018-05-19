Pod::Spec.new do |s|
  s.name         = "MMDSceneKit"
  s.version      = "0.3.2"
  s.summary      = "SceneKit expansion for MikuMikuDance"
  s.homepage     = "https://github.com/magicien/MMDSceneKit"
  s.screenshots  = "https://raw.githubusercontent.com/magicien/MMDSceneKit/master/screenshot.png"
  s.license      = "MIT"
  s.author       = { "magicien" => "magicien.du.ballon@gmail.com" }
  s.ios.deployment_target = "11.0"
  s.osx.deployment_target = "10.13"
  s.tvos.deployment_target = "11.0"
  s.source       = { :git => "https://github.com/magicien/MMDSceneKit.git", :tag => "v#{s.version}" }
  s.source_files = "Source/**/*.{swift,metal}"
  s.resource     = "Source/**/*.shader", "Source/**/*.bmp"
  s.pod_target_xcconfig = {
    "SWIFT_VERSION" => "4.0"
  }
end
