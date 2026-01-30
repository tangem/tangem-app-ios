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

    func configure(delegate: AppDelegate) {
        guard !AppEnvironment.current.isAlphaOrBetaOrDebug else {
            return
        }

        AppsFlyerLib.shared().disableIDFVCollection = true
        AppsFlyerLib.shared().appsFlyerDevKey = keysManager.appsFlyer.appsFlyerDevKey
        AppsFlyerLib.shared().appleAppID = keysManager.appsFlyer.appsFlyerAppID
        AppsFlyerLib.shared().deepLinkDelegate = delegate
    }

    func handleApplicationDidBecomeActive() {
        guard !AppEnvironment.current.isAlphaOrBetaOrDebug else {
            return
        }

        AppsFlyerLib.shared().start()
    }

    func handleUserActivity(userActivity: NSUserActivity) {
        guard !AppEnvironment.current.isAlphaOrBetaOrDebug else {
            return
        }

        AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
    }

    func log(event: String, params: [String: Any]) {
        guard !AppEnvironment.current.isAlphaOrBetaOrDebug else {
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
        guard !AppEnvironment.current.isAlphaOrBetaOrDebug else {
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
