//
//  MarketsDTO+Categories.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension MarketsDTO {
    enum Categories {}
}

extension MarketsDTO.Categories {
    struct Request: Encodable {
        /// ISO 3166-1 alpha-2. When omitted the backend answers with every category unrestricted.
        let country: String?

        init(country: String?) {
            self.country = country
        }

        var parameters: [String: Any] {
            guard let country, !country.isEmpty else {
                return [:]
            }

            return ["country": country]
        }
    }

    struct Response: Decodable {
        let categories: [Category]
    }

    struct Category: Identifiable, Codable, Hashable {
        let id: Int
        let code: String
        let displayName: String
        let displayOrder: Int
        let restricted: Bool
        let tokensCount: Int
        let sectors: [Sector]
        /// Present on the wire but absent from the swagger schema, hence optional.
        let visible: Bool?
    }

    struct Sector: Identifiable, Codable, Hashable {
        let id: Int
        let code: String
        let displayName: String
        let displayOrder: Int
        let tokensCount: Int
    }
}

extension MarketsDTO.Categories.Category {
    /// The backend already returns sectors in their curated order; sorting here keeps the UI independent of that.
    var orderedSectors: [MarketsDTO.Categories.Sector] {
        sectors.sorted(by: \.displayOrder)
    }
}
