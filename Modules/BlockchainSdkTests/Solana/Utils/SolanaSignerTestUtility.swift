//
//  SolanaSignerTestUtility.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Combine
import enum SolanaSwift.SolanaError
@testable import BlockchainSdk

private let raisedError = SolanaError.nullValue

enum SolanaSignerTestUtility {
    class CoinSigner: TransactionSigner {
        private let sizeTester = TransactionSizeTesterUtility()

        func sign(hashes: [Data], walletPublicKey: BlockchainSdk.Wallet.PublicKey) -> AnyPublisher<[BlockchainSdk.SignatureInfo], any Error> {
            sizeTester.testTxSizes(hashes)
            return Fail(error: raisedError)
                .eraseToAnyPublisher()
        }

        func sign(hash: Data, walletPublicKey: BlockchainSdk.Wallet.PublicKey) -> AnyPublisher<BlockchainSdk.SignatureInfo, any Error> {
            sizeTester.testTxSize(hash)
            return Fail(error: raisedError)
                .eraseToAnyPublisher()
        }

        public func sign(
            dataToSign: [BlockchainSdk.SignData],
            seedKey: Data
        ) -> AnyPublisher<[(signature: Data, publicKey: Data)], Error> {
            dataToSign.forEach { data in
                sizeTester.testTxSize(data.hash)
            }
            return Fail(error: raisedError)
                .eraseToAnyPublisher()
        }
    }

    class TokenSigner: TransactionSigner {
        private let sizeTester = TransactionSizeTesterUtility()

        func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], any Error> {
            hashes.forEach {
                _ = sign(hash: $0, walletPublicKey: walletPublicKey)
            }
            return Fail(error: raisedError)
                .eraseToAnyPublisher()
        }

        func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<SignatureInfo, any Error> {
            #expect(sizeTester.isValidForCos4_52AndAbove(hash))
            #expect(!sizeTester.isValidForCosBelow4_52(hash))
            #expect(!sizeTester.isValidForIPhone7(hash))
            return Fail(error: raisedError)
                .eraseToAnyPublisher()
        }

        public func sign(
            dataToSign: [BlockchainSdk.SignData],
            seedKey: Data
        ) -> AnyPublisher<[(signature: Data, publicKey: Data)], Error> {
            dataToSign.forEach { data in
                sizeTester.testTxSize(data.hash)
            }
            return Fail(error: raisedError)
                .eraseToAnyPublisher()
        }
    }
}
