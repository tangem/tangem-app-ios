//
//  NEARAddressResolver.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct NEARAddressResolver {
    private let networkService: NEARNetworkService

    init(networkService: NEARNetworkService) {
        self.networkService = networkService
    }
}

// MARK: - AddressResolver

extension NEARAddressResolver: AddressResolver {
    func resolve(_ address: String) async throws -> String {
        // Implicit accounts don't require any modification or verification
        if !isNeedToResolve(address: address) {
            return address
        }

        // Here we're verifying if the account with the given named account ID exists
        // and just throwing an error if it doesn't
        return try await withCheckedThrowingContinuation { continuation in
            var getInfoSubscription: AnyCancellable?

            getInfoSubscription = networkService
                .getInfo(accountId: address)
                .tryMap { accountInfo in
                    switch accountInfo {
                    case .notInitialized:
                        throw BlockchainSdkError.empty // The particular type of this error doesn't matter
                    case .initialized(let account):
                        return account
                    }
                }
                .sink(
                    receiveCompletion: { result in
                        switch result {
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        case .finished:
                            continuation.resume(returning: address)
                        }
                        withExtendedLifetime(getInfoSubscription) {}
                    },
                    receiveValue: { _ in }
                )
        }
    }

    func isNeedToResolve(address: String) -> Bool {
        !NEARAddressUtil.isImplicitAccount(accountId: address)
    }
}
