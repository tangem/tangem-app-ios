//
//  CollectiblesTransactionSender.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Broadcasts fully signed, sponsor-assembled transaction bytes and returns the signature.
/// No verification lives here — callers verify before any key touches the bytes.
protocol CollectiblesTransactionSender: AnyObject {
    /// `startSendingTimestamp` is when the sponsor issued the transaction's blockhash: the RPC layer sleeps
    /// the calling thread until 15 seconds have passed since that moment, so a fresh blockhash still idles
    /// for most of them.
    func send(signedTransaction: Data, startSendingTimestamp: Date) async throws -> String
}
