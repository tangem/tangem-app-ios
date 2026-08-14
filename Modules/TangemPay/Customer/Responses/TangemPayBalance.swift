//
//  TangemPayBalance.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayBalance: Decodable, Equatable {
    public let fiat: Fiat
    public let crypto: Crypto
    public let availableForWithdrawal: AvailableForWithdrawal
    public let networks: [Network]

    enum CodingKeys: String, CodingKey {
        case fiat
        case crypto
        case availableForWithdrawal
        case networks
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fiat = try container.decode(Fiat.self, forKey: .fiat)
        crypto = try container.decode(Crypto.self, forKey: .crypto)
        availableForWithdrawal = try container.decode(AvailableForWithdrawal.self, forKey: .availableForWithdrawal)
        networks = (try container.decodeIfPresent([DecodedNetwork].self, forKey: .networks) ?? [])
            .compactMap(\.network)
    }
}

private extension TangemPayBalance {
    struct DecodedNetwork: Decodable {
        let network: Network?

        init(from decoder: Decoder) throws {
            network = try? Network(from: decoder)
        }
    }
}

public extension TangemPayBalance {
    struct Fiat: Decodable, Equatable {
        public let currency: String
        public let availableBalance: Decimal
        public let creditLimit: Decimal
        public let pendingCharges: Decimal
        public let postedCharges: Decimal
        public let balanceDue: Decimal
    }

    struct Crypto: Decodable, Equatable {
        public let id: String
        public let chainId: Int
        public let depositAddress: String
        public let tokenContractAddress: String
        public let balance: Decimal
    }

    struct AvailableForWithdrawal: Decodable, Equatable {
        public let amount: Decimal
        public let currency: String
    }

    struct Network: Decodable, Equatable {
        public let name: String
        public let isTestnet: Bool
        public let chainId: Int
        public let status: Status
        public let depositAddress: String?
        public let tokens: [Token]

        public enum Status: String, Decodable {
            case enabled = "ENABLED"
            case disabled = "DISABLED"
            case notIssued = "NOT_ISSUED"
            case undefined = "UNDEFINED"

            public init(from decoder: Decoder) throws {
                let raw = try decoder.singleValueContainer().decode(String.self)
                self = Self(rawValue: raw) ?? .undefined
            }
        }

        public struct Token: Decodable, Equatable {
            public let token: String
            public let tokenContractAddress: String
            public let availableForWithdrawal: Decimal?
        }
    }
}
