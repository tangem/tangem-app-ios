//
//  Analytics+DebugEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol AnalyticsDebugEvent {
    var title: String { get }
    var analyticsParams: [String: Any] { get }
}
