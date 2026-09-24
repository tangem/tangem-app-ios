//
//  RetrieveUserWalletRegistrationStatusUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct TangemFoundation.UserWalletId

public struct RetrieveUserWalletRegistrationStatusUseCase: Sendable {
    private let registrationStatusRepository: any UserWalletRegistrationStatusRepository

    init(registrationStatusRepository: some UserWalletRegistrationStatusRepository) {
        self.registrationStatusRepository = registrationStatusRepository
    }

    public func callAsFunction(id: UserWalletId) async -> Bool {
        await registrationStatusRepository.retrieve(id: id)
    }
}
