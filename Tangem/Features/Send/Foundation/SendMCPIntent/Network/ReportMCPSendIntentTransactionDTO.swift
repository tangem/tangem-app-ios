//
//  ReportMCPSendIntentTransactionDTO.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum ReportMCPSendIntentTransactionDTO {
    struct Request: Encodable {
        let txHash: String
    }
}
