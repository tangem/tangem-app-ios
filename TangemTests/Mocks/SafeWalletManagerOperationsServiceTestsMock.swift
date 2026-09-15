//
//  SafeWalletManagerOperationsServiceTestsMock.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// Stands in for the wallet manager of a network with a Safe: what the tests it serves check is which manager an
/// operation ends up with, not what it answers.
final class SafeWalletManagerOperationsServiceTestsMock: SafeWalletManagerOperationsService {
    func getSafeState() async throws -> SafeContractState {
        throw MockError.notStubbed
    }

    func makeSafeInnerTransferCall(amount: Amount, destination: String) throws -> SafeInnerCall {
        throw MockError.notStubbed
    }

    func getSafeOperationFee(innerCall: SafeInnerCall, parameters: SafeOperationParameters) async throws -> Fee {
        throw MockError.notStubbed
    }
}

// MARK: - Auxiliary types

extension SafeWalletManagerOperationsServiceTestsMock {
    enum MockError: Error {
        case notStubbed
    }
}
