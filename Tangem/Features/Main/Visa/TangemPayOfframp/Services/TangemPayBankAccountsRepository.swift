//
//  TangemPayBankAccountsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

protocol TangemPayBankAccountsRepository {
    func bankAccounts() async throws -> [TangemPayBankAccountResponse]
}

final class CommonTangemPayBankAccountsRepository {
    private let customerService: any CustomerInfoManagementService

    init(customerService: any CustomerInfoManagementService) {
        self.customerService = customerService
    }
}

// MARK: - TangemPayBankAccountsRepository

extension CommonTangemPayBankAccountsRepository: TangemPayBankAccountsRepository {
    func bankAccounts() async throws -> [TangemPayBankAccountResponse] {
        try await customerService.getBankAccounts()
    }
}
