//
//  MainQRBlockchainURIRequestBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol MainQRBlockchainURIRequestBuilder {
    func buildRequest(
        blockchain: Blockchain,
        destination: String,
        parsedAmount: Decimal?,
        parsedMemo: String?,
        queryItems: [URLQueryItem]
    ) -> MainQRPaymentRequest
}
