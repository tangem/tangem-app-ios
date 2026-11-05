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
    private let retrieveUserWalletRegistrationStatus: RetrieveUserWalletRegistrationStatus
    private let delegate: Delegate

    private let analyticsReporter: any MCPAuthorizationAnalyticsReporter
    private let logger: TangemLogger.Logger

    private let proposalViewModel: MCPConnectionRequestProposalViewModel

    private lazy var userWalletSelectorViewModel: MCPConnectionRequestUserWalletSelectorViewModel = make()
    private var userWalletSelectionTask: Task<Void, Never>?

    private var pushPermissionsCancellable: AnyCancellable?

    var isPushPermissionsBannerVisible: Bool {
        proposalViewModel.state.pushPermissionsBanner != nil
    }

    @Published private(set) var state: MCPConnectionRequestState

    init(
        userWallets: [MCPUserWallet],
        userWalletImageRepository: MCPUserWalletImageRepository,
        userWalletBalanceUpdater: @escaping (MCPUserWallet.ID) -> AsyncStream<String>,
        selectedUserWallet: MCPUserWallet,
        userCode: String,
        interactor: MCPConnectionRequestInteractor,
        delegate: Delegate,
        analyticsReporter: some MCPAuthorizationAnalyticsReporter,
        logger: TangemLogger.Logger
    ) {
        self.userWallets = userWallets
        self.userWalletImageRepository = userWalletImageRepository
        self.userWalletBalanceUpdater = userWalletBalanceUpdater
        retrieveUserWalletRegistrationStatus = interactor.retrieveUserWalletRegistrationStatus

        self.delegate = delegate
        self.analyticsReporter = analyticsReporter
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
                unregisteredUserWalletSelected: {
                    futureSelf?.handle(action: .unregisteredUserWalletSelected)
                },
                connectionRejected: { rejectResult in
                    futureSelf?.handle(action: .agentConnectionRejected(rejectResult))
                },
                connectionAccepted: { acceptResult in
                    futureSelf?.handle(action: .agentConnectionAccepted(acceptResult))
                }
            ),
            analyticsReporter: analyticsReporter,
            logger: logger
        )

        self.state = MCPConnectionRequestState.proposal(proposalViewModel)

        futureSelf = self

        pushPermissionsCancellable = proposalViewModel.$state
            .map(\.pushPermissionsBanner)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
    }
}

extension MCPConnectionRequestViewModel {
    func handle(action: MCPConnectionRequestAction) {
        switch action {
        case .viewDidLoad:
            proposalViewModel.handle(action: .fetchInitiated)

        case .navigationBackButtonTapped:
            guard case .userWalletSelector = state else {
                assertionFailure("MCPConnectionRequestAction.backButtonTapped sent from unexpected state. Developer mistake.")
                return
            }
            state = .proposal(proposalViewModel)

        case .navigationCloseButtonTapped:
            handleNavigationCloseButtonTapped()

        case .openSystemSettingsButtonTapped:
            delegate.openSystemSettingsButtonTapped()

        case .userWalletSelectorTapped:
            state = .userWalletSelector(userWalletSelectorViewModel)

        case .userWalletSelectionRequested(let userWallet):
            handleUserWalletSelectionRequested(userWallet)

        case .userWalletSelectionUpdated(let selectedUserWallet):
            handleUserWalletSelectionUpdated(selectedUserWallet)

        case .unregisteredUserWalletSelected:
            delegate.unregisteredUserWalletSelected()

        case .fetchRequestFailed(let error):
            analyticsReporter.reportAuthorizationFailed(errorCode: error.errorCode)
            logger.error("Proposal fetch request failed", error: error)
            delegate.fetchRequestErrorOccurred(error)

        case .agentConnectionRejected(let rejectResult):
            handle(rejectResult: rejectResult)

        case .agentConnectionAccepted(let acceptResult):
            handle(acceptResult: acceptResult)
        }
    }

    private func handleNavigationCloseButtonTapped() {
        switch state {
        case .proposal, .userWalletSelector:
            if proposalViewModel.isAcceptingConnection {
                delegate.proposalAccepted(proposalViewModel.state.userWalletSelector.selection.id)
            }

            proposalViewModel.handle(action: .navigationCloseButtonTapped)

        case .agentConnected:
            break
        }

        delegate.closeButtonTapped()
    }

    private func handleUserWalletSelectionRequested(_ userWallet: MCPUserWallet) {
        userWalletSelectionTask?.cancel()
        userWalletSelectionTask = Task { [weak self, retrieveUserWalletRegistrationStatus] in
            let isRegistered = await retrieveUserWalletRegistrationStatus(userWallet.id)

            guard !Task.isCancelled else { return }

            self?.handle(action: isRegistered ? .userWalletSelectionUpdated(userWallet) : .unregisteredUserWalletSelected)
        }
    }

    private func handleUserWalletSelectionUpdated(_ selectedUserWallet: MCPUserWallet) {
        proposalViewModel.handle(action: .userWalletSelectionUpdated(selectedUserWallet))
        userWalletSelectorViewModel.handle(action: .selectionUpdated(selectedUserWallet.id))

        guard case .userWalletSelector = state else { return }
        state = .proposal(proposalViewModel)
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
            delegate.proposalAccepted(proposalViewModel.state.userWalletSelector.selection.id)
            let agentConnectedViewModel = MCPConnectionRequestAgentConnectedViewModel(
                doneAction: delegate.closeButtonTapped,
                state: MCPConnectionRequestAgentConnectedState(agentName: agentName)
            )
            state = .agentConnected(agentConnectedViewModel)

        case .failure(let error):
            analyticsReporter.reportAuthorizationFailed(errorCode: error.errorCode)
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
            selectionRequested: { [weak self] userWallet in
                self?.handle(action: .userWalletSelectionRequested(userWallet))
            }
        )
    }
}

extension MCPConnectionRequestViewModel {
    struct Delegate {
        let closeButtonTapped: () -> Void
        let openSystemSettingsButtonTapped: () -> Void
        let unregisteredUserWalletSelected: () -> Void
        let fetchRequestErrorOccurred: (MCPConnectionClientError) -> Void
        let proposalRejected: (Result<Void, MCPConnectionClientError>) -> Void
        let proposalAccepted: (UserWalletId) -> Void
        let proposalAcceptErrorOccurred: (MCPConnectionClientError) -> Void
    }
}
