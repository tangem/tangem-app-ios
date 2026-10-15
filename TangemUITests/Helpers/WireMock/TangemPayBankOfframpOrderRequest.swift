//
//  TangemPayBankOfframpOrderRequest.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TangemPayBankOfframpOrderRequest: Equatable, CustomStringConvertible {
    let amountInCents: Int
    let chainId: Int
    let bankAccountId: String?
    let details: Details?

    struct Details: Equatable {
        let rail: String
        let bankAccountType: String
        let beneficiaryType: String
        let isThirdParty: Bool
        let accountNumber: String
        let bankName: String
    }

    init(amountInCents: Int, chainId: Int, bankAccountId: String) {
        self.amountInCents = amountInCents
        self.chainId = chainId
        self.bankAccountId = bankAccountId
        details = nil
    }

    init(amountInCents: Int, chainId: Int, details: Details) {
        self.amountInCents = amountInCents
        self.chainId = chainId
        bankAccountId = nil
        self.details = details
    }

    init?(body: String) {
        guard
            let data = body.data(using: .utf8),
            let payload = try? JSONDecoder().decode(Payload.self, from: data).data,
            payload.type == Constants.orderType
        else {
            return nil
        }

        amountInCents = payload.amountInCents
        chainId = payload.chainId
        bankAccountId = payload.bankAccountId
        details = payload.bankAccount.map {
            Details(
                rail: $0.details.rail,
                bankAccountType: $0.details.bankAccountType,
                beneficiaryType: $0.details.beneficiary.type,
                isThirdParty: $0.details.thirdParty,
                accountNumber: $0.details.accountNumber,
                bankName: $0.details.bankName
            )
        }
    }

    var description: String {
        let recipient = details.map {
            "\($0.rail), \($0.bankAccountType), \($0.beneficiaryType), third party: \($0.isThirdParty), \($0.accountNumber), \($0.bankName)"
        } ?? "bank account id: \(bankAccountId ?? "none")"
        return "\(amountInCents) cents on chain \(chainId) to \(recipient)"
    }
}

private extension TangemPayBankOfframpOrderRequest {
    struct Payload: Decodable {
        let data: OrderData
    }

    struct OrderData: Decodable {
        let type: String
        let amountInCents: Int
        let chainId: Int
        let bankAccountId: String?
        let bankAccount: BankAccount?

        enum CodingKeys: String, CodingKey {
            case type
            case amountInCents = "amount_in_cents"
            case chainId = "chain_id"
            case bankAccountId = "bank_account_id"
            case bankAccount = "bank_account"
        }
    }

    struct BankAccount: Decodable {
        let details: BankAccountDetails
    }

    struct BankAccountDetails: Decodable {
        let rail: String
        let thirdParty: Bool
        let beneficiary: Beneficiary
        let bankName: String
        let accountNumber: String
        let bankAccountType: String

        enum CodingKeys: String, CodingKey {
            case rail
            case thirdParty = "third_party"
            case beneficiary
            case bankName = "bank_name"
            case accountNumber = "account_number"
            case bankAccountType = "bank_account_type"
        }
    }

    struct Beneficiary: Decodable {
        let type: String
    }

    enum Constants {
        static let orderType = "BANK_OFFRAMP_RAIN"
    }
}
