
Pod::Spec.new do |s|


  s.name         = "FDFullscreenPopGesture_ysghome"
  s.version      = "1.1.1"
  s.summary      = "FDFullscreenPopGesture库添加滚动视图，右滑返回功能。"

  s.description  = <<-DESC
                   FDFullscreenPopGesture库添加滚动视图，右滑返回功能

  s.homepage     = "https://github.com/ysghome/FDFullscreenPopGesture"
  s.license      = "MIT"
  s.author             = { "ysghome" => "ysghome@163.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/ysghome/FDFullscreenPopGesture.git", :tag => "1.1.1" }
  s.source_files  = "FDFullscreenPopGesture", "FDFullscreenPopGesture/**/*.{h,m}"
  s.frameworks = "Foundation"

end
