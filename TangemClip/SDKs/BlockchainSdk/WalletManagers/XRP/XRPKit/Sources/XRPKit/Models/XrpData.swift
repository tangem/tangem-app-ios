//
//  XrpData.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Smart Cash AG. All rights reserved.
//

import Foundation

struct XrpResponse: Codable {
    let result: XrpResult?
}

struct XrpResult: Codable {
    let account_data: XrpAccountData?
    let validated: Bool?
    let drops: XrpFeeDrops?
    let engine_result_code: Int?
    let engine_result_message: String?
    let error: String?
    let error_exception: String?
    let state: XrpState?
    let error_code: Int?
}

struct XrpAccountData: Codable {
    let account: String?
    let balance: String?
    let sequence: Int?
    
    enum CodingKeys: String, CodingKey {
        case account = "Account"
        case balance = "Balance"
        case sequence = "Sequence"
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
