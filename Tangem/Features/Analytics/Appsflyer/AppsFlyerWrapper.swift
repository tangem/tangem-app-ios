//
//  AppsFlyerWrapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import AppsFlyerLib
import enum TangemFoundation.AppEnvironment
import TangemFoundation
import Combine

class AppsFlyerWrapper {
    @Injected(\.keysManager) private var keysManager: any KeysManager
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    var appsflyerId: String {
        AppsFlyerLib.shared().getAppsFlyerUID()
    }

    static let shared: AppsFlyerWrapper = .init()

    private var bag: Set<AnyCancellable> = []

    private init() {
        bind()
    }

    /// AppsFlyer is allowed to run in Production (release builds only), and — to enable referral/OneLink
    /// testing — in the Alpha and Beta environments. It stays disabled in the Internal environment.
    /// Note: Alpha/Beta use the production AppsFlyer dev key, so test installs/events land in the prod account.
    private var isAppsFlyerEnabled: Bool {
        switch AppEnvironment.current {
        case .production:
            return !AppEnvironment.current.isDebug
        case .alpha, .beta:
            return true
        case .internal:
            return false
        }
    }

    func configure(delegate: AppDelegate) {
        guard isAppsFlyerEnabled else {
            return
        }

        AppsFlyerLib.shared().isDebug = !AppEnvironment.current.isProduction
        AppsFlyerLib.shared().disableIDFVCollection = true
        AppsFlyerLib.shared().appsFlyerDevKey = keysManager.appsFlyer.appsFlyerDevKey
        AppsFlyerLib.shared().appleAppID = keysManager.appsFlyer.appsFlyerAppID
        AppsFlyerLib.shared().deepLinkDelegate = delegate
    }

    func handleApplicationDidBecomeActive() {
        guard isAppsFlyerEnabled else {
            return
        }

        AppsFlyerLib.shared().start()
    }

    func handleUserActivity(userActivity: NSUserActivity) {
        guard isAppsFlyerEnabled else {
            return
        }

        AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
    }

    func log(event: String, params: [String: Any]) {
        guard isAppsFlyerEnabled else {
            return
        }

        let convertedEvent = AppsFlyerAnalyticsEventConverter.convert(event: event)
        let convertedParams = AppsFlyerAnalyticsEventConverter.convert(params: params)

        AppsFlyerLib.shared().logEvent(name: convertedEvent, values: convertedParams, completionHandler: { params, error in
            if let error {
                AnalyticsLogger.error(params, error: error)
            }
        })
    }

    private func setUserId(userId: String) {
        guard isAppsFlyerEnabled else {
            return
        }

        AppsFlyerLib.shared().customerUserID = userId
    }

    private func bind() {
        userWalletRepository
            .eventProvider
            .withWeakCaptureOf(self)
            .sink { wrapper, event in
                switch event {
                case .selected(let userWalletId):
                    wrapper.setUserId(userId: userWalletId.hashedStringValue)
                default:
                    break
                }
            }
            .store(in: &bag)
    }
}
