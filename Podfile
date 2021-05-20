# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'
        pod 'SwiftyJSON'

target 'Tangem Tap' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  inhibit_all_warnings!

  # Pods for Tangem Tap
  pod 'AnyCodable-FlightSchool'
  
  pod 'BinanceChain', :git => 'https://github.com/lazutkin-andrey/swiftbinancechain.git', :tag => '0.0.7'
  #pod 'BinanceChain', :path => '../SwiftBinanceChain'
  
  pod 'HDWalletKit', :git => 'https://github.com/lazutkin-andrey/hdwallet.git', :tag => '0.3.12'
  #pod 'HDWalletKit', :path => '../HDWallet'
  
  pod 'TangemSdk', :git => 'https://github.com/Tangem/tangem-sdk-ios.git', :tag => 'develop-18'
#  pod 'TangemSdk', :path => '../tangem-sdk-ios'
  
  pod 'BlockchainSdk', :git => 'https://github.com/Tangem/blockchain-sdk-swift.git', :tag => 'develop-17'
#  pod 'BlockchainSdk', :path => '../blockchain-sdk-swift'
  
  pod 'web3swift', :git => 'https://github.com/lazutkin-andrey/web3swift.git', :tag => '2.2.6'
#  pod 'web3swift', :path => '../web3swift'
  
  pod 'BitcoinCore.swift', :git => 'https://github.com/lazutkin-andrey/bitcoincore.git', :tag => '0.0.13'
  #pod 'BitcoinCore.swift', :path => '../bitcoincore'

  pod 'Moya'
  pod 'KeychainSwift', '~> 19.0'
  pod 'EFQRCode' #//TODO: remove
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Analytics'
	pod 'Firebase/RemoteConfig'
  pod 'DeviceGuru'
  pod 'WalletConnectSwift'
  pod 'Kingfisher'

  target 'Tangem TapTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'Tangem TapUITests' do
    # Pods for testing
  end

end

target 'TangemClip' do
  use_frameworks!

  pod 'BigInt'
  pod 'SwiftyJSON'
  pod 'Alamofire'
  pod 'Moya'
  pod 'Sodium'
  pod 'SwiftCBOR'
  pod 'AnyCodable-FlightSchool'
  
end

pre_install do |installer|
    # workaround for https://github.com/CocoaPods/CocoaPods/issues/3289
    Pod::Installer::Xcode::TargetValidator.send(:define_method, :verify_no_static_framework_transitive_dependencies) {}
end

post_install do |installer|
	installer.pods_project.targets.each do |target|
		target.build_configurations.each do |config|
			if Gem::Version.new('9.0') > Gem::Version.new(config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'])
				config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
			end
		end
	end
end
