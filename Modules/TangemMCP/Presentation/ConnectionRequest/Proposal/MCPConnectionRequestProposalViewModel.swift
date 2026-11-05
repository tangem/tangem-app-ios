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
import struct TangemLogger.Logger

@MainActor
final class MCPConnectionRequestProposalViewModel: ObservableObject, HashableObject {
    private let userCode: String
    private let interactor: MCPConnectionRequestInteractor
    private let notificationCenter: NotificationCenter
    private let delegate: Delegate

    private let analyticsReporter: any MCPAuthorizationAnalyticsReporter
    private let logger: TangemLogger.Logger

    private var connectionRequest: MCPConnectionRequest?
    private var hasRequestedPushNotificationsAuthorizationAtLeastOnce = false

    private var applicationLifecycleObservationTask: Task<Void, Never>?
    private var fetchConnectionRequestTask: Task<Void, Never>?
    private var fireAndForgetRejectConnectionTask: Task<Void, Never>?
    private var rejectConnectionTask: Task<Void, Never>?
    private var acceptConnectionTask: Task<Void, Never>?
    private var hasBeenClosed = false

    private(set) var isAcceptingConnection = false

    @Published private(set) var state: MCPConnectionRequestProposalState

    init(
        state: MCPConnectionRequestProposalState,
        userCode: String,
        interactor: MCPConnectionRequestInteractor,
        notificationCenter: NotificationCenter = NotificationCenter.default,
        delegate: Delegate,
        analyticsReporter: some MCPAuthorizationAnalyticsReporter,
        logger: TangemLogger.Logger
    ) {
        self.state = state

        self.userCode = userCode
        self.interactor = interactor
        self.notificationCenter = notificationCenter
        self.delegate = delegate

        self.analyticsReporter = analyticsReporter
        self.logger = logger
    }

    deinit {
        applicationLifecycleObservationTask?.cancel()
        fetchConnectionRequestTask?.cancel()
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

        case .navigationCloseButtonTapped:
            handleNavigationCloseButtonTapped()

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
                let connectionRequest = try await fetchRequest(userCode)
                self?.handle(action: .fetchSucceeded(connectionRequest))
            } catch {
                self?.delegate.fetchRequestFailed(error)
            }
        }
    }

    private func handleApplicationWillEnterForeground() {
        let hasFinishedLoadingProposal = connectionRequest != nil

        guard hasFinishedLoadingProposal, hasRequestedPushNotificationsAuthorizationAtLeastOnce else { return }
        logger.debug("App will enter foreground. Initiating fresh push permissions check.")

        Task { [weak self, interactor] in
            let pushNotificationsAuthorized = await interactor.ensurePushNotificationsAuthorized()

            guard let self else { return }

            guard pushNotificationsAuthorized else {
                logger.debug("App will enter foreground. Push permissions are not granted. Connection is prohibited.")
                return
            }

            logger.debug("App will enter foreground. Push permissions are granted. Connection is allowed.")
            state.pushPermissionsBanner = nil

            let notRejectingAtTheMoment = rejectConnectionTask == nil
            let notAcceptingAtTheMoment = acceptConnectionTask == nil

            guard notRejectingAtTheMoment, notAcceptingAtTheMoment else {
                return
            }

            state.declineButton.state = .enabled
            state.connectButton.state = .enabled
        }
    }

    private func handleFetchSucceeded(_ connectionRequest: MCPConnectionRequest) {
        analyticsReporter.reportAgentConnectionRequested(agent: connectionRequest.agent)
        self.connectionRequest = connectionRequest

        state.agentSummary = .content(connectionRequest.agent)
        state.declineButton.state = .enabled
        state.connectButton.state = .enabled
    }

    private func handleNavigationCloseButtonTapped() {
        guard
            let connectionRequest,
            fireAndForgetRejectConnectionTask == nil,
            rejectConnectionTask == nil
        else {
            return
        }

        hasBeenClosed = true

        guard !isAcceptingConnection else {
            logger.debug("Closed while the connection is being accepted. The connection is kept.")
            return
        }

        acceptConnectionTask?.cancel()
        acceptConnectionTask = nil

        analyticsReporter.reportDeclineButtonTapped(agent: connectionRequest.agent)
        logger.debug("Fire and forget connection request reject initiated.")

        // [REDACTED_USERNAME], intentionally not messing with decline and connect buttons loading or disabled state
        // in order to keep UI clean during close transition.

        fireAndForgetRejectConnectionTask = Task { [reject = interactor.reject, logger] in
            do throws(MCPConnectionClientError) {
                try await reject(connectionRequest)
            } catch {
                logger.error("Fire and forget connection request reject failed", error: error)
            }
        }
    }

    private func handleDeclineButtonTapped() {
        guard
            case .enabled = state.declineButton.state,
            rejectConnectionTask == nil,
            fireAndForgetRejectConnectionTask == nil
        else {
            return
        }

        guard let connectionRequest else {
            assertionFailure("Decline button is not expected to be enabled without loaded request. Developer mistake.")
            return
        }

        analyticsReporter.reportDeclineButtonTapped(agent: connectionRequest.agent)
        state.declineButton.state = .loading
        state.connectButton.state = .disabled
        state.userWalletSelector.isEnabled = false

        rejectConnectionTask = Task { [reject = interactor.reject, weak self] in
            do throws(MCPConnectionClientError) {
                try await reject(connectionRequest)
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
        guard
            case .enabled = state.connectButton.state,
            acceptConnectionTask == nil,
            fireAndForgetRejectConnectionTask == nil
        else {
            return
        }

        guard let connectionRequest else {
            assertionFailure("Connect button is not expected to be enabled without loaded request. Developer mistake.")
            return
        }

        analyticsReporter.reportApproveButtonTapped(agent: connectionRequest.agent)
        state.declineButton.state = .disabled
        state.connectButton.state = .loading
        state.userWalletSelector.isEnabled = false

        let userWalletID = state.userWalletSelector.selection.id

        acceptConnectionTask = Task { [interactor, analyticsReporter, logger, weak self] in
            self?.hasRequestedPushNotificationsAuthorizationAtLeastOnce = true

            defer {
                self?.acceptConnectionTask = nil
                self?.state.declineButton.state = .enabled
                self?.state.userWalletSelector.isEnabled = true
            }

            guard await interactor.ensurePushNotificationsAuthorized() else {
                analyticsReporter.reportPushPermissionRequired()
                logger.debug("Push notifications are disabled. Connection is blocked.")
                self?.state.pushPermissionsBanner = MCPConnectionRequestProposalState.PushNotificationsPermissionBanner()
                self?.state.connectButton.state = .disabled
                return
            }

            guard await interactor.retrieveUserWalletRegistrationStatus(userWalletID) else {
                logger.debug("The selected user wallet isn't registered. Connection is blocked.")
                self?.state.connectButton.state = .enabled
                self?.delegate.unregisteredUserWalletSelected()
                return
            }

            guard !Task.isCancelled, self?.hasBeenClosed == false else {
                return
            }

            self?.isAcceptingConnection = true

            let acceptResult: Result<String, MCPConnectionClientError>

            do throws(MCPConnectionClientError) {
                try await interactor.accept(connectionRequest, userWalletID)
                analyticsReporter.reportAgentConnected(agent: connectionRequest.agent)
                acceptResult = Result.success(connectionRequest.agent.name ?? MCPAgent.fallbackName)
            } catch {
                acceptResult = Result.failure(error)
            }

            self?.isAcceptingConnection = false

            guard let self, !hasBeenClosed else {
                logger.debug("Connection accept finished after the sheet was closed. Result is ignored.")
                return
            }

            delegate.connectionAccepted(acceptResult)

            state.connectButton.state = .enabled
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
        let unregisteredUserWalletSelected: () -> Void
        let connectionRejected: (Result<Void, MCPConnectionClientError>) -> Void
        let connectionAccepted: (Result<String, MCPConnectionClientError>) -> Void
    }
}
