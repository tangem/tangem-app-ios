//
//  VisaBlockchainSdkDummyDependencies.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

public struct VisaDummyBlockchainDataProvider: BlockchainDataProvider {
    public let currentHost: String = ""
    public let outputsCount: Int? = nil

    public init() {}
}

public class VisaDummyTransactionDependencies: TransactionCreator, TransactionSender, CompiledTransactionSender {
    public var wallet: Wallet
    public var state: WalletManagerState

    public var walletPublisher: AnyPublisher<Wallet, Never> {
        Just(wallet).eraseToAnyPublisher()
    }

    public var statePublisher: AnyPublisher<WalletManagerState, Never> {
        Just(state).eraseToAnyPublisher()
    }

    public init(isTestnet: Bool) {
        wallet = .init(blockchain: VisaUtilities.visaBlockchain(isTestnet: isTestnet), addresses: [:])
        state = .loaded
    }

    public func send(_ transaction: Transaction, signer: any TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let error = SendTxError(error: VisaDummyTransactionDependencies.Error.notSupported)
        return Fail(error: error).eraseToAnyPublisher()
    }

    public func send(compiledTransaction data: Data, signer: any BlockchainSdk.TransactionSigner) async throws -> TransactionSendResult {
        let error = SendTxError(error: VisaDummyTransactionDependencies.Error.notSupported)
        throw error
    }
}

private extension VisaDummyTransactionDependencies {
    enum Error: UniversalError {
        case notSupported

        var errorCode: Int { -1 }

        var errorDescription: String? {
            return "Not supported"
        }
    }
}
