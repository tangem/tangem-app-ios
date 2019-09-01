#
# Be sure to run `pod lib lint TangemKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TangemKit'
  s.version          = '0.4.23'
  s.summary          = 'Everything that you need to read Tangem notes'
  s.swift_version    = '4.0'

  s.description      = <<-DESC
Check the values and details of your Tangem notes — special NFC smart cards that can securely carry digital tokens, acting as a highly protected cold wallets with fixed value inside.
                       DESC

  s.homepage         = 'https://github.com/TangemCash/tangem-ios-kit'

  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Tangem' => 'github@tangem.com' }
  s.source           = { :git => 'https://github.com/TangemCash/tangem-ios-kit.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'

  s.source_files = 'TangemKit/TangemKit/Classes/**/*.{swift}'

  s.frameworks = 'CoreNFC'

  s.resources = "TangemKit/TangemKit/Assets/*.xcassets"

  s.dependency 'BigInt'
  s.dependency 'CryptoSwift'
  s.dependency 'SwiftyJSON', '4.2.0'
  s.dependency 'SwiftLint', '0.27.0'
  s.dependency 'GBAsyncOperation', '0.2.0'
  s.dependency 'SwiftCBOR', '0.3'
  s.dependency 'Sodium', '0.8.0'
  s.dependency 'web3.swift.pod'
end
