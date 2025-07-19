//
//  Timeouts.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum Timeouts {
    static let quickUIUpdate = 3.0
    static let longUIUpdate = 10.0
    static let criticalUIOperation = 20.0 // Для критичных UI операций на CI

    static let quickNetworkRequest = 30.0
    static let networkRequest = 60.0
    static let longNetworkRequest = 180.0

    static let databaseMigration = 60.0
}

extension TimeInterval {
    /// 3
    static let quickUIUpdate: TimeInterval = Timeouts.quickUIUpdate

    /// 10
    static let longUIUpdate: TimeInterval = Timeouts.longUIUpdate

    /// 20
    static let criticalUIOperation: TimeInterval = Timeouts.criticalUIOperation

    /// 30
    static let quickNetworkRequest: TimeInterval = Timeouts.quickNetworkRequest

    /// 60
    static let networkRequest: TimeInterval = Timeouts.networkRequest

    /// 180
    static let longNetworkRequest: TimeInterval = Timeouts.longNetworkRequest

    /// 60
    static let databaseMigration: TimeInterval = Timeouts.databaseMigration
}
