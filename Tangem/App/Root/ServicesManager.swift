//
//  ServicesManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine
import BlockchainSdk
import TangemStaking
import TangemStories
import TangemFoundation
import TangemFirebaseDynamicShim

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
    @Injected(\.geoEligibilityService) private var geoEligibilityService: GeoEligibilityService
    @Injected(\.userTokensPushNotificationsService) private var userTokensPushNotificationsService: UserTokensPushNotificationsService
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor
    @Injected(\.wcService) private var wcService: any WCService
    @Injected(\.cryptoAccountsETagStorage) private var eTagStorage: CryptoAccountsETagStorage
    @Injected(\.experimentService) private var experimentService: ExperimentService
    @Injected(\.expandableAccountItemStateStorageProvider) private var stateStorageProvider: ExpandableAccountItemStateStorageProvider
    @Injected(\.tokenSelectorStateStorage) private var tokenSelectorStateStorage: TokenSelectorStateStorage
    @Injected(\.gaslessTransactionsNetworkManager) private var gaslessTransactionsNetworkManager: GaslessTransactionsNetworkManager
    @Injected(\.referralService) private var referralService: ReferralService
    @Injected(\.mobileUpgradeBannerStorageManager) private var mobileUpgradeBannerStorageManager: MobileUpgradeBannerStorageManager
    @Injected(\.stakingTargetAmountLimitProvider) private var stakingTargetAmountLimitProvider: CommonStakingTargetAmountLimitProvider

    private var stakingPendingHashesSender: StakingPendingHashesSender?
    private let storyDataPrefetchService: StoryDataPrefetchService
    private let pushNotificationEventsLogger: PushNotificationsEventsLogger
    private let mobileAccessCodeCleaner: MobileAccessCodeCleaner
    private let customerIOWrapper: CustomerIOWrapper

    private var _initialized: Bool = false

    init() {
        stakingPendingHashesSender = StakingDependenciesFactory().makePendingHashesSender()
        storyDataPrefetchService = StoryDataPrefetchService()
        pushNotificationEventsLogger = PushNotificationsEventsLogger()
        mobileAccessCodeCleaner = MobileAccessCodeCleaner()
        customerIOWrapper = CustomerIOWrapper()
    }

    /// - Warning: DO NOT enable in debug mode.
    private func configureFirebase() {
        guard !AppEnvironment.current.isDebug else {
            return
        }

        let plistName = "GoogleService-Info-\(AppEnvironment.current.rawValue.capitalizingFirstLetter())"

        guard
            let filePath = Bundle.main.path(forResource: plistName, ofType: "plist"),
            let options = FirebaseOptions(contentsOfFile: filePath)
        else {
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
            UITestsStorageCleaner.clearStoriesState()
        }

        if arguments.firstIndex(of: "-uitest-keep-wallets") == nil {
            UITestsStorageCleaner.clearWalletData()
        }

        // Feature toggle overrides — reset previous overrides for deterministic UI test runs
        FeatureStorage.instance.availableFeatures = [:]

        for feature in Feature.allCases {
            let onFlag = "-uitest-feature-\(feature.rawValue)-on"
            let offFlag = "-uitest-feature-\(feature.rawValue)-off"

            if arguments.contains(onFlag) {
                FeatureStorage.instance.availableFeatures[feature] = .on
            } else if arguments.contains(offFlag) {
                FeatureStorage.instance.availableFeatures[feature] = .off
            }
        }

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

        AppLogger.info("Start services initializing")

        configureFirebase()

        configureForUITests()

        SettingsMigrator.migrateIfNeeded()

        TangemLoggerConfigurator().initialize()
        TangemPayMocksConfigurator().initialize()

        recordStartAppUsageDate()
        let initialLaunches = recordAppLaunch()

        if initialLaunches == 0 {
            KeychainCleaner.cleanAllData()
        }

        AmplitudeWrapper.shared.configure()
        experimentService.configure()
        AppsFlyerWrapper.shared.configure(delegate: delegate)
        customerIOWrapper.configure()

        configureBlockchainSdkExceptionHandler()

        sellService.initialize()
        apiListProvider.initialize()
        userTokensPushNotificationsService.initialize()
        pushNotificationsInteractor.initialize()
        stakingPendingHashesSender?.sendHashesIfNeeded()
        hotCryptoService.loadHotCrypto(AppSettings.shared.selectedCurrencyCode)
        storyDataPrefetchService.prefetchStoryIfNeeded(.initialSwapStoryBasedOnToggle)
        geoEligibilityService.initialize()
        wcService.initialize()
        eTagStorage.initialize()
        mobileAccessCodeCleaner.initialize()
        stateStorageProvider.initialize()
        tokenSelectorStateStorage.initialize()
        SendFeatureProvider.shared.loadFeaturesAvailability()
        gaslessTransactionsNetworkManager.initialize()
        referralService.retryBindingIfNeeded()
        mobileUpgradeBannerStorageManager.initialize()
        stakingTargetAmountLimitProvider.initialize()
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
