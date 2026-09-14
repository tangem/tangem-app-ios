//
//  TangemPayOfframpOptionsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

protocol TangemPayOfframpOptionsRepository {
    func options() async throws -> TangemPayBankOfframpOptionsResponse
}

final class CommonTangemPayOfframpOptionsRepository: TangemPayOfframpOptionsRepository {
    private let customerService: any CustomerInfoManagementService

    init(customerService: any CustomerInfoManagementService) {
        self.customerService = customerService
    }

    func options() async throws -> TangemPayBankOfframpOptionsResponse {
        try await customerService.getBankOfframpOptions()
    }
}
