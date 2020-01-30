#
# Be sure to run `pod lib lint TangemSdk.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TangemSdk'
  s.version          = '0.1.0'
  s.summary          = 'Use TangemSdk for Tangem cards integration'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Use TangemSdk for Tangem cards integration
                       DESC

  s.homepage         = 'https://github.com/TangemCash/tangem-sdk-ios'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Tangem AG' => '' }
  s.source           = { :git => 'https://github.com/TangemCash/tangem-sdk-ios.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '11.0'

  s.source_files = 'TangemSdk/TangemSdk/**/*'
  
  # s.resource_bundles = {
  #   'TangemSdk' => ['TangemSdk/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'

  s.dependency 'secp256k1.swift'
  s.dependency 'KeychainSwift'
end