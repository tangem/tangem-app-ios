//
//  MCPConnectionRequestViewModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Combine
import struct TangemFoundation.UserWalletId
import struct TangemLogger.Logger
public import protocol TangemUI.FloatingSheetContentViewModel

@MainActor
public final class MCPConnectionRequestViewModel: ObservableObject, FloatingSheetContentViewModel {
    private let userWallets: [MCPUserWallet]
    private let userWalletImageRepository: MCPUserWalletImageRepository
    private let userWalletBalanceUpdater: (MCPUserWallet.ID) -> AsyncStream<String>
    private let delegate: Delegate

    private let logger: TangemLogger.Logger

    private let proposalViewModel: MCPConnectionRequestProposalViewModel

    private lazy var userWalletSelectorViewModel: MCPConnectionRequestUserWalletSelectorViewModel = make()
    private static let userWalletSelectorAutoCloseDelay = Duration.seconds(1)
    private var userWalletSelectorAutoCloseTask: Task<Void, any Error>?

    private var pushPermissionsCancellable: AnyCancellable?

    @Published private(set) var state: MCPConnectionRequestState

    init(
        userWallets: [MCPUserWallet],
        userWalletImageRepository: MCPUserWalletImageRepository,
        userWalletBalanceUpdater: @escaping (MCPUserWallet.ID) -> AsyncStream<String>,
        selectedUserWallet: MCPUserWallet,
        userCode: String,
        interactor: MCPConnectionRequestInteractor,
        delegate: Delegate,
        logger: TangemLogger.Logger,
    ) {
        self.userWallets = userWallets
        self.userWalletImageRepository = userWalletImageRepository
        self.userWalletBalanceUpdater = userWalletBalanceUpdater

        self.delegate = delegate
        self.logger = logger

        let isUserWalletSelectionAllowed = userWallets.count > 1

        weak var futureSelf: MCPConnectionRequestViewModel?

        self.proposalViewModel = MCPConnectionRequestProposalViewModel(
            state: MCPConnectionRequestProposalState.initialLoading(
                userWalletSelector: MCPConnectionRequestProposalState.UserWalletSelector(
                    isSelectionAllowed: isUserWalletSelectionAllowed,
                    isEnabled: true,
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

        pushPermissionsCancellable = proposalViewModel.$state.map(\.pushPermissionsBanner).sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    deinit {
        userWalletSelectorAutoCloseTask?.cancel()
    }
}

extension MCPConnectionRequestViewModel {
    func handle(action: MCPConnectionRequestAction) {
        switch action {
        case .viewDidLoad:
            proposalViewModel.handle(action: .fetchInitiated)

        case .backButtonTapped:
            guard case .userWalletSelector = state else {
                assertionFailure("MCPConnectionRequestAction.backButtonTapped sent from unexpected state. Developer mistake.")
                return
            }
            userWalletSelectorAutoCloseTask?.cancel()
            state = .proposal(proposalViewModel)

        case .closeButtonTapped:
            delegate.closeButtonTapped()

        case .openSystemSettingsButtonTapped:
            delegate.openSystemSettingsButtonTapped()

        case .userWalletSelectorTapped:
            state = .userWalletSelector(userWalletSelectorViewModel)

        case .userWalletSelectionUpdated(let selectedUserWallet):
            handleUserWalletSelectionUpdated(selectedUserWallet)

        case .userWalletSelectorAutoCloseDelayElapsed:
            guard case .userWalletSelector = state else { return }
            state = .proposal(proposalViewModel)

        case .fetchRequestFailed(let error):
            logger.error("Proposal fetch request failed", error: error)
            delegate.fetchRequestErrorOccurred(error)

        case .agentConnectionRejected(let rejectResult):
            handle(rejectResult: rejectResult)

        case .agentConnectionAccepted(let acceptResult):
            handle(acceptResult: acceptResult)
        }
    }

    private func handleUserWalletSelectionUpdated(_ selectedUserWallet: MCPUserWallet) {
        let selectionChanged = proposalViewModel.state.userWalletSelector.selection != selectedUserWallet
        proposalViewModel.handle(action: .userWalletSelectionUpdated(selectedUserWallet))

        let sleepDuration = selectionChanged ? Self.userWalletSelectorAutoCloseDelay : Duration.zero

        userWalletSelectorAutoCloseTask?.cancel()
        userWalletSelectorAutoCloseTask = Task { [weak self] in
            try await Task.sleep(for: sleepDuration)
            self?.handle(action: .userWalletSelectorAutoCloseDelayElapsed)
        }
    }

    private func handle(rejectResult: Result<Void, MCPConnectionClientError>) {
        switch rejectResult {
        case .success:
            logger.debug("Proposal reject succeeded")

        case .failure(let error):
            logger.error("Proposal reject failed", error: error)
        }

        delegate.proposalRejected(rejectResult)
    }

    private func handle(acceptResult: Result<String, MCPConnectionClientError>) {
        switch acceptResult {
        case .success(let agentName):
            logger.debug("Proposal accept succeeded")
            let agentConnectedViewModel = MCPConnectionRequestAgentConnectedViewModel(
                doneButtonAction: delegate.closeButtonTapped,
                state: MCPConnectionRequestAgentConnectedState(agentName: agentName)
            )
            state = .agentConnected(agentConnectedViewModel)

        case .failure(let error):
            logger.error("Proposal accept failed", error: error)
            delegate.proposalAcceptErrorOccurred(error)
        }
    }
}

extension MCPConnectionRequestViewModel {
    private func make() -> MCPConnectionRequestUserWalletSelectorViewModel {
        MCPConnectionRequestUserWalletSelectorViewModel(
            userWallets: userWallets,
            selectedUserWalletID: proposalViewModel.state.userWalletSelector.selection.id,
            userWalletImageRepository: userWalletImageRepository,
            balanceUpdater: userWalletBalanceUpdater,
            selectionChanged: { [weak self] selectedUserWallet in
                self?.handle(action: .userWalletSelectionUpdated(selectedUserWallet))
            }
        )
    }
}

extension MCPConnectionRequestViewModel {
    struct Delegate {
        let closeButtonTapped: () -> Void
        let openSystemSettingsButtonTapped: () -> Void
        let fetchRequestErrorOccurred: (MCPConnectionClientError) -> Void
        let proposalRejected: (Result<Void, MCPConnectionClientError>) -> Void
        let proposalAcceptErrorOccurred: (MCPConnectionClientError) -> Void
    }
}
