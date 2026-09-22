//
//  TangemPayBankAccountResponse.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayBankAccountResponse: Decodable {
    public let id: String
    public let displayName: String?
    public let details: Details
    public let createdAt: Date?
}

// MARK: - Details

public extension TangemPayBankAccountResponse {
    struct Details: Decodable {
        public let currency: String?
        public let rail: TangemPayBankAccountRail?
        public let thirdParty: Bool?
        public let beneficiary: Beneficiary
        public let beneficiaryAddress: Address?
        public let bankName: String?
        public let bankAddress: Address?
        public let accountNumber: String
        public let routingNumber: String?
        public let bankAccountType: TangemPayBankAccountType?

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            currency = try container.decodeIfPresent(String.self, forKey: .currency)
            rail = try container.decodeIfPresent(String.self, forKey: .rail).flatMap(TangemPayBankAccountRail.init(rawValue:))
            thirdParty = try container.decodeIfPresent(Bool.self, forKey: .thirdParty)
            beneficiary = try container.decode(Beneficiary.self, forKey: .beneficiary)
            beneficiaryAddress = try container.decodeIfPresent(Address.self, forKey: .beneficiaryAddress)
            bankName = try container.decodeIfPresent(String.self, forKey: .bankName)
            bankAddress = try container.decodeIfPresent(Address.self, forKey: .bankAddress)
            accountNumber = try container.decode(String.self, forKey: .accountNumber)
            routingNumber = try container.decodeIfPresent(String.self, forKey: .routingNumber)
            bankAccountType = try container.decodeIfPresent(String.self, forKey: .bankAccountType)
                .flatMap(TangemPayBankAccountType.init(rawValue:))
        }

        enum CodingKeys: String, CodingKey {
            case currency
            case rail
            case thirdParty
            case beneficiary
            case beneficiaryAddress
            case bankName
            case bankAddress
            case accountNumber
            case routingNumber
            case bankAccountType
        }
    }

    struct Beneficiary: Decodable {
        public let type: TangemPayBankAccountBeneficiaryType?
        public let firstName: String?
        public let lastName: String?
        public let businessName: String?

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = try container.decodeIfPresent(String.self, forKey: .type)
                .flatMap(TangemPayBankAccountBeneficiaryType.init(rawValue:))
            firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
            lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
            businessName = try container.decodeIfPresent(String.self, forKey: .businessName)
        }

        enum CodingKeys: String, CodingKey {
            case type
            case firstName
            case lastName
            case businessName
        }
    }

    struct Address: Decodable {
        public let line1: String?
        public let line2: String?
        public let city: String?
        public let region: String?
        public let postalCode: String?
        public let countryCode: String?
    }
}

// MARK: - Enums

public enum TangemPayBankAccountRail: String, Encodable {
    case ach = "ACH"
    case wire = "WIRE"
}

public enum TangemPayBankAccountBeneficiaryType: String, Encodable {
    case individual = "INDIVIDUAL"
    case business = "BUSINESS"
}

public enum TangemPayBankAccountType: String, Encodable {
    case checking = "CHECKING"
    case savings = "SAVINGS"
}
