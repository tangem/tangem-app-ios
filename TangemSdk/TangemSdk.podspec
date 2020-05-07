#
# Be sure to run `pod lib lint TangemSdk.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TangemSdk'
  s.version          = '2.0.2'
  s.summary          = 'Use TangemSdk for Tangem cards integration'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Tangem is a Swiss-based secure hardware wallet manufacturer that enables blockchain-based assets to be kept in custody within smart physical banknotes and accessed via NFC technology. Tangem’s mission is to make digital assets accessible, affordable and convenient for consumers.
                       DESC

  s.homepage         = 'https://github.com/Tangem/tangem-sdk-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Tangem' => 'hello@tangem.com' }
  s.source           = { :git => 'https://github.com/Tangem/tangem-sdk-ios.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Tangem'

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'
  s.source_files = 'TangemSdk/TangemSdk/**/*.{h,m,swift,c}'
  s.preserve_paths = 'TangemSdk/TangemSdk/Crypto/Ed25519/CEd25519/*.{modulemap}'
  s.pod_target_xcconfig = {
      'SWIFT_INCLUDE_PATHS' => '$(PODS_TARGET_SRCROOT)/TangemSdk/TangemSdk/Crypto/Ed25519/CEd25519/**'
  }

  # s.resource_bundles = {
  #   'TangemSdk' => ['TangemSdk/Assets/*.png']
  # 

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'

  s.resource_bundle = { "TangemSdk" => ["TangemSdk/TangemSdk/**/*.lproj/*.strings"] }

  s.dependency 'secp256k1.swift'
  s.dependency 'KeychainSwift'
end