//
//  WalletConnectConnectedDAppDetailsViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemLogger

@MainActor
final class WalletConnectConnectedDAppDetailsViewModel: ObservableObject {
    private let connectedDApp: WalletConnectConnectedDApp
    private let disconnectDAppUseCase: WalletConnectDisconnectDAppUseCase
    private let analyticsLogger: any WalletConnectConnectedDAppDetailsAnalyticsLogger
    private let logger: TangemLogger.Logger
    private let closeAction: () -> Void
    private let onDisconnect: () -> Void
    private let dateFormatter: RelativeDateTimeFormatter

    private var disconnectDAppTask: Task<Void, Never>?
    private var timerCancellable: AnyCancellable?

    @Published private(set) var state: WalletConnectConnectedDAppDetailsViewState

    init(
        connectedDApp: WalletConnectConnectedDApp,
        disconnectDAppUseCase: WalletConnectDisconnectDAppUseCase,
        userWalletRepository: some UserWalletRepository,
        analyticsLogger: some WalletConnectConnectedDAppDetailsAnalyticsLogger,
        logger: TangemLogger.Logger,
        closeAction: @escaping () -> Void,
        onDisconnect: @escaping () -> Void
    ) {
        self.connectedDApp = connectedDApp
        self.disconnectDAppUseCase = disconnectDAppUseCase
        self.analyticsLogger = analyticsLogger
        self.logger = logger
        self.closeAction = closeAction
        self.onDisconnect = onDisconnect

        let dateFormatter = Self.makeDateFormatter()
        self.dateFormatter = dateFormatter
        state = Self.makeInitialState(for: connectedDApp, using: dateFormatter, userWalletRepository: userWalletRepository, logger: logger)

        subscribeToConnectedTimeUpdates()
    }

    deinit {
        disconnectDAppTask?.cancel()
    }

    private func subscribeToConnectedTimeUpdates() {
        timerCancellable = Timer
            .publish(every: .minute, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateConnectedTime()
            }
    }

    private func updateConnectedTime() {
        guard case .dAppDetails(var dAppDetails) = state else {
            return
        }

        dAppDetails.navigationBar.connectedTime = Self.connectedTime(for: connectedDApp, using: dateFormatter)
        state = .dAppDetails(dAppDetails)
    }
}

// MARK: - View events handling

extension WalletConnectConnectedDAppDetailsViewModel {
    func handle(viewEvent: WalletConnectConnectedDAppDetailsViewEvent) {
        switch viewEvent {
        case .closeButtonTapped:
            closeAction()

        case .dAppDetailsAppeared:
            updateConnectedTime()

        case .verifiedDomainIconTapped:
            handleVerifiedDomainIconTapped()

        case .disconnectButtonTapped:
            handleDisconnectButtonTapped()
        }
    }

    private func handleVerifiedDomainIconTapped() {
        guard case .dAppDetails(let dAppDetailsViewState) = state else { return }

        let viewModel = WalletConnectDAppDomainVerificationViewModel(
            verifiedDAppName: connectedDApp.dAppData.name,
            closeAction: { [weak self] in
                self?.state = .dAppDetails(dAppDetailsViewState)
            }
        )

        state = .verifiedDomain(viewModel)
    }

    private func handleDisconnectButtonTapped() {
        guard
            case .dAppDetails(var dAppDetailsViewState) = state,
            !dAppDetailsViewState.disconnectButton.isLoading
        else {
            return
        }

        dAppDetailsViewState.disconnectButton.isLoading = true
        analyticsLogger.logDisconnectButtonTapped()
        state = .dAppDetails(dAppDetailsViewState)

        disconnectDAppTask?.cancel()
        disconnectDAppTask = Task { [disconnectDAppUseCase, analyticsLogger, logger, closeAction, onDisconnect, connectedDApp] in
            do {
                try await disconnectDAppUseCase(connectedDApp)
                analyticsLogger.logDAppDisconnected()
            } catch {
                logger.error("Failed to disconnect \(connectedDApp.dAppData.name) dApp", error: error)
            }

            closeAction()
            onDisconnect()
        }
    }
}

// MARK: - Factory methods

extension WalletConnectConnectedDAppDetailsViewModel {
    private static func makeDateFormatter() -> RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .numeric
        return formatter
    }

    private static func makeInitialState(
        for dApp: WalletConnectConnectedDApp,
        using dateFormatter: RelativeDateTimeFormatter,
        userWalletRepository: some UserWalletRepository,
        logger: TangemLogger.Logger
    ) -> WalletConnectConnectedDAppDetailsViewState {
        let imageProvider = NetworkImageProvider()
        let walletName: String

        if let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId.stringValue == dApp.userWalletID }) {
            walletName = userWalletModel.name
        } else {
            logger.warning("UserWalletModel not found for \(dApp.dAppData.name) dApp")
            walletName = ""
        }

        return WalletConnectConnectedDAppDetailsViewState.dAppDetails(
            WalletConnectConnectedDAppDetailsViewState.DAppDetails(
                navigationBar: WalletConnectConnectedDAppDetailsViewState.DAppDetails.NavigationBar(
                    connectedTime: Self.connectedTime(for: dApp, using: dateFormatter)
                ),
                dAppDescriptionSection: .content(
                    WalletConnectDAppDescriptionViewModel.ContentState(
                        dAppData: dApp.dAppData,
                        verificationStatus: dApp.verificationStatus
                    )
                ),
                walletSection: WalletConnectConnectedDAppDetailsViewState.DAppDetails.WalletSection(walletName: walletName),
                dAppVerificationWarningSection: WalletConnectWarningNotificationViewModel(dApp.verificationStatus),
                connectedNetworksSection: WalletConnectConnectedDAppDetailsViewState.DAppDetails.ConnectedNetworksSection(
                    blockchains: dApp.blockchains.map { blockchain in
                        WalletConnectConnectedDAppDetailsViewState.DAppDetails.BlockchainRowItem(
                            id: blockchain.networkId,
                            iconAsset: imageProvider.provide(by: blockchain, filled: true),
                            name: blockchain.displayName,
                            currencySymbol: blockchain.currencySymbol
                        )
                    }
                )
            )
        )
    }

    private static func connectedTime(for dApp: WalletConnectConnectedDApp, using dateFormatter: RelativeDateTimeFormatter) -> String {
        let relativeDateString = dateFormatter.localizedString(for: dApp.connectionDate, relativeTo: Date.now)
        let delimiter = " • "
        let timeString = dApp.connectionDate.formatted(.dateTime.hour().minute())

        return relativeDateString + delimiter + timeString
    }
}
