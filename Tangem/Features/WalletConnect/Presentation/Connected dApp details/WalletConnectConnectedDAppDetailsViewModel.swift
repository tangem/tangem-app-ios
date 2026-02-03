//
//  WalletConnectConnectedDAppDetailsViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemAssets
import TangemLogger
import TangemUI

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

        var verifiedDomainForwarder: (() -> Void)?

        state = Self.makeInitialState(
            for: connectedDApp,
            using: dateFormatter,
            userWalletRepository: userWalletRepository,
            logger: logger,
            verifiedDomainAction: {
                verifiedDomainForwarder?()
            }
        )

        verifiedDomainForwarder = { [weak self] in
            self?.handle(viewEvent: .verifiedDomainIconTapped)
        }

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
        logger: TangemLogger.Logger,
        verifiedDomainAction: @escaping () -> Void
    ) -> WalletConnectConnectedDAppDetailsViewState {
        let imageProvider = NetworkImageProvider()
        var walletSection: WalletConnectConnectedDAppDetailsViewState.DAppDetails.WalletSection?
        var connectionTargetSection: WalletConnectConnectedDAppDetailsViewState.DAppDetails.ConnectionTargetSection?
        var walletName = ""

        switch dApp {
        case .v1(let dAppV1):
            let userWalletID = dAppV1.userWalletID
            if let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId.stringValue == userWalletID }) {
                walletName = userWalletModel.name
            } else {
                logger.warning("UserWalletModel not found for \(dApp.dAppData.name) dApp")
            }
        case .v2(let dAppV2):
            outer: for userWalletModel in userWalletRepository.models where userWalletModel.userWalletId.stringValue == dAppV2.userWalletID {
                for accountModel in userWalletModel.accountModelsManager.accountModels {
                    switch accountModel {
                    case .standard(.single(let cryptoAccount)):
                        if cryptoAccount.id.walletConnectIdentifierString == dAppV2.accountId {
                            connectionTargetSection = .init(
                                targetName: walletName,
                                target: .wallet()
                            )
                            walletSection = nil
                            break outer
                        }

                    case .standard(.multiple(let cryptoAccounts)):
                        if let cryptoAccount = cryptoAccounts.first(where: { $0.id.walletConnectIdentifierString == dAppV2.accountId }) {
                            connectionTargetSection = .init(
                                targetName: cryptoAccount.name,
                                target: .account(.init(icon: cryptoAccount.icon))
                            )
                            walletSection = nil
                            break outer
                        }
                    }
                }
            }

            if connectionTargetSection == nil {
                walletSection = .init(walletName: walletName)
                logger.warning("CryptoAccountModel not found for \(dApp.dAppData.name) dApp")
            }
        }

        let verificationStatusIconConfig = EntitySummaryView.ViewState.TitleInfoConfig(
            imageType: Assets.Glyphs.verified,
            foregroundColor: Colors.Icon.accent,
            onTap: verifiedDomainAction
        )

        return WalletConnectConnectedDAppDetailsViewState.dAppDetails(
            WalletConnectConnectedDAppDetailsViewState.DAppDetails(
                navigationBar: WalletConnectConnectedDAppDetailsViewState.DAppDetails.NavigationBar(
                    connectedTime: Self.connectedTime(for: dApp, using: dateFormatter)
                ),
                dAppDescriptionSection: .content(
                    EntitySummaryView.ViewState.ContentState(
                        imageLocation: .remote(
                            EntitySummaryView.ViewState.ContentState.ImageLocation.RemoteImageConfig(iconURL: dApp.dAppData.icon)
                        ),
                        title: dApp.dAppData.name,
                        subtitle: dApp.dAppData.domain.host ?? "",
                        titleInfoConfig: dApp.verificationStatus.isVerified
                            ? verificationStatusIconConfig
                            : nil
                    )
                ),
                walletSection: walletSection,
                connectionTargetSection: connectionTargetSection,
                dAppVerificationWarningSection: WalletConnectWarningNotificationViewModel(dApp.verificationStatus),
                connectedNetworksSection: WalletConnectConnectedDAppDetailsViewState.DAppDetails.ConnectedNetworksSection(
                    blockchains: dApp.dAppBlockchains.map { dAppBlockchain in
                        WalletConnectConnectedDAppDetailsViewState.DAppDetails.BlockchainRowItem(
                            id: dAppBlockchain.blockchain.networkId,
                            iconAsset: imageProvider.provide(by: dAppBlockchain.blockchain, filled: true),
                            name: dAppBlockchain.blockchain.displayName,
                            currencySymbol: dAppBlockchain.blockchain.currencySymbol
                        )
                    }
                )
            )
        )
    }

    private static func connectedTime(for dApp: WalletConnectConnectedDApp, using dateFormatter: RelativeDateTimeFormatter) -> String {
        dateFormatter.localizedString(for: dApp.connectionDate, relativeTo: Date.now)
    }
}
