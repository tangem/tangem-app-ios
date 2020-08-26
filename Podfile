platform :ios, '13.0'
use_frameworks!
inhibit_all_warnings!
target 'Tangem' do
        pod 'BigInt'
        pod 'CryptoSwift'
        pod 'SwiftyJSON'
        pod 'SwiftLint'
        pod 'GBAsyncOperation'
        pod 'SwiftCBOR'
        pod 'Sodium'
        pod 'stellar-ios-mac-sdk'
        pod 'BinanceChain', :git => 'https://bitbucket.org/tangem/swiftbinancechain.git', :tag => '0.0.6'
           #pod 'BinanceChain', :path => '/Users/alexander.osokin/repos/tangem/SwiftBinanceChain'
        pod 'HDWalletKit', :git => 'https://bitbucket.org/tangem/hdwallet.git', :tag => '0.3.8'
           #pod 'HDWalletKit', :path => '/Users/alexander.osokin/repos/tangem/HDWallet'
           #pod 'web3swift', :path => '/Users/alexander.osokin/repos/tangem/web3swift'
        pod 'web3swift', :git => 'https://bitbucket.org/tangem/web3swift.git', :tag => '2.2.3'
        pod 'Moya'
        pod 'AnyCodable-FlightSchool'
    pod 'QRCode', '2.0'
    pod 'Firebase/Analytics'
    pod 'Firebase/Crashlytics'
    pod 'Firebase/Performance'
    pod 'KeychainSwift'
    pod 'TangemSdk', :git => 'git@bitbucket.org:tangem/card-sdk-swift.git', :tag => 'build-46'
    #pod 'TangemSdk', :path => '../card-sdk-swift'

    #pod 'BlockchainSdk', :path => '/Users/alexander.osokin/repos/tangem/tangem-ios/BlockchainSdk'
end

pre_install do |installer|
    # workaround for https://github.com/CocoaPods/CocoaPods/issues/3289
    Pod::Installer::Xcode::TargetValidator.send(:define_method, :verify_no_static_framework_transitive_dependencies) {}
end

post_install do |installer|
  oldTargets = ['QRCode']

  installer.pods_project.targets.each do |target|
    if oldTargets.include? target.name
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '4.2'
        #Убирает issues в XCode
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = "YES"
      end
      end
    end
  end
