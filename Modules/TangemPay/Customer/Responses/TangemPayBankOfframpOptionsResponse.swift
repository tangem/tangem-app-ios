//
//  TangemPayBankOfframpOptionsResponse.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayBankOfframpOptionsResponse: Decodable {
    public let sources: [Source]
    public let destinations: [Destination]

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sources = try container.decodeIfPresent([Source].self, forKey: .sources) ?? []
        destinations = try container.decodeIfPresent([Destination].self, forKey: .destinations) ?? []
    }

    enum CodingKeys: String, CodingKey {
        case sources
        case destinations
    }
}

// MARK: - Source

public extension TangemPayBankOfframpOptionsResponse {
    struct Source: Decodable {
        public let name: String
        public let isTestnet: Bool?
        public let chainId: Int
        public let tokens: [Token]
    }

    struct Token: Decodable {
        public let token: String
        public let tokenContractAddress: String
    }
}

// MARK: - Destination

public extension TangemPayBankOfframpOptionsResponse {
    struct Destination: Decodable {
        public let rail: TangemPayBankAccountRail
        public let fee: Fee
        public let eta: ETA
    }

    struct Fee: Decodable {
        public let name: String?
        public let calculationType: String?
        public let amount: Decimal
        public let currency: String?
        public let description: String?
    }

    struct ETA: Decodable {
        public let minDays: Int
        public let maxDays: Int
    }
}
