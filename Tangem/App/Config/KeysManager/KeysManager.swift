//
//  KeysManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol KeysManager {
    var appsFlyer: AppsFlyerConfig { get }
    var moonPayKeys: MoonPayKeys { get }
    var mercuryoWidgetId: String { get }
    var mercuryoSecret: String { get }
    var blockchainSdkKeysConfig: BlockchainSdkKeysConfig { get }
    var tangemComAuthorization: String? { get }
    var infuraProjectId: String { get }
    var utorgSID: String { get }
    var walletConnectProjectId: String { get }
    var expressKeys: ExpressKeys { get }
    var devExpressKeys: ExpressKeys? { get }
    var stakeKitKey: String { get }
    var moralisAPIKey: String { get }
    var blockaidAPIKey: String { get }
    var tangemApiKey: String { get }
}

private struct KeysManagerKey: InjectionKey {
    static var currentValue: KeysManager = try! CommonKeysManager()
}

extension InjectedValues {
    var keysManager: KeysManager {
        get { Self[KeysManagerKey.self] }
        set { Self[KeysManagerKey.self] = newValue }
    }
}
