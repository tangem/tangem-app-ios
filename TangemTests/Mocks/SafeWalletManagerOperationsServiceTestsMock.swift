//
//  SafeWalletManagerOperationsServiceTestsMock.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// Stands in for the wallet manager of a network with a Safe. Answers only what the test hands it, so a call the
/// test did not expect fails rather than passes for something.
final class SafeWalletManagerOperationsServiceTestsMock: SafeWalletManagerOperationsService {
    private let state: SafeContractState?
    private let innerCall: SafeInnerCall?

    init(state: SafeContractState? = nil, innerCall: SafeInnerCall? = nil) {
        self.state = state
        self.innerCall = innerCall
    }

    func getSafeState() async throws -> SafeContractState {
        guard let state else {
            throw MockError.notStubbed
        }

        return state
    }

    func makeSafeInnerTransferCall(amount: Amount, destination: String) throws -> SafeInnerCall {
        guard let innerCall else {
            throw MockError.notStubbed
        }

        return innerCall
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
