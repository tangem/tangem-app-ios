//
//  ClearUserWalletRegistrationStatusUseCaseTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import struct TangemFoundation.UserWalletId
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
struct ClearUserWalletRegistrationStatusUseCaseTests {
    @Test
    func clearUserWalletRegistrationStatusPersistsUnregisteredForGivenID() async {
        let expectedID = UserWalletId.fake
        let repository = SpyUserWalletRegistrationStatusRepository()

        let sut = makeSUT(registrationStatusRepository: repository)

        await sut(id: expectedID)

        #expect(repository.receivedMessages == [.remove(expectedID)])
    }
}

// MARK: - Factory methods

extension ClearUserWalletRegistrationStatusUseCaseTests {
    private func makeSUT(
        registrationStatusRepository: some UserWalletRegistrationStatusRepository
    ) -> ClearUserWalletRegistrationStatusUseCase {
        ClearUserWalletRegistrationStatusUseCase(registrationStatusRepository: registrationStatusRepository)
    }
}
