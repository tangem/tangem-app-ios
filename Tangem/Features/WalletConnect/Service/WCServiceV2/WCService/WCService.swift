//
//  WCService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import ReownWalletKit
import enum BlockchainSdk.Blockchain

/// Answers a WalletConnect link with a connection sheet, which belongs to a wallet session — so the app
/// keeps it in the responder chain for exactly as long as one is on screen.
protocol WCService: IncomingActionResponder {
    var transactionRequestPublisher: AnyPublisher<Result<WCHandleTransactionData, any Error>, Never> { get }

    func initialize()

    func openSession(with uri: WalletConnectRequestURI) async throws -> (Session.Proposal, VerifyContext?)

    func approveSessionProposal(with proposalID: String, namespaces: [String: SessionNamespace]) async throws -> Session
    func rejectSessionProposal(with proposalID: String, reason: RejectionReason) async throws
    func disconnectSession(withTopic topic: String) async throws
    func updateSession(withTopic topic: String, namespaces: [String: SessionNamespace]) async throws
    func emitEvent(_ event: Session.Event, on blockchain: BlockchainSdk.Blockchain)

    func disconnectAllSessionsForUserWallet(with userWalletId: String)
    func handleHiddenBlockchainFromCurrentUserWallet(_ blockchain: BlockchainSdk.Blockchain)
}
