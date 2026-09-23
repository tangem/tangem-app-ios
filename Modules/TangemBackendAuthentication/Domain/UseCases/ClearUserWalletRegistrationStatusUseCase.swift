//
//  ClearUserWalletRegistrationStatusUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct TangemFoundation.UserWalletId

public struct ClearUserWalletRegistrationStatusUseCase: Sendable {
    private let registrationStatusRepository: any UserWalletRegistrationStatusRepository

    init(registrationStatusRepository: some UserWalletRegistrationStatusRepository) {
        self.registrationStatusRepository = registrationStatusRepository
    }

    public func callAsFunction(id: UserWalletId) async {
        await registrationStatusRepository.persist(isRegistered: false, id: id)
    }
}
