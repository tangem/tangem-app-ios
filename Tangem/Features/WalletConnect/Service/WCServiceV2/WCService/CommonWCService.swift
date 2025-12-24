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
import enum BlockchainSdk.Blockchain
import TangemFoundation
import TangemUIUtils

final class CommonWCService {
    @Injected(\.userWalletRepository) private var userWalletRepository: any UserWalletRepository
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    private let v2Service: WCServiceV2
    private let dAppSessionsExtender: WalletConnectDAppSessionsExtender

    private var userWalletRepositoryEventsCancelable: AnyCancellable?

    @MainActor
    private var hasInitialized = false

    init(v2Service: WCServiceV2, dAppSessionsExtender: WalletConnectDAppSessionsExtender) {
        self.v2Service = v2Service
        self.dAppSessionsExtender = dAppSessionsExtender
    }
}

extension CommonWCService: WCService {
    var transactionRequestPublisher: AnyPublisher<Result<WCHandleTransactionData, any Error>, Never> {
        v2Service.transactionRequestPublisher
    }

    func initialize() {
        userWalletRepositoryEventsCancelable = userWalletRepository
            .eventProvider
            .receiveOnMain()
            .sink { [weak self, userWalletRepository, incomingActionManager, dAppSessionsExtender] walletRepositoryEvent in
                MainActor.assumeIsolated {
                    guard
                        let self,
                        !self.hasInitialized,
                        userWalletRepository.models.isNotEmpty
                    else {
                        return
                    }

                    switch walletRepositoryEvent {
                    case .locked:
                        // do nothing for locked event
                        break

                    case .unlocked, .inserted, .unlockedWallet, .deleted, .selected:
                        self.hasInitialized = true
                        incomingActionManager.becomeFirstResponder(self)

                        Task {
                            await dAppSessionsExtender.extendConnectedDAppSessionsIfNeeded()
                        }
                    }
                }
            }
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

    func updateSession(withTopic topic: String, namespaces: [String: SessionNamespace]) async throws {
        try await v2Service.updateSession(withTopic: topic, namespaces: namespaces)
    }

    func emitEvent(_ event: Session.Event, on blockchain: BlockchainSdk.Blockchain) {
        v2Service.emitEvent(event, on: blockchain)
    }

    func disconnectAllSessionsForUserWallet(with userWalletId: String) {
        v2Service.disconnectAllSessionsForUserWallet(with: userWalletId)
    }

    func handleHiddenBlockchainFromCurrentUserWallet(_ blockchain: BlockchainSdk.Blockchain) {
        v2Service.handleHiddenBlockchainFromCurrentUserWallet(blockchain)
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
