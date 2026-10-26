//
//  MarketingActivityURLBuilderUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct MarketingActivityURLBuilderUtil {
    func bindWalletsURL(baseURL: URL, uid: String) -> URL {
        baseURL
            .appending(path: "marketing/activity")
            .appending(component: uid)
            .appending(path: "bind-wallets")
    }

    func bindWalletsLoggablePath(uid: String) -> String {
        "/marketing/activity/\(uid.masked())/bind-wallets"
    }
}
