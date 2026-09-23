//
//  TangemPayGeoCountry.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayGeoCountry: Decodable, Equatable {
    public let code: String
    public let name: String
    public let flagUrl: String?
    public let suggested: Bool
    public let hasRegions: Bool

    public init(code: String, name: String, flagUrl: String?, suggested: Bool, hasRegions: Bool) {
        self.code = code
        self.name = name
        self.flagUrl = flagUrl
        self.suggested = suggested
        self.hasRegions = hasRegions
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        code = try container.decode(String.self, forKey: .code)
        name = try container.decode(String.self, forKey: .name)
        flagUrl = try container.decodeIfPresent(String.self, forKey: .flagUrl)
        suggested = try container.decodeIfPresent(Bool.self, forKey: .suggested) ?? false
        hasRegions = try container.decodeIfPresent(Bool.self, forKey: .hasRegions) ?? false
    }

    enum CodingKeys: String, CodingKey {
        case code
        case name
        case flagUrl
        case suggested
        case hasRegions
    }
}
