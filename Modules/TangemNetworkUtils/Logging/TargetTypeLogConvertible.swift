//
//  TargetTypeLogConvertible.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public protocol TargetTypeLogConvertible {
    var requestDescription: String { get }
    var shouldLogResponseBody: Bool { get }
}
