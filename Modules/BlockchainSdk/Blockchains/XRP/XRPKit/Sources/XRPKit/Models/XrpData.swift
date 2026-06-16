//
//  XrpData.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Smart Cash AG. All rights reserved.
//

import Foundation
import TangemLocalization
import AnyCodable

// https://xrpl.org/docs/references/http-websocket-apis/public-api-methods/transaction-methods/submit/

struct XrpResponse: Codable {
    let result: XrpResult?

    func assertAccountCreated() throws {
        if let code = result?.error_code, code == 19 {
            let networkName = Blockchain.xrp(curve: .secp256k1).displayName
            let amountToCreate: Decimal = 1
            throw BlockchainSdkError.noAccount(
                message: Localization.noAccountGeneric(networkName, "\(amountToCreate)", "XRP"),
                amountToCreate: amountToCreate
            )
        }
    }
}

struct XrpResult: Codable {
    let account_data: XrpAccountData?
    let account_flags: XRPAccountFlags?
    let validated: Bool?
    let drops: XrpFeeDrops?
    let engine_result_code: Int?
    let engine_result_message: String?
    let error: String?
    let error_exception: String?
    let state: XrpState?
    let error_code: Int?
    let tx_json: XrpTxJson?
    let lines: [XRPTrustLine]?
    let marker: [String: AnyCodable]?
    let transactions: [XRPTransactionInfo]?
}

struct XrpAccountData: Codable {
    let account: String?
    let balance: String?
    let sequence: Int?
    let transferRate: Int?
    let ownerCount: Int?

    enum CodingKeys: String, CodingKey {
        case account = "Account"
        case balance = "Balance"
        case sequence = "Sequence"
        case transferRate = "TransferRate"
        case ownerCount = "OwnerCount"
    }
}

struct XrpFeeDrops: Codable {
    let minimum_fee: String?
    let open_ledger_fee: String?
    let median_fee: String?
}

struct XrpState: Codable {
    let validated_ledger: XRPValidatedLedger?
}

struct XRPValidatedLedger: Codable {
    let reserve_base: Int?
}

struct XrpTxJson: Codable {
    let hash: String
}

struct XRPAccountFlags: Codable {
    let requireDestinationTag: Bool
}

struct XRPTrustLine: Codable, Hashable {
    let account: String
    let balance: String
    let currency: String
    let freezePeer: Bool?
    let no_ripple: Bool?

    enum CodingKeys: String, CodingKey {
        case account
        case balance
        case currency
        case freezePeer = "freeze_peer"
        case no_ripple
    }

    func matches(currency: String, issuer: String) -> Bool {
        self.currency == currency && account == issuer
    }
}

struct XRPTransactionInfo: Codable {
    let tx: XRPHistoryTransaction
    let meta: XRPTransactionMeta?
    let validated: Bool?
}

struct XRPTransactionMeta: Codable {
    let transactionResult: String?

    enum CodingKeys: String, CodingKey {
        case transactionResult = "TransactionResult"
    }
}

struct XRPHistoryTransaction: Codable {
    let account: String
    let destination: String?
    let amount: XRPTransactionAmount?
    let limitAmount: XRPIssuedCurrencyAmount?
    let fee: String?
    let transactionType: String?
    let hash: String?
    let date: Int?
    let ledgerIndex: Int?

    enum CodingKeys: String, CodingKey {
        case account = "Account"
        case destination = "Destination"
        case amount = "Amount"
        case limitAmount = "LimitAmount"
        case fee = "Fee"
        case transactionType = "TransactionType"
        case hash
        case date
        case ledgerIndex = "ledger_index"
    }
}

enum XRPTransactionAmount: Codable {
    /// Native XRP amount in drops.
    case drops(String)
    /// Issued currency amount.
    case issuedCurrency(XRPIssuedCurrencyAmount)

    var dropsValue: String? {
        if case .drops(let value) = self {
            return value
        }

        return nil
    }

    var issuedCurrencyValue: XRPIssuedCurrencyAmount? {
        if case .issuedCurrency(let value) = self {
            return value
        }

        return nil
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let stringValue = try? container.decode(String.self) {
            self = .drops(stringValue)
            return
        }

        self = .issuedCurrency(try container.decode(XRPIssuedCurrencyAmount.self))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .drops(let value):
            try container.encode(value)
        case .issuedCurrency(let value):
            try container.encode(value)
        }
    }
}

struct XRPIssuedCurrencyAmount: Codable {
    let currency: String
    let issuer: String
    let value: String
}
