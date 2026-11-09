//
//  DateProvider.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol DateProvider {
    var now: Date { get }
}

public struct SystemDateProvider: DateProvider {
    public init() {}

    public var now: Date {
        Date()
    }
}

public struct FixedDateProvider: DateProvider {
    public let now: Date

    public init(now: Date) {
        self.now = now
    }
}
