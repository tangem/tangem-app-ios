//
//  VisaAPIService.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol VisaAPIService {
    func loadHistoryPage(request: VisaTransactionHistoryDTO.APIRequest) async throws -> VisaTransactionHistoryDTO
}
