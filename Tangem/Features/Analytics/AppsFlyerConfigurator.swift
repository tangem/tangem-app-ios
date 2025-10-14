//
//  AppsFlyerConfigurator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import AppsFlyerLib
import enum TangemFoundation.AppEnvironment

enum AppsFlyerConfigurator {
    @Injected(\.keysManager) private static var keysManager: any KeysManager

    static func configure() {
        guard AppEnvironment.current.isProduction else {
            return
        }

        AppsFlyerLib.shared().appsFlyerDevKey = keysManager.appsFlyer.appsFlyerDevKey
        AppsFlyerLib.shared().appleAppID = keysManager.appsFlyer.appsFlyerAppID
    }

    static func handleApplicationDidBecomeActive() {
        guard AppEnvironment.current.isProduction else {
            return
        }

        AppsFlyerLib.shared().start()
    }
}
