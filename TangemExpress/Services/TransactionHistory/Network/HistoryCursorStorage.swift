//
//  HistoryCursorStorage.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol HistoryCursorStorage: Sendable {
    var cursor: Any? { get async }

    func setCursor(_ cursor: Any?) async
    func clear() async
}
