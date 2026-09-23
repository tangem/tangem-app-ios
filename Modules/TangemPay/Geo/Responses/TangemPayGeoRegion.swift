//
//  TangemPayGeoRegion.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayGeoRegion: Decodable, Equatable {
    public let code: String
    public let name: String
    public let suggested: Bool

    public init(code: String, name: String, suggested: Bool) {
        self.code = code
        self.name = name
        self.suggested = suggested
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        code = try container.decode(String.self, forKey: .code)
        name = try container.decode(String.self, forKey: .name)
        suggested = try container.decodeIfPresent(Bool.self, forKey: .suggested) ?? false
    }

    enum CodingKeys: String, CodingKey {
        case code
        case name
        case suggested
    }
}
