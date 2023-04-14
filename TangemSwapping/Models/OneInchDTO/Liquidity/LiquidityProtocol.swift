//
//  LiquidityProtocol.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct LiquidityProtocol: Decodable {
    public let id: String
    public let title: String
    public let image: String
    public let imageColor: String?

    enum CodingKeys: String, CodingKey {
        case imageColor = "img_color"
        case image = "img"
        case id
        case title
    }
}
