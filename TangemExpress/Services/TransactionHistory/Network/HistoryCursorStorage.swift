//
//  HistoryCursorStorage.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A storage for the opaque (hence `Any`) cursor for the next page.
public protocol HistoryCursorStorage: Sendable {
    var cursor: Any? { get async }

    func setCursor(_ cursor: Any?) async
    func clear() async
}
