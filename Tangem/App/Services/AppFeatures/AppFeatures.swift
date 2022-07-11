//
//  AppFeatures.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct AppFeatures: Decodable {
    let isWalletPayIdEnabled: Bool
    let isSendingToPayIdEnabled: Bool
    let isTopUpEnabled: Bool
    let isCreatingTwinCardsAllowed: Bool

    static var local: AppFeatures {
        get throws {
            return try JsonUtils.readBundleFile(with: "features", type: AppFeatures.self)
        }
    }
}
