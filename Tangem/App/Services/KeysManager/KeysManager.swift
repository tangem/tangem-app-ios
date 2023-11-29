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
    var blockchainConfig: BlockchainSdkConfig { get }
    var shopifyShop: ShopifyShop { get }
    var tangemComAuthorization: String? { get }
    var sprinklr: SprinklrConfig { get }
    var zendesk: ZendeskConfig { get }
    var infuraProjectId: String { get }
    var swapReferrerAccount: SwapReferrerAccount? { get }
    var utorgSID: String { get }
    var walletConnectProjectId: String { get }
    var oneInchApiKey: String { get }
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
