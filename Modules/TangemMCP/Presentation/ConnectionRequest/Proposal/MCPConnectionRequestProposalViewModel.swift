//
//  MCPConnectionRequestProposalViewModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import protocol Combine.ObservableObject
import struct Combine.Published
import class Foundation.NotificationCenter
private import class UIKit.UIApplication
private import struct TangemFoundation.UserWalletId

@MainActor
final class MCPConnectionRequestProposalViewModel: ObservableObject, HashableObject {
    private let userCode: String
    private let interactor: MCPConnectionRequestInteractor
    private let notificationCenter: NotificationCenter
    private let delegate: Delegate

    private var connectionRequest: MCPConnectionRequest?
    private var hasRequestedPushNotificationsAuthorizationAtLeastOnce = false

    private var applicationLifecycleObservationTask: Task<Void, Never>?
    private var fetchConnectionRequestTask: Task<Void, Never>?
    private var rejectConnectionTask: Task<Void, Never>?
    private var acceptConnectionTask: Task<Void, Never>?

    @Published private(set) var state: MCPConnectionRequestProposalState

    init(
        state: MCPConnectionRequestProposalState,
        userCode: String,
        interactor: MCPConnectionRequestInteractor,
        notificationCenter: NotificationCenter = NotificationCenter.default,
        delegate: Delegate
    ) {
        self.state = state

        self.userCode = userCode
        self.interactor = interactor
        self.notificationCenter = notificationCenter
        self.delegate = delegate
    }

    deinit {
        applicationLifecycleObservationTask?.cancel()
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

        case .applicationWillEnterForeground:
            handleApplicationWillEnterForeground()

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

        observeApplicationLifecycle()

        fetchConnectionRequestTask = Task { [fetchRequest = interactor.fetchRequest, userCode, weak self] in
            do throws(MCPConnectionClientError) {
                let connectionRequest = try await fetchRequest(userCode: userCode)
                self?.handle(action: .fetchSucceeded(connectionRequest))
            } catch {
                self?.delegate.fetchRequestFailed(error)
            }
        }
    }

    private func handleApplicationWillEnterForeground() {
        let hasFinishedLoadingProposal = connectionRequest != nil

        guard hasFinishedLoadingProposal, hasRequestedPushNotificationsAuthorizationAtLeastOnce else { return }

        Task { [weak self, interactor] in
            let pushNotificationsAuthorized = await interactor.ensurePushNotificationsAuthorized()

            guard let self else { return }

            let notRejectingAtTheMoment = rejectConnectionTask == nil
            let notAcceptingAtTheMoment = acceptConnectionTask == nil

            guard pushNotificationsAuthorized, notRejectingAtTheMoment, notAcceptingAtTheMoment else {
                return
            }

            state.pushPermissionsBanner = nil
            state.declineButton.state = .enabled
            state.connectButton.state = .enabled
        }
    }

    private func handleFetchSucceeded(_ connectionRequest: MCPConnectionRequest) {
        self.connectionRequest = connectionRequest

        state.agentSummary = .content(
            MCPConnectionRequestProposalState.AgentSummary.Agent(
                iconURL: connectionRequest.agent.iconURL,
                name: connectionRequest.agent.name ?? "",
                host: connectionRequest.agent.host ?? ""
            )
        )
        state.declineButton.state = .enabled
        state.connectButton.state = .enabled
    }

    private func handleDeclineButtonTapped() {
        guard case .enabled = state.declineButton.state else {
            return
        }

        guard let connectionRequest else {
            assertionFailure("Decline button is not expected to be enabled without loaded request. Developer mistake.")
            return
        }

        state.declineButton.state = .loading
        state.connectButton.state = .disabled
        state.userWalletSelector.isEnabled = false

        rejectConnectionTask = Task { [reject = interactor.reject, weak self] in
            do throws(MCPConnectionClientError) {
                try await reject(request: connectionRequest)
                self?.delegate.connectionRejected(Result.success(()))
            } catch {
                self?.delegate.connectionRejected(Result.failure(error))
            }

            self?.rejectConnectionTask = nil
            self?.state.declineButton.state = .enabled
            self?.state.connectButton.state = .enabled
            self?.state.userWalletSelector.isEnabled = true
        }
    }

    private func handleConnectButtonTapped() {
        guard case .enabled = state.connectButton.state else {
            return
        }

        guard let connectionRequest else {
            assertionFailure("Connect button is not expected to be enabled without loaded request. Developer mistake.")
            return
        }

        state.declineButton.state = .disabled
        state.connectButton.state = .loading
        state.userWalletSelector.isEnabled = false

        let userWalletID = state.userWalletSelector.selection.id

        acceptConnectionTask = Task { [interactor, weak self] in
            self?.hasRequestedPushNotificationsAuthorizationAtLeastOnce = true

            defer {
                self?.acceptConnectionTask = nil
                self?.state.declineButton.state = .enabled
                self?.state.userWalletSelector.isEnabled = true
            }

            guard await interactor.ensurePushNotificationsAuthorized() else {
                self?.state.pushPermissionsBanner = MCPConnectionRequestProposalState.PushNotificationsPermissionBanner()
                self?.state.connectButton.state = .disabled
                return
            }

            do throws(MCPConnectionClientError) {
                try await interactor.accept(request: connectionRequest, for: userWalletID)
                self?.delegate.connectionAccepted(Result.success(connectionRequest.agent.name ?? ""))
            } catch {
                self?.delegate.connectionAccepted(Result.failure(error))
            }

            self?.state.connectButton.state = .enabled
        }
    }

    private func observeApplicationLifecycle() {
        applicationLifecycleObservationTask = Task { [weak self, notificationCenter] in
            for await _ in notificationCenter.notifications(named: UIApplication.willEnterForegroundNotification) {
                self?.handle(action: .applicationWillEnterForeground)
            }
        }
    }
}

extension MCPConnectionRequestProposalViewModel {
    struct Delegate {
        let fetchRequestFailed: (MCPConnectionClientError) -> Void
        let userWalletSelectorTapped: () -> Void
        let openSystemSettingsButtonTapped: () -> Void
        let connectionRejected: (Result<Void, MCPConnectionClientError>) -> Void
        let connectionAccepted: (Result<String, MCPConnectionClientError>) -> Void
    }
}
