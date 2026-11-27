#
# CocoaPods spec for apps that don't use Swift Package Manager.
# Sources are shared with the Swift package in cupertino_native/.
#
Pod::Spec.new do |s|
  s.name             = 'cupertino_native'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'cupertino_native/Sources/cupertino_native/**/*.swift'
  s.resource_bundles = {'cupertino_native_privacy' => ['cupertino_native/Sources/cupertino_native/PrivacyInfo.xcprivacy']}
  s.dependency 'Flutter'
  s.platform = :ios, '18.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
