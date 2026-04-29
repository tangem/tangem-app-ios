//
//  StakeKitDTO.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakeKitAPIError: Decodable, LocalizedError {
    public let code: String?
    public let message: String?
    public let details: Details?
    let level: String?

    public var errorDescription: String? { message }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message = try? container.decodeIfPresent(String.self, forKey: .message)
        details = try? container.decodeIfPresent(Details.self, forKey: .details)
        level = try? container.decodeIfPresent(String.self, forKey: .level)

        if let stringCode = try? container.decodeIfPresent(String.self, forKey: .code) {
            code = stringCode
        } else if let intCode = try? container.decodeIfPresent(Int.self, forKey: .code) {
            code = String(intCode)
        } else {
            code = nil
        }
    }

    private enum CodingKeys: String, CodingKey {
        case code
        case message
        case details
        case level
    }

    public struct Details: Decodable {
        public let code: Code?
        public let reason: String?
        public let gasTokenSymbol: String?
        public let shortfallAmount: String?
        public let availableAmount: String?
        public let requiredAmount: String?

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            code = try? container.decodeIfPresent(Code.self, forKey: .code)
            reason = try? container.decodeIfPresent(String.self, forKey: .reason)
            gasTokenSymbol = try? container.decodeIfPresent(String.self, forKey: .gasTokenSymbol)
            shortfallAmount = try? container.decodeIfPresent(String.self, forKey: .shortfallAmount)
            availableAmount = try? container.decodeIfPresent(String.self, forKey: .availableAmount)
            requiredAmount = try? container.decodeIfPresent(String.self, forKey: .requiredAmount)
        }

        private enum CodingKeys: String, CodingKey {
            case code
            case reason
            case gasTokenSymbol
            case shortfallAmount
            case availableAmount
            case requiredAmount
        }

        public enum Code: String, Decodable {
            case insufficientGasReserve = "INSUFFICIENT_GAS_RESERVE"
        }
    }
}

enum StakeKitDTO {
    // MARK: - Common

    struct Token: Codable {
        let network: String
        let name: String
        let decimals: Int
        let address: String?
        let symbol: String
    }

    struct Validator: Decodable {
        let address: String
        let status: Status
        let name: String?
        let image: String?
        let website: String?
        let apr: Decimal?
        let commission: Decimal?
        let stakedBalance: String?
        let votingPower: Decimal?
        let preferred: Bool?

        enum Status: String, Decodable {
            case active
            case jailed
            case deactivating
            case inactive
            case full
        }
    }

    struct Address: Codable {
        let address: String
        let additionalAddresses: AdditionalAddresses?

        init(address: String, additionalAddresses: StakeKitDTO.Address.AdditionalAddresses? = nil) {
            self.address = address
            self.additionalAddresses = additionalAddresses
        }

        struct AdditionalAddresses: Codable {
            let cosmosPubKey: String?
            let binanceBeaconAddress: String?
            let stakeAccounts: [String]?
            let lidoStakeAccounts: [String]?
            let tezosPubKey: String?
            let cAddressBech: String?
            let pAddressBech: String?

            init(
                cosmosPubKey: String? = nil,
                binanceBeaconAddress: String? = nil,
                stakeAccounts: [String]? = nil,
                lidoStakeAccounts: [String]? = nil,
                tezosPubKey: String? = nil,
                cAddressBech: String? = nil,
                pAddressBech: String? = nil
            ) {
                self.cosmosPubKey = cosmosPubKey
                self.binanceBeaconAddress = binanceBeaconAddress
                self.stakeAccounts = stakeAccounts
                self.lidoStakeAccounts = lidoStakeAccounts
                self.tezosPubKey = tezosPubKey
                self.cAddressBech = cAddressBech
                self.pAddressBech = pAddressBech
            }
        }
    }

    struct Action: Decodable {
        let addresses: Address
        let amount: String?
        let createdAt: String?
        let currentStepIndex: Int
        let id: String
        let inputToken: Token?
        let integrationId: String
        let status: StakeKitDTO.Actions.ActionStatus
        let tokenId: String?
        let transactions: [Transaction.Response]
        let type: Actions.ActionType
        let USDAmount: String?
        let validatorAddress: String?
        let validatorAddresses: [String]?
        let accountAddresses: [String]?
    }

    struct Required: Decodable {
        let required: Bool
    }
}
