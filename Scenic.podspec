Pod::Spec.new do |s|
  s.name         = "Scenic"
  s.version      = "0.2.0"
  s.summary      = "A library for declaratively defining navigation hierarchies in iOS using simple data structures."
  s.homepage     = "https://github.com/sdduursma/Scenic"
  s.license      = "MIT"
  s.author       = "Samuel Duursma"
  s.platform     = :ios, "11.0"
  s.source       = { :git => "https://github.com/sdduursma/Scenic.git", :tag => s.version }
  s.source_files = "Scenic/*.swift"
end
