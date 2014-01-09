Pod::Spec.new do |s|
  s.name         = "KFAppTaxi"
  s.version      = "0.1.0"
  s.summary      = "AdHoc AppDistribution Plattform with integrated Crash Reporting."
  s.description  = <<-DESC
                   AppTaxi is an AdHoc AppDistribution Plattform with integrated Crash Reporting.
                   DESC
  s.homepage     = "https://github.com/kfinteractive/KFAppTaxi.git"
  s.license      = 'MIT'
  s.authors       = { "Gunnar Herzog" => "gunnar.herzog@kf-interactive.com", "Rico Becker" => "rico.becker@kf-interactive.com" }
  s.source       = { :git => "https://github.com/kfinteractive/KFAppTaxi.git", :tag => s.version.to_s }

  s.platform     = :ios, '6.0'
  s.ios.deployment_target = '6.0'
  #s.osx.deployment_target = '10.8'
  s.requires_arc = true

  s.ios.source_files = 'Classes/ios/**/*'
  s.ios.resource = 'Assets/ios/KFAppTaxi.bundle'
  s.ios.framework = 'SystemConfiguration'

  s.ios.exclude_files = 'Classes/osx'
  #s.osx.exclude_files = 'Classes/ios'
  
  s.ios.public_header_files = 'Classes/ios/*.h'
  #s.osx.public_header_files = 'Classes/osx/*.h'
  
  s.ios.vendored_frameworks = 'Assets/ios/CrashReporter.framework'
end
