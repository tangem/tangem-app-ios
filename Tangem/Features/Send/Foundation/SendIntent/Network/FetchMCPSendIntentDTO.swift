//
//  FetchMCPSendIntentDTO.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum FetchMCPSendIntentDTO {
    struct Response: Decodable {
        let type: String
        let status: String
        let networkId: String
        let fromAddress: String
        let toAddress: String
        let tokenId: String
        let amount: String
        let memo: String?
        let txHash: String?
        let clientId: String
    }
}
