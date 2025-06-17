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

    private let v2Service: WCServiceV2

    init() {
        v2Service = WCFactory().createWCService()
    }
}

extension CommonWCService: WCService {
    var transactionRequestPublisher: AnyPublisher<WCHandleTransactionData, WalletConnectV2Error> {
        v2Service.transactionRequestPublisher
    }

    var newSessions: AsyncStream<[WalletConnectSavedSession]> {
        get async {
            await v2Service.newSessions
        }
    }

    func initialize() {
        v2Service.initialize()
        incomingActionManager.becomeFirstResponder(self)
    }

    func reset() {
        incomingActionManager.resignFirstResponder(self)
    }

    func openSession(with uri: WalletConnectRequestURI, source: Analytics.WalletConnectSessionSource) async throws -> Session.Proposal {
        switch uri {
        case .v2(let v2URI):
            try await v2Service.openSession(with: v2URI, source: source)
        }
    }

    // [REDACTED_TODO_COMMENT]
    func approveSessionProposal(with proposalID: String, namespaces: [String: SessionNamespace], _ userWalletID: String) async throws {
        try await v2Service.approveSessionProposal(with: proposalID, namespaces: namespaces, userWalletID)
    }

    func rejectSessionProposal(with proposalID: String, reason: RejectionReason) async throws {
        try await v2Service.rejectSessionProposal(with: proposalID, reason: reason)
    }

    func disconnectSession(with id: Int) async {
        await v2Service.disconnectSession(with: id)
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
