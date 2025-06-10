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
    var newSessions: AsyncStream<[WalletConnectSavedSession]> { get async }

    func initialize()
    func reset()

    func openSession(with uri: WalletConnectRequestURI, source: Analytics.WalletConnectSessionSource) async throws -> Session.Proposal
    // [REDACTED_TODO_COMMENT]
    func approveSessionProposal(with proposalID: String, namespaces: [String: SessionNamespace], _ userWalletID: String) async throws
    func rejectSessionProposal(with proposalID: String, reason: RejectionReason) async throws

    func disconnectSession(with id: Int) async
    func disconnectAllSessionsForUserWallet(with userWalletId: String)
}

private struct WCServiceKey: InjectionKey {
    static var currentValue: WCService = CommonWCService()
}

extension InjectedValues {
    var wcService: WCService {
        get { Self[WCServiceKey.self] }
        set { Self[WCServiceKey.self] = newValue }
    }
}
