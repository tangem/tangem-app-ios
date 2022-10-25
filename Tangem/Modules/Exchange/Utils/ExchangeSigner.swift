//
//  ExchangeSigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

class ExchangeSigner {
    @Injected(\.tangemSdkProvider) private var tangemProvider: TangemSdkProviding

    func signTx(_ hash: Data, publicKey: Data) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            tangemProvider.sdk.sign(hash: hash, walletPublicKey: publicKey) { result in
                switch result {
                case .failure(let error):
                    continuation.resume(throwing: error)
                case .success(let response):
                    continuation.resume(returning: response.signature)
                }
            }
        }
    }
}
