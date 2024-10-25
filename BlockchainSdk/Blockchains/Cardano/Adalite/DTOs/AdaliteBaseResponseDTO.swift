//
//  AdaliteBaseResponseDTO.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct AdaliteBaseResponseDTO<Left: Decodable, Right: Decodable>: Decodable {
    let right: Right?
    let left: Left?

    enum CodingKeys: String, CodingKey {
        case right = "Right"
        case left = "Left"
    }
}
