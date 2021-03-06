#
# Be sure to run `pod lib lint RelayServiceKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "RelayServiceKit"
  s.version          = "0.9.0"
  s.summary          = "An Objective-C library for communicating with the Forsta Relay messaging service."

  s.description      = <<-DESC
An Objective-C library for communicating with the Signal messaging service.
  DESC

  s.homepage         = "https://github.com/ForstaLabs/RelayServiceKit"
  s.license          = 'GPLv3'
  s.author           = { "Frederic Jacobs" => "github@fredericjacobs.com" }
  s.source           = { :git => "https://github.com/ForstaLabs/RelayServiceKit.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/ForstaInc'

  s.platform     = :ios, '9.0'
  #s.ios.deployment_target = '9.0'
  #s.osx.deployment_target = '10.9'
  s.requires_arc = true
  s.source_files = 'RelayServiceKit/src/**/*.{h,m,mm,swift}'

  # We want to use modules to avoid clobbering CocoaLumberjack macros defined
  # by other OWS modules which *also* import CocoaLumberjack. But because we
  # also use Objective-C++, modules are disabled unless we explicitly enable
  # them
  s.compiler_flags = "-fcxx-modules"

  s.prefix_header_file = 'RelayServiceKit/src/TSPrefix.h'
  s.xcconfig = { 'OTHER_CFLAGS' => '$(inherited) -DSQLITE_HAS_CODEC' }

  s.resources = ["RelayServiceKit/Resources/Certificates/*"]

  s.dependency 'Curve25519Kit'
  s.dependency 'CocoaLumberjack'
  s.dependency 'AFNetworking'
  s.dependency 'AxolotlKit'
  s.dependency 'Mantle'
  s.dependency 'YapDatabase/SQLCipher'
  s.dependency 'SocketRocket'
  s.dependency 'libPhoneNumber-iOS'
  s.dependency 'GRKOpenSSLFramework'
  s.dependency 'SAMKeychain'
  s.dependency 'Reachability'
  s.dependency 'SwiftProtobuf'
  s.dependency 'ProtocolBuffers'
  s.dependency 'SignalCoreKit'
  s.dependency 'PromiseKit', "= 6.7.1"

end
