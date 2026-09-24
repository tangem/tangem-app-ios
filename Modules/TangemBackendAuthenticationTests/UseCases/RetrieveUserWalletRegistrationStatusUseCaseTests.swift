//
//  RetrieveUserWalletRegistrationStatusUseCaseTests.swift
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
struct RetrieveUserWalletRegistrationStatusUseCaseTests {
    @Test(arguments: [true, false])
    func retrieveUserWalletRegistrationStatusReturnsRepositoryStatusForGivenID(isRegistered: Bool) async {
        let expectedID = UserWalletId.uniqueFake()
        let repository = SpyUserWalletRegistrationStatusRepository()
        repository.retrieveResult = isRegistered

        let sut = makeSUT(registrationStatusRepository: repository)

        let actualStatus = await sut(id: expectedID)

        #expect(actualStatus == isRegistered)
        #expect(repository.receivedMessages == [.retrieve(expectedID)])
    }
}

// MARK: - Factory methods

extension RetrieveUserWalletRegistrationStatusUseCaseTests {
    private func makeSUT(
        registrationStatusRepository: some UserWalletRegistrationStatusRepository
    ) -> RetrieveUserWalletRegistrationStatusUseCase {
        RetrieveUserWalletRegistrationStatusUseCase(registrationStatusRepository: registrationStatusRepository)
    }
}
