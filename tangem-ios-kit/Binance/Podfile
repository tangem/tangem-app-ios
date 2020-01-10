source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!

def common
	pod 'BinanceChain', :path => '.'
	pod 'BinanceChain/Test', :path => '.'
	pod 'SwiftProtobuf', :inhibit_warnings => true
	pod 'Starscream', :inhibit_warnings => true
	pod 'HDWalletKit', :inhibit_warnings => true
	pod 'CryptoSwift', :inhibit_warnings => true
end

target "Mobile" do
	platform :ios, '11.0'
	common
end

target "Desktop" do
	platform :macos, '10.11'
	common
end
