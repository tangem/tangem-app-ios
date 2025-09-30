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

    func initialize()
    func initializeKeychainSensitiveServices() async
}

class CommonServicesManager {
    @Injected(\.sellService) private var sellService: SellService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.accountHealthChecker) private var accountHealthChecker: AccountHealthChecker
    @Injected(\.apiListProvider) private var apiListProvider: APIListProvider
    @Injected(\.hotCryptoService) private var hotCryptoService: HotCryptoService
    @Injected(\.ukGeoDefiner) private var ukGeoDefiner: UKGeoDefiner
    @Injected(\.userTokensPushNotificationsService) private var userTokensPushNotificationsService: UserTokensPushNotificationsService
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor
    @Injected(\.wcService) private var wcService: any WCService

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

    private func configureAmplitude() {
        guard !AppEnvironment.current.isDebug else {
            return
        }

        AmplitudeWrapper.shared.configure()
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
            clearStorageForUITests()
        }

        UIView.setAnimationsEnabled(false)
    }

    private func clearStorageForUITests() {
        AppLogger.info("Clearing storage for UI tests")

        // Clear keychain data
        KeychainCleaner.cleanAllData()

        // Clear UserDefaults for the app
        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
        }

        // Clear blockchain data storage
        let blockchainDataStorageSuiteName = AppEnvironment.current.blockchainDataStorageSuiteName
        UserDefaults(suiteName: blockchainDataStorageSuiteName)?.removePersistentDomain(forName: blockchainDataStorageSuiteName)

        // Clear cached files from caches directory
        clearCachedFiles()

        AppLogger.info("Storage cleared for UI tests")
    }

    private func clearCachedFiles() {
        let fileManager = FileManager.default
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]

        let cacheFiles = [
            "cached_balances.json",
            "cached_quotes.json",
            "cached_express_availability.json",
        ]

        for cacheFile in cacheFiles {
            let fileURL = cachesDirectory.appendingPathComponent(cacheFile)
            if fileManager.fileExists(atPath: fileURL.path) {
                do {
                    try fileManager.removeItem(at: fileURL)
                    AppLogger.info("Cleared cache file: \(cacheFile)")
                } catch {
                    AppLogger.error(error: "Failed to clear cache file \(cacheFile): \(error)")
                }
            }
        }

        // Clear any NFT assets cache files
        do {
            let contents = try fileManager.contentsOfDirectory(at: cachesDirectory, includingPropertiesForKeys: nil)
            let nftCacheFiles = contents.filter { $0.lastPathComponent.hasPrefix("nft_assets_cache_") }
            for nftCacheFile in nftCacheFiles {
                try fileManager.removeItem(at: nftCacheFile)
                AppLogger.info("Cleared NFT cache file: \(nftCacheFile.lastPathComponent)")
            }
        } catch {
            AppLogger.error(error: "Failed to clear NFT cache files: \(error)")
        }
    }
}

extension CommonServicesManager: ServicesManager {
    var initialized: Bool {
        _initialized
    }

    func initialize() {
        if _initialized {
            return
        }

        SettingsMigrator.migrateIfNeeded()

        configureForUITests()

        TangemLoggerConfigurator().initialize()

        recordStartAppUsageDate()
        let initialLaunches = recordAppLaunch()

        if initialLaunches == 0 {
            KeychainCleaner.cleanAllData()
        }

        AppLogger.info("Start services initializing")

        configureFirebase()
        configureAmplitude()

        configureBlockchainSdkExceptionHandler()

        sellService.initialize()
        accountHealthChecker.initialize()
        apiListProvider.initialize()
        userTokensPushNotificationsService.initialize()
        pushNotificationsInteractor.initialize()
        stakingPendingHashesSender?.sendHashesIfNeeded()
        hotCryptoService.loadHotCrypto(AppSettings.shared.selectedCurrencyCode)
        storyDataPrefetchService.prefetchStoryIfNeeded(.swap(.initialWithoutImages))
        ukGeoDefiner.initialize()
        wcService.initialize()

        mobileAccessCodeCleaner.initialize()
        SendFeatureProvider.shared.loadFeaturesAvailability()
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
