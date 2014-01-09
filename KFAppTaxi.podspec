Pod::Spec.new do |s|
  s.name         = "KFAppTaxi"
  s.version      = "0.1.0"
  s.summary      = "AdHoc AppDistribution Plattform with integrated Crash Reporting."
  s.description  = <<-DESC
                   AppTaxi is an AdHoc AppDistribution Plattform with integrated Crash Reporting.
                   DESC
  s.homepage     = "http://app-taxi.com"
  s.license      = 'MIT'
  s.author       = { "Gunnar Herzog" => "gunnar.herzog@kf-interactive.com", "Rico Becker" => "rico.becker@kf-interactive.com" }
  s.source       = { :git => "http://EXAMPLE/NAME.git", :tag => s.version.to_s }

  s.platform     = :ios, '6.0'
  s.ios.deployment_target = '6.0'
  #s.osx.deployment_target = '10.8'
  s.requires_arc = true

  s.ios.source_files = 'Classes/ios/**/*'
  s.ios.resources = 'Assets/ios'

  s.ios.exclude_files = 'Classes/osx'
  #s.osx.exclude_files = 'Classes/ios'
  
  s.ios.public_header_files = 'Classes/ios/*.h'
  #s.osx.public_header_files = 'Classes/osx/*.h'
  
  s.ios.vendored_frameworks = 'Assets/ios/CrashReporter.framework'
end
