//
//  MCPConnectionRequestViewModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import protocol Combine.ObservableObject
import struct Combine.Published
import struct TangemFoundation.UserWalletId

@MainActor
final class MCPConnectionRequestViewModel: ObservableObject {
    private let userWallets: [MCPUserWallet]
    private let closeAction: () -> Void
    private let openSystemSettingsAction: () -> Void

    private let proposalViewModel: MCPConnectionRequestProposalViewModel
    private lazy var userWalletSelectorViewModel: MCPConnectionRequestUserWalletSelectorViewModel = make()

    @Published private(set) var state: MCPConnectionRequestState

    init(
        userWallets: [MCPUserWallet],
        selectedUserWallet: MCPUserWallet,
        userCode: String,
        interactor: MCPConnectionRequestInteractor,
        openSystemSettingsAction: @escaping () -> Void,
        closeAction: @escaping () -> Void
    ) {
        self.userWallets = userWallets
        self.closeAction = closeAction
        self.openSystemSettingsAction = openSystemSettingsAction

        let shouldAllowSelection = userWallets.count > 1

        weak var futureSelf: MCPConnectionRequestViewModel?

        self.proposalViewModel = MCPConnectionRequestProposalViewModel(
            state: MCPConnectionRequestProposalState.initialLoading(
                userWalletSelector: MCPConnectionRequestProposalState.UserWalletSelector(
                    enabled: shouldAllowSelection,
                    selection: selectedUserWallet
                )
            ),
            userCode: userCode,
            interactor: interactor,
            delegate: MCPConnectionRequestProposalViewModel.Delegate(
                fetchRequestFailed: { fetchError in
                    futureSelf?.handle(action: .fetchRequestFailed(fetchError))
                },
                userWalletSelectorTapped: {
                    futureSelf?.handle(action: .userWalletSelectorTapped)
                },
                openSystemSettingsButtonTapped: {
                    futureSelf?.handle(action: .openSystemSettingsButtonTapped)
                },
                connectionRejected: { rejectResult in
                    futureSelf?.handle(action: .agentConnectionRejected(rejectResult))
                },
                connectionAccepted: { acceptResult in
                    futureSelf?.handle(action: .agentConnectionAccepted(acceptResult))
                }
            )
        )

        self.state = MCPConnectionRequestState.proposal(proposalViewModel)

        futureSelf = self
    }
}

extension MCPConnectionRequestViewModel {
    func handle(action: MCPConnectionRequestAction) {
        switch action {
        case .backButtonTapped:
            guard case .userWalletSelector = state else { return }
            state = .proposal(proposalViewModel)

        case .closeButtonTapped:
            closeAction()

        case .openSystemSettingsButtonTapped:
            openSystemSettingsAction()

        case .userWalletSelectorTapped:
            state = .userWalletSelector(userWalletSelectorViewModel)

        case .userWalletSelectionUpdated(let selectedUserWallet):
            proposalViewModel.handle(action: .userWalletSelectionUpdated(selectedUserWallet))

        case .fetchRequestFailed(let error):
            handle(fetchRequestError: error)

        case .agentConnectionRejected(let rejectResult):
            handle(rejectResult: rejectResult)

        case .agentConnectionAccepted(let acceptResult):
            handle(acceptResult: acceptResult)
        }
    }

    private func handle(fetchRequestError: MCPConnectionClientError) {
        // [REDACTED_TODO_COMMENT]
    }

    private func handle(rejectResult: Result<Void, MCPConnectionClientError>) {
        // [REDACTED_TODO_COMMENT]
    }

    private func handle(acceptResult: Result<String, AcceptMCPConnectionError>) {
        switch acceptResult {
        case .success(let agentName):
            let agentConnectedViewModel = MCPConnectionRequestAgentConnectedViewModel(
                doneButtonAction: closeAction,
                state: MCPConnectionRequestAgentConnectedState(agentName: agentName)
            )
            state = .agentConnected(agentConnectedViewModel)

        case .failure:
            // [REDACTED_TODO_COMMENT]
            // [REDACTED_TODO_COMMENT]
            closeAction()
        }
    }
}

extension MCPConnectionRequestViewModel {
    private func make() -> MCPConnectionRequestUserWalletSelectorViewModel {
        MCPConnectionRequestUserWalletSelectorViewModel(
            state: MCPConnectionRequestUserWalletSelectorState(
                userWallets: userWallets,
                selectedUserWalletID: proposalViewModel.state.userWalletSelector.selection.id
            ),
            selectionChanged: { [weak self] selectedUserWallet in
                self?.handle(action: .userWalletSelectionUpdated(selectedUserWallet))
            }
        )
    }
}
