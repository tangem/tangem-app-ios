//
//  WCService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import ReownWalletKit

protocol WCService {
    var transactionRequestPublisher: AnyPublisher<WCHandleTransactionData, WalletConnectV2Error> { get }

    func initialize()
    func reset()

    func openSession(with uri: WalletConnectRequestURI) async throws -> (Session.Proposal, VerifyContext?)

    func approveSessionProposal(with proposalID: String, namespaces: [String: SessionNamespace]) async throws -> Session
    func rejectSessionProposal(with proposalID: String, reason: RejectionReason) async throws
    func disconnectSession(withTopic topic: String) async throws

    func disconnectAllSessionsForUserWallet(with userWalletId: String)
}
