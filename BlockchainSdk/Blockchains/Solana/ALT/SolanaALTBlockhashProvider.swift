//
//  SolanaALTBlockhashProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol SolanaALTBlockhashProvider {
    func provideBlockhash() async throws -> String
}

struct SolanaCommonALTBlockhashProvider: SolanaALTBlockhashProvider {
    private let networkService: SolanaNetworkService

    init(networkService: SolanaNetworkService) {
        self.networkService = networkService
    }

    func provideBlockhash() async throws -> String {
        try await networkService.getLatestBlockhash()
    }
}

struct SolanaDummyALTBlockhashProvider: SolanaALTBlockhashProvider {
    private let dummyBlockhash: String

    init(dummyBlockhash: String) {
        self.dummyBlockhash = dummyBlockhash
    }

    func provideBlockhash() async throws -> String {
        dummyBlockhash
    }
}
