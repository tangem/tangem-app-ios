//
//  ServicesManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import FirebaseCore
import BlockchainSdk
import TangemStaking
import TangemStories
import TangemFoundation
import UIKit

private struct ServicesManagerKey: InjectionKey {
    static var currentValue: ServicesManager = CommonServicesManager()
}

extension InjectedValues {
    var servicesManager: ServicesManager {
        get { Self[ServicesManagerKey.self] }
        set { Self[ServicesManagerKey.self] = newValue }
    }
}

protocol ServicesManager {
    var initialized: Bool { get }

    func initialize(delegate: AppDelegate)
    func initializeKeychainSensitiveServices() async
}

final class CommonServicesManager {
    @Injected(\.sellService) private var sellService: SellService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.apiListProvider) private var apiListProvider: APIListProvider
    @Injected(\.hotCryptoService) private var hotCryptoService: HotCryptoService
    @Injected(\.ukGeoDefiner) private var ukGeoDefiner: UKGeoDefiner
    @Injected(\.userTokensPushNotificationsService) private var userTokensPushNotificationsService: UserTokensPushNotificationsService
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor
    @Injected(\.wcService) private var wcService: any WCService
    @Injected(\.cryptoAccountsETagStorage) private var eTagStorage: CryptoAccountsETagStorage
    @Injected(\.experimentService) private var experimentService: ExperimentService
    @Injected(\.referralService) private var referralService: ReferralService

    private var stakingPendingHashesSender: StakingPendingHashesSender?
    private let storyDataPrefetchService: StoryDataPrefetchService
    private let pushNotificationEventsLogger: PushNotificationsEventsLogger
    private let mobileAccessCodeCleaner: MobileAccessCodeCleaner

    private var _initialized: Bool = false

    init() {
        stakingPendingHashesSender = StakingDependenciesFactory().makePendingHashesSender()
        storyDataPrefetchService = StoryDataPrefetchService()
        pushNotificationEventsLogger = PushNotificationsEventsLogger()
        mobileAccessCodeCleaner = MobileAccessCodeCleaner()
    }

    /// - Warning: DO NOT enable in debug mode.
    private func configureFirebase() {
        guard !AppEnvironment.current.isDebug else {
            return
        }

        let plistName = "GoogleService-Info-\(AppEnvironment.current.rawValue.capitalizingFirstLetter())"

        guard let filePath = Bundle.main.path(forResource: plistName, ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: filePath) else {
            assertionFailure("GoogleService-Info.plist not found")
            return
        }

        FirebaseApp.configure(options: options)
    }

    private func configureBlockchainSdkExceptionHandler() {
        ExceptionHandler.shared.append(output: Analytics.BlockchainExceptionHandler())
    }

    private func recordAppLaunch() -> Int {
        let initialLaunches = AppSettings.shared.numberOfLaunches
        let currentLaunches = initialLaunches + 1
        AppSettings.shared.numberOfLaunches = currentLaunches

        let sessionMessage = "New session. Session id: \(AppConstants.sessionId)"
        let launchNumberMessage = "Current launch number: \(currentLaunches)"
        let deviceInfoMessage = "\(DeviceInfoProvider.Subject.allCases.map { $0.description }.joined(separator: ", "))"
        AppLogger.info(sessionMessage)
        AppLogger.info(launchNumberMessage)
        AppLogger.info(deviceInfoMessage)
        AppLogger.info(RTCUtil().checkStatus())

        return initialLaunches
    }

    private func recordStartAppUsageDate() {
        guard AppSettings.shared.startAppUsageDate == nil else {
            return
        }

        AppSettings.shared.startAppUsageDate = Date()
    }

    private func configureForUITests() {
        // Only process UI testing arguments when running in UI test mode
        guard AppEnvironment.current.isUITest else { return }

        let arguments = ProcessInfo.processInfo.arguments

        if let _ = arguments.firstIndex(of: "-uitest-skip-tos") {
            AppSettings.shared.termsOfServicesAccepted = ["https://tangem.com/tangem_tos.html"]
        } else {
            AppSettings.shared.termsOfServicesAccepted = []
        }

        if let _ = arguments.firstIndex(of: "-uitest-clear-storage") {
            UITestsStorageCleaner.clearCachedFiles()
        }

        if arguments.contains("-uitest-disable-mobile-wallet") {
            FeatureStorage.instance.availableFeatures[.mobileWallet] = .off
        } else {
            FeatureStorage.instance.availableFeatures[.mobileWallet] = .on
        }

        UITestsStorageCleaner.clearWalletData()

        UIView.setAnimationsEnabled(false)
    }
}

extension CommonServicesManager: ServicesManager {
    var initialized: Bool {
        _initialized
    }

    func initialize(delegate: AppDelegate) {
        if _initialized {
            return
        }

        configureForUITests()

        SettingsMigrator.migrateIfNeeded()

        TangemLoggerConfigurator().initialize()

        recordStartAppUsageDate()
        let initialLaunches = recordAppLaunch()

        if initialLaunches == 0 {
            KeychainCleaner.cleanAllData()
        }

        AppLogger.info("Start services initializing")

        configureFirebase()
        AmplitudeWrapper.shared.configure()
        experimentService.configure()
        AppsFlyerWrapper.shared.configure(delegate: delegate)

        configureBlockchainSdkExceptionHandler()

        sellService.initialize()
        apiListProvider.initialize()
        userTokensPushNotificationsService.initialize()
        pushNotificationsInteractor.initialize()
        stakingPendingHashesSender?.sendHashesIfNeeded()
        hotCryptoService.loadHotCrypto(AppSettings.shared.selectedCurrencyCode)
        storyDataPrefetchService.prefetchStoryIfNeeded(.swap(.initialWithoutImages))
        ukGeoDefiner.initialize()
        wcService.initialize()
        eTagStorage.initialize()
        mobileAccessCodeCleaner.initialize()
        SendFeatureProvider.shared.loadFeaturesAvailability()
        PredefinedOnrampParametersBuilder.loadMoonpayPromotion()
        referralService.retryBindingIfNeeded()
    }

    /// Some services should be initialized later, in SceneDelegate to bypass locked keychain during preheating
    func initializeKeychainSensitiveServices() async {
        if _initialized {
            return
        }

        await userWalletRepository.initialize()

        _initialized = true
    }
}

protocol Initializable {
    func initialize()
}
