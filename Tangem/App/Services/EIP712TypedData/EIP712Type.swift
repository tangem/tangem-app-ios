//
//  EIP712Type.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

/// A struct represents EIP712 type tuple
public struct EIP712Type: Codable {
    let name: String
    let type: String
}
