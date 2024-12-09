//
//  TargetTypeLogConvertible.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public protocol TargetTypeLogConvertible {
    var requestDescription: String { get }
    var shouldLogResponseBody: Bool { get }
}

public extension TargetTypeLogConvertible {
    var shouldLogResponseBody: Bool { true }
}
