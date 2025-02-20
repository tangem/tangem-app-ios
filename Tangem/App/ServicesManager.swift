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

class ServicesManager {
    @Injected(\.exchangeService) private var exchangeService: ExchangeService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.accountHealthChecker) private var accountHealthChecker: AccountHealthChecker
    @Injected(\.apiListProvider) private var apiListProvider: APIListProvider
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor
    @Injected(\.hotCryptoService) private var hotCryptoService: HotCryptoService

    private var stakingPendingHashesSender: StakingPendingHashesSender?
    private let storyDataPrefetchService: StoryDataPrefetchService

    init() {
        stakingPendingHashesSender = StakingDependenciesFactory().makePendingHashesSender()
        storyDataPrefetchService = StoryDataPrefetchService()
    }

    func initialize() {
        TangemLoggerConfigurator().initialize()
        let initialLaunches = recordAppLaunch()

        if initialLaunches == 0 {
            userWalletRepository.initialClean()
        }

        AppLogger.info("Start services initializing")

        if !AppEnvironment.current.isDebug {
            configureFirebase()
        }

        configureBlockchainSdkExceptionHandler()

        exchangeService.initialize()
        accountHealthChecker.initialize()
        apiListProvider.initialize()
        pushNotificationsInteractor.initialize()
        SendFeatureProvider.shared.loadFeaturesAvailability()
        stakingPendingHashesSender?.sendHashesIfNeeded()
        MailZipFileManager.shared.cleanZipData()
        hotCryptoService.loadHotCrypto(AppSettings.shared.selectedCurrencyCode)
        storyDataPrefetchService.prefetchStoryIfNeeded(.swap(.initialWithoutImages))
    }

    private func configureFirebase() {
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
//        AppLogger.info(sessionMessage, launchNumberMessage, deviceInfoMessage)

        return initialLaunches
    }
}

// Some services should be initialized later, in SceneDelegate to bypass locked keychain during preheating
class KeychainSensitiveServicesManager {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    func initialize() {
        userWalletRepository.initialize()
    }
}

protocol Initializable {
    func initialize()
}
