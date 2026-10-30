//
//  CollectiblesDTO+GenerateBuybackDataResponse.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension CollectiblesDTO {
    struct GenerateBuybackDataResponse: Decodable {
        let buybackID: String
        let txData: TxData

        private enum CodingKeys: String, CodingKey {
            case buybackID = "buybackId"
            case txData
        }
    }
}

extension CollectiblesDTO.GenerateBuybackDataResponse {
    struct TxData: Decodable {
        let memo: String
        let toDecimals: Int
        let toAmount: String
        let tx: String
    }
}
