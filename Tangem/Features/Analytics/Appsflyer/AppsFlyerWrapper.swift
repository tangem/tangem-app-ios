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

    /// `didStart` / `pendingUserActivities` are touched only from the main thread (UIKit scene callbacks),
    /// so they need no synchronization.
    private var didStart = false
    /// Universal links that arrived before `start()` (cold-launch `willConnectTo`); replayed once the SDK
    /// starts, because AppsFlyer resolves deep links only after `start()`.
    private var pendingUserActivities: [NSUserActivity] = []

    private init() {
        bind()
    }

    func configure(delegate: AppDelegate) {
        guard !AppEnvironment.current.isInternalOrDebug else {
            return
        }

        AppsFlyerLib.shared().disableIDFVCollection = true
        AppsFlyerLib.shared().appsFlyerDevKey = keysManager.appsFlyer.appsFlyerDevKey
        AppsFlyerLib.shared().appleAppID = keysManager.appsFlyer.appsFlyerAppID
        AppsFlyerLib.shared().deepLinkDelegate = delegate
    }

    func handleApplicationDidBecomeActive() {
        guard !AppEnvironment.current.isInternalOrDebug else {
            return
        }

        AppsFlyerLib.shared().start()
        didStart = true

        for userActivity in pendingUserActivities {
            continueUserActivity(userActivity)
        }

        pendingUserActivities.removeAll()
    }

    func handleUserActivity(userActivity: NSUserActivity) {
        guard !AppEnvironment.current.isInternalOrDebug else {
            return
        }

        guard didStart else {
            pendingUserActivities.append(userActivity)
            return
        }

        continueUserActivity(userActivity)
    }

    private func continueUserActivity(_ userActivity: NSUserActivity) {
        AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
    }

    func log(event: String, params: [String: Any]) {
        guard !AppEnvironment.current.isInternalOrDebug else {
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
        guard !AppEnvironment.current.isInternalOrDebug else {
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
