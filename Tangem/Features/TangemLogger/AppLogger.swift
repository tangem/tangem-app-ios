//
//  AppLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemLogger

let AppLogger = Logger(category: .app)
let WCLogger = Logger(category: .app).tag("Wallet Connect")
let AnalyticsLogger = Logger(category: .analytics)
let AppsflyerLogger = Logger(category: .app).tag("AppsFlyer")

extension Logger.Category {
    static let app = OSLogCategory(name: "App")
    static let analytics = OSLogCategory(name: "Analytics", prefix: nil)
}
