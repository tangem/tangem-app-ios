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
    var appsFlyerDevKey: String { get }
    var moonPayKeys: MoonPayKeys { get }
    var onramperApiKey: String { get }
    var blockchainConfig: BlockchainSdkConfig { get }
    var shopifyShop: ShopifyShop { get }
    var zendesk: ZendeskConfig { get }
}

private struct KeysManagerKey: InjectionKey {
    static var currentValue: KeysManager = CommonKeysManager()
}

extension InjectedValues {
    var keysManager: KeysManager {
        get { Self[KeysManagerKey.self] }
        set { Self[KeysManagerKey.self] = newValue }
    }
}
