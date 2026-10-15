//
//  MCPConnectionRequestProposalViewModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import protocol Combine.ObservableObject
import struct Combine.Published
private import struct TangemFoundation.UserWalletId

@MainActor
final class MCPConnectionRequestProposalViewModel: ObservableObject, HashableObject {
    private let userCode: String
    private let interactor: MCPConnectionRequestInteractor
    private let delegate: Delegate

    private var connectionRequest: MCPConnectionRequest?

    private var fetchConnectionRequestTask: Task<Void, Never>?
    private var rejectConnectionTask: Task<Void, Never>?
    private var acceptConnectionTask: Task<Void, Never>?

    @Published private(set) var state: MCPConnectionRequestProposalState

    init(
        state: MCPConnectionRequestProposalState,
        userCode: String,
        interactor: MCPConnectionRequestInteractor,
        delegate: Delegate
    ) {
        self.state = state

        self.userCode = userCode
        self.interactor = interactor
        self.delegate = delegate
    }

    deinit {
        fetchConnectionRequestTask?.cancel()
        rejectConnectionTask?.cancel()
        acceptConnectionTask?.cancel()
    }
}

extension MCPConnectionRequestProposalViewModel {
    func handle(action: MCPConnectionRequestProposalAction) {
        switch action {
        case .fetchInitiated:
            handleFetchInitiated()

        case .fetchSucceeded(let connectionRequest):
            handleFetchSucceeded(connectionRequest)

        case .userWalletSelectorTapped:
            delegate.userWalletSelectorTapped()

        case .userWalletSelectionUpdated(let selectedUserWallet):
            state.userWalletSelector.selection = selectedUserWallet

        case .openSystemSettingsButtonTapped:
            delegate.openSystemSettingsButtonTapped()

        case .declineButtonTapped:
            handleDeclineButtonTapped()

        case .connectButtonTapped:
            handleConnectButtonTapped()
        }
    }

    private func handleFetchInitiated() {
        guard fetchConnectionRequestTask == nil else {
            assertionFailure("Method is expected to be called only once. Developer mistake.")
            return
        }

        fetchConnectionRequestTask = Task { [fetchRequest = interactor.fetchRequest, userCode, weak self] in
            do throws(MCPConnectionClientError) {
                let connectionRequest = try await fetchRequest(userCode: userCode)
                self?.handle(action: .fetchSucceeded(connectionRequest))
            } catch {
                self?.delegate.fetchRequestFailed(error)
            }
        }
    }

    private func handleFetchSucceeded(_ connectionRequest: MCPConnectionRequest) {
        self.connectionRequest = connectionRequest

        state.agentSummary = .content(
            MCPConnectionRequestProposalState.AgentSummary.Agent(
                iconURL: nil,
                name: connectionRequest.agent.name ?? "",
                host: connectionRequest.agent.host ?? ""
            )
        )
        state.declineButton.state = .enabled
        state.connectButton.state = .enabled
    }

    private func handleDeclineButtonTapped() {
        guard let connectionRequest else {
            assertionFailure("Decline button is not expected to be enabled without loaded request. Developer mistake.")
            return
        }

        state.declineButton.state = .loading
        state.connectButton.state = .disabled

        rejectConnectionTask = Task { [reject = interactor.reject, weak self] in
            do throws(MCPConnectionClientError) {
                try await reject(request: connectionRequest)
                self?.delegate.connectionRejected(Result.success(()))
            } catch {
                self?.delegate.connectionRejected(Result.failure(error))
            }

            self?.state.resetButtons()
        }
    }

    private func handleConnectButtonTapped() {
        guard let connectionRequest else {
            assertionFailure("Connect button is not expected to be enabled without loaded request. Developer mistake.")
            return
        }

        state.declineButton.state = .disabled
        state.connectButton.state = .loading

        let userWalletID = state.userWalletSelector.selection.id

        acceptConnectionTask = Task { [accept = interactor.accept, weak self] in
            do throws(AcceptMCPConnectionError) {
                try await accept(request: connectionRequest, for: userWalletID)
                self?.delegate.connectionAccepted(Result.success(connectionRequest.agent.name ?? ""))
            } catch AcceptMCPConnectionError.pushNotificationsDisabled {
                // [REDACTED_TODO_COMMENT]
                self?.state.pushPermissionsBanner = MCPConnectionRequestProposalState.PushNotificationsPermissionBanner()
                self?.state.declineButton.state = .enabled
                self?.state.connectButton.state = .disabled
                return
            } catch {
                self?.delegate.connectionAccepted(Result.failure(error))
            }

            self?.state.resetButtons()
        }
    }
}

extension MCPConnectionRequestProposalViewModel {
    struct Delegate {
        let fetchRequestFailed: (MCPConnectionClientError) -> Void
        let userWalletSelectorTapped: () -> Void
        let openSystemSettingsButtonTapped: () -> Void
        let connectionRejected: (Result<Void, MCPConnectionClientError>) -> Void
        let connectionAccepted: (Result<String, AcceptMCPConnectionError>) -> Void
    }
}

extension MCPConnectionRequestProposalState {
    mutating func resetButtons() {
        declineButton.state = .enabled
        connectButton.state = .enabled
    }
}
