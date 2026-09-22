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
        destinations = (try container.decodeIfPresent([DecodedDestination].self, forKey: .destinations) ?? [])
            .compactMap(\.destination)
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
    struct Destination {
        public let rail: TangemPayBankAccountRail
        public let fee: Fee
        public let eta: ETA

        init(rail: TangemPayBankAccountRail, fee: Fee, eta: ETA) {
            self.rail = rail
            self.fee = fee
            self.eta = eta
        }
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

// MARK: - Rail tolerance

private extension TangemPayBankOfframpOptionsResponse {
    struct DecodedDestination: Decodable {
        let destination: Destination?

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            guard
                let rail = try container.decodeIfPresent(String.self, forKey: .rail)
                .flatMap(TangemPayBankAccountRail.init(rawValue:))
            else {
                destination = nil
                return
            }

            destination = Destination(
                rail: rail,
                fee: try container.decode(Fee.self, forKey: .fee),
                eta: try container.decode(ETA.self, forKey: .eta)
            )
        }

        enum CodingKeys: String, CodingKey {
            case rail
            case fee
            case eta
        }
    }
}
