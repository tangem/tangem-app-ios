//
//  CommonWCService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import UIKit
import ReownWalletKit
import TangemUIUtils

final class CommonWCService {
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
    private let dAppSessionsExtender: WalletConnectDAppSessionsExtender

    private let v2Service: WCServiceV2

    init(v2Service: WCServiceV2, dAppSessionsExtender: WalletConnectDAppSessionsExtender) {
        self.v2Service = v2Service
        self.dAppSessionsExtender = dAppSessionsExtender
    }
}

extension CommonWCService: WCService {
    var transactionRequestPublisher: AnyPublisher<WCHandleTransactionData, WalletConnectV2Error> {
        v2Service.transactionRequestPublisher
    }

    func initialize() {
        incomingActionManager.becomeFirstResponder(self)

        Task {
            await dAppSessionsExtender.extendConnectedDAppSessionsIfNeeded()
        }
    }

    func reset() {
        incomingActionManager.resignFirstResponder(self)
    }

    func openSession(with uri: WalletConnectRequestURI) async throws -> (Session.Proposal, VerifyContext?) {
        switch uri {
        case .v2(let v2URI):
            try await v2Service.openSession(with: v2URI)
        }
    }

    func approveSessionProposal(with proposalID: String, namespaces: [String: SessionNamespace]) async throws -> Session {
        try await v2Service.approveSessionProposal(with: proposalID, namespaces: namespaces)
    }

    func rejectSessionProposal(with proposalID: String, reason: RejectionReason) async throws {
        try await v2Service.rejectSessionProposal(with: proposalID, reason: reason)
    }

    func disconnectSession(withTopic topic: String) async throws {
        try await v2Service.disconnectSession(withTopic: topic)
    }

    func disconnectAllSessionsForUserWallet(with userWalletId: String) {
        v2Service.disconnectAllSessionsForUserWallet(with: userWalletId)
    }
}

// MARK: - IncomingActionResponder

extension CommonWCService: IncomingActionResponder {
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        guard case .walletConnect(let uri) = action else {
            return false
        }

        UIApplication.mainWindow?.endEditing(true)

        Task { @MainActor in
            guard let viewModel = WalletConnectModuleFactory.makeDAppConnectionViewModel(forURI: uri, source: .deeplink) else { return }
            viewModel.loadDAppProposal()
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }

        return true
    }
}
