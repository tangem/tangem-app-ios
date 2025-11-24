//
//  XrpData.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Smart Cash AG. All rights reserved.
//

import Foundation
import TangemLocalization

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
}

struct XrpAccountData: Codable {
    let account: String?
    let balance: String?
    let sequence: Int?
    let transferRate: Int?

    enum CodingKeys: String, CodingKey {
        case account = "Account"
        case balance = "Balance"
        case sequence = "Sequence"
        case transferRate = "TransferRate"
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
    let no_ripple: Bool?

    func matches(currency: String, issuer: String) -> Bool {
        self.currency == currency && account == issuer
    }
}
