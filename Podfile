# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'
        pod 'SwiftyJSON'

target 'Tangem Tap' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  inhibit_all_warnings!

  # Pods for Tangem Tap
  pod 'AnyCodable-FlightSchool'
  pod 'BinanceChain', :git => 'https://bitbucket.org/tangem/swiftbinancechain.git', :tag => '0.0.7'
  #pod 'BinanceChain', :path => '../swiftbinancechain'
  pod 'HDWalletKit', :git => 'https://bitbucket.org/tangem/hdwallet.git', :tag => '0.3.12'
  pod 'TangemSdk', :git => 'git@bitbucket.org:tangem/card-sdk-swift.git', :tag => 'build-85'
  #pod 'TangemSdk', :path => '../card-sdk-swift'
  pod 'BlockchainSdk',:git => 'git@bitbucket.org:tangem/blockchain-sdk-swift.git', :tag => 'build-62'
  #pod 'BlockchainSdk', :path => '../blockchain-sdk-swift'
  pod 'web3swift', :git => 'https://bitbucket.org/tangem/web3swift.git', :tag => '2.2.4'
  #pod 'web3swift', :path => '../web3swift'
  #pod 'BitcoinCore.swift', :path => '../bitcoincore'
  pod 'BitcoinCore.swift', :git => 'https://bitbucket.org/tangem/bitcoincore.git', :tag => '0.0.12'
  pod 'Moya'
  pod 'EFQRCode'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Analytics'
	pod 'Firebase/RemoteConfig'

  target 'Tangem TapTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'Tangem TapUITests' do
    # Pods for testing
  end

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
