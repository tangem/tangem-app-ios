//
//  CollectiblesChainService.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Foundation
public import BlockchainSdk

public protocol CollectiblesChainAccountReader {
    func account(address: String) async throws -> SolanaRawAccount?
}

public protocol CollectiblesChainTransactionBuilder {
    func latestBlockhash() async throws -> SolanaBlockhash
    func makeSelfPaidTransaction(
        instructions: [SolanaRawInstruction],
        feePayer: Data,
        blockhash: SolanaBlockhash
    ) throws -> SolanaSelfPaidTransaction
}

public protocol CollectiblesChainTransactionBroadcaster {
    func send(serializedTransaction: Data, startSendingTimestamp: Date) async throws -> String
}

public typealias CollectiblesChainService = CollectiblesChainAccountReader
    & CollectiblesChainTransactionBuilder
    & CollectiblesChainTransactionBroadcaster
