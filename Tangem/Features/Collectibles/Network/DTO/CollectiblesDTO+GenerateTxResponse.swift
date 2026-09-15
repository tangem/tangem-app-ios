//
//  CollectiblesDTO+GenerateTxResponse.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension CollectiblesDTO {
    struct GenerateTxResponse: Decodable {
        let id, txData: String
    }
}
