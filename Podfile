# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'
project 'TangemApp.xcodeproj'
# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!
inhibit_all_warnings!

def blockchain_sdk_pods
  pod 'BlockchainSdk', :git => 'https://github.com/tangem/blockchain-sdk-swift.git', :tag => 'develop-184'
  # pod 'BlockchainSdk', :path => '../blockchain-sdk-swift'

  pod 'AnyCodable-FlightSchool'
  pod 'stellar-ios-mac-sdk'
  pod 'ScaleCodec'

  pod 'Solana.Swift', :git => 'https://github.com/tangem/Solana.Swift', :tag => 'add-external-signer-6'
  # pod 'Solana.Swift', :path => '../Solana.Swift'

  pod 'BinanceChain', :git => 'https://github.com/tangem/swiftbinancechain.git', :tag => '0.0.9'
  # pod 'BinanceChain', :path => '../SwiftBinanceChain'

  pod 'HDWalletKit', :git => 'https://github.com/tangem/hdwallet.git', :tag => '0.3.12'
  # pod 'HDWalletKit', :path => '../HDWallet'
  
  pod 'web3swift', :git => 'https://github.com/tangem/web3swift.git', :tag => '2.2.11'
  # pod 'web3swift', :path => '../web3swift'
  
  pod 'BitcoinCore.swift', :git => 'https://github.com/tangem/bitcoincore.git', :tag => '0.0.16'
  # pod 'BitcoinCore.swift', :path => '../bitcoincore'
end

def tangem_sdk_pod
  pod 'TangemSdk', :git => 'https://github.com/Tangem/tangem-sdk-ios.git', :tag => 'develop-195'
  # pod 'TangemSdk', :path => '../tangem-sdk-ios'
end

target 'Tangem' do
  blockchain_sdk_pods
  tangem_sdk_pod
  
  # Pods for Tangem
  pod 'Moya'
  pod 'WalletConnectSwift', :git => 'https://github.com/WalletConnect/WalletConnectSwift', :tag => '1.7.0'
  pod 'Kingfisher', :git => 'https://github.com/onevcat/Kingfisher.git', :branch => 'version6-xcode13'
  pod 'Mobile-Buy-SDK' # Shopify

  # Helpers
  pod 'DeviceGuru', '8.0.0'
  pod 'AlertToast', :git => 'https://github.com/tangem/AlertToast'
  
  # support chat 
  pod 'ZendeskSupportSDK', '~> 5.5.0'
  pod 'ZendeskSupportProvidersSDK', '~> 5.5.0'
  pod 'ZendeskChatSDK', '~> 2.12.0'
  pod 'ZendeskAnswerBotSDK', '~> 2.2.0'
  
  # Analytics
  pod 'Amplitude', '~> 8.8.0'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Analytics'
  pod 'AppsFlyerFramework'
  
  target 'TangemTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'TangemUITests' do
    # Pods for testing
  end
end

target 'TangemExchange' do 
  pod 'Moya'

  target 'TangemExchangeTests' do
    inherit! :search_paths
    # Pods for testing
  end
end

pre_install do |installer|
    # workaround for https://github.com/CocoaPods/CocoaPods/issues/3289
    Pod::Installer::Xcode::TargetValidator.send(:define_method, :verify_no_static_framework_transitive_dependencies) {}
end

post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
      if config.name.include?("Debug")
          config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '0'
          config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
      end
  end
  
	installer.pods_project.targets.each do |target|
		target.build_configurations.each do |config|
			if Gem::Version.new('9.0') > Gem::Version.new(config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'])
				config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
			end
      if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
        target.build_configurations.each do |config|
            config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        end
      end
		end
	end
end
