//
//  ServicesManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Firebase
import AppsFlyerLib
import Amplitude
import BlockchainSdk

class ServicesManager {
    @Injected(\.exchangeService) private var exchangeService: ExchangeService
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private var bag = Set<AnyCancellable>()

    func initialize() {
        AppLog.shared.configure()

        let initialLaunches = AppSettings.shared.numberOfLaunches
        let currentLaunches = initialLaunches + 1
        AppSettings.shared.numberOfLaunches = currentLaunches

        AppLog.shared.logAppLaunch(currentLaunches)

        if initialLaunches == 0 {
            userWalletRepository.initialClean()
        }

        AppLog.shared.debug("Start services initializing")

        if !AppEnvironment.current.isDebug {
            configureFirebase()
            configureAppsFlyer()
            configureAmplitude()
        }

        configureBlockchainSdkExceptionHandler()

        S2CTOUMigrator().migrate()
        exchangeService.initialize()
        tangemApiService.initialize()
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

    private func configureAppsFlyer() {
        guard AppEnvironment.current.isProduction else {
            return
        }

        do {
            let keysManager = try CommonKeysManager()
            AppsFlyerLib.shared().appsFlyerDevKey = keysManager.appsFlyer.appsFlyerDevKey
            AppsFlyerLib.shared().appleAppID = keysManager.appsFlyer.appsFlyerAppID
        } catch {
            assertionFailure("CommonKeysManager not initialized with error: \(error.localizedDescription)")
        }
    }

    private func configureAmplitude() {
        Amplitude.instance().trackingSessionEvents = true
        Amplitude.instance().initializeApiKey(try! CommonKeysManager().amplitudeApiKey)
    }

    private func configureBlockchainSdkExceptionHandler() {
        ExceptionHandler.shared.append(output: Analytics.BlockchainExceptionHandler())
    }
}

protocol Initializable {
    func initialize()
}
