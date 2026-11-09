//
//  JointAccountMemberSlotID.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct JointAccountMemberSlotID: Hashable {
    let rawValue: Int

    init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
}

// MARK: - Comparable

extension JointAccountMemberSlotID: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Codable

extension JointAccountMemberSlotID: Codable {
    init(from decoder: Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(Int.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
