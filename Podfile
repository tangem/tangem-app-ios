platform :ios, '11.0'

load 'tangem-ios-kit/pods_define'

workspace 'Tangem'
project 'Tangem.xcodeproj'
project 'tangem-ios-kit/TangemKit/TangemKit.xcodeproj'

target 'Tangem beta' do
    project 'Tangem.xcodeproj'
    use_frameworks!
    tangemioskit_pods
    pod 'QRCode', '2.0'
    pod 'Fabric'
    pod 'Crashlytics'
end

target 'TangemKit' do
   project 'tangem-ios-kit/TangemKit/TangemKit.xcodeproj'
    use_frameworks!
    tangemioskit_pods
end

target 'Tangem' do
    project 'Tangem.xcodeproj'
    use_frameworks!
    tangemioskit_pods
    pod 'QRCode', '2.0'
    pod 'Fabric'
    pod 'Crashlytics'
end