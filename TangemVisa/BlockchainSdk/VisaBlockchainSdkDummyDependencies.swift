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

public struct VisaDummyBlockchainDataProvider: BlockchainDataProvider {
    public let currentHost: String = ""
    public let outputsCount: Int? = nil

    public init() {}
}

public class VisaDummyTransactionDependencies: TransactionCreator, TransactionSender {
    public var wallet: Wallet
    public var state: WalletManagerState

    public var walletPublisher: AnyPublisher<Wallet, Never> {
        Just(wallet).eraseToAnyPublisher()
    }

    public var statePublisher: AnyPublisher<WalletManagerState, Never> {
        Just(state).eraseToAnyPublisher()
    }

    public init(isTestnet: Bool) {
        wallet = .init(blockchain: VisaUtilities(isTestnet: isTestnet).visaBlockchain, addresses: [:])
        state = .loaded
    }

    public func send(_ transaction: Transaction, signer: any TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        return Fail(error: .init(error: NSError(domain: "Not supported", code: -1))).eraseToAnyPublisher()
    }
}
