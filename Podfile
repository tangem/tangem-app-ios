platform :ios, '11.0'
use_frameworks!
target 'Tangem' do
        pod 'BigInt'
        pod 'CryptoSwift'
        pod 'SwiftyJSON'
        pod 'SwiftLint'
        pod 'GBAsyncOperation'
        pod 'SwiftCBOR'
        pod 'Sodium'
        pod 'stellar-ios-mac-sdk', '~> 1.7.2'
        pod 'BinanceChain', :git => 'https://bitbucket.org/tangem/swiftbinancechain.git', :tag => '0.0.4'
        #pod 'BinanceChain', :path => '/Users/alexander.osokin/repos/tangem/SwiftBinanceChain'
        pod 'HDWalletKit', :git => 'https://bitbucket.org/tangem/hdwallet.git', :tag => '0.3.8'
        #pod 'HDWalletKit', :path => '/Users/alexander.osokin/repos/tangem/HDWallet'
        #pod 'web3swift', :path => '/Users/alexander.osokin/repos/tangem/web3swift'
        pod 'web3swift', :git => 'https://bitbucket.org/tangem/web3swift.git', :tag => '2.2.2'
        pod 'Moya'
        pod 'AnyCodable-FlightSchool'
    pod 'QRCode', '2.0'
    pod 'Firebase/Analytics'
    pod 'Firebase/Crashlytics'
    pod 'Firebase/Performance'
   #pod 'TangemSdk', :path => '/TangemSdk'
end

pre_install do |installer|
    # workaround for https://github.com/CocoaPods/CocoaPods/issues/3289
    Pod::Installer::Xcode::TargetValidator.send(:define_method, :verify_no_static_framework_transitive_dependencies) {}
end
