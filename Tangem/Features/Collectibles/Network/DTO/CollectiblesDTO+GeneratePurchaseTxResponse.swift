//
//  CollectiblesDTO+GeneratePurchaseTxResponse.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension CollectiblesDTO {
    struct GeneratePurchaseTxResponse: Decodable {
        let txID: String
        let txData: TxData

        private enum CodingKeys: String, CodingKey {
            case txID = "txId"
            case txData
        }
    }
}

extension CollectiblesDTO.GeneratePurchaseTxResponse {
    struct TxData: Decodable {
        let memo: String
        let fromContractAddress: String
        let fromAmount: String
        let feeAmount: String
    }
}
