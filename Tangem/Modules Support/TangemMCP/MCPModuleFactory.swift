//
//  MCPModuleFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import struct SwiftUI.Alert
import struct SwiftUI.Text
import class UIKit.UIApplication
import class UIKit.UIImage
import class Kingfisher.ImageCache
import enum TangemBackendAuthentication.BackendAuthenticationAssembly
import TangemFoundation
import TangemLocalization
import TangemMCP
import class TangemUI.FloatingSheetRegistry
import TangemUIUtils

enum MCPModuleFactory {
    @Injected(\.floatingSheetPresenter) private static var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.alertPresenter) private static var alertPresenter: any AlertPresenter
    @Injected(\.pushNotificationsPermission) private static var pushNotificationsPermission: any PushNotificationsPermissionService
    @Injected(\.userWalletRepository) private static var userWalletRepository: any UserWalletRepository

    private static let balanceFormatter = BalanceFormatter()
    private static let blockchainImageAssetProvider = NetworkImageProvider()
    private static let tokenIconURLBuilder = IconURLBuilder()

    static let kingfisherImageCache = ImageCache(name: "com.tangem.mcp.icons")

    static func configure() {
        let configuration = MCPAssembly.Configuration(
            floatingSheetRegistry: FloatingSheetRegistry.default,
            baseURL: AppEnvironment.current.backendAuthenticationAPIType.baseURL,
            requestAdapter: BackendAuthenticationAssembly.requestAdapter,
            requestRetrier: BackendAuthenticationAssembly.requestRetrier,
            authorizationAnalyticsReporter: CommonMCPAuthorizationAnalyticsReporter(),
            sessionsAnalyticsReporter: CommonMCPSessionsAnalyticsReporter(),
            kingfisherImageCache: kingfisherImageCache,
            logger: MCPLogger
        )

        MCPAssembly.configure(configuration)
    }

    @MainActor
    static func makeConnectionRequestViewModel(
        userCode: String,
        preselectedUserWalletID: UserWalletId? = nil,
        connectionAcceptedAction: @escaping (UserWalletId) -> Void = { _ in }
    ) -> MCPConnectionRequestViewModel? {
        let userWallets = Self.userWalletRepository.models.map(MCPUserWallet.init(from:))

        guard !userWallets.isEmpty else {
            return nil
        }

        let selectedUserWalletID = preselectedUserWalletID ?? userWalletRepository.selectedModel?.userWalletId
        let selectedUserWallet = userWallets.first { $0.id == selectedUserWalletID } ?? userWallets[0]

        CommonMCPAuthorizationAnalyticsReporter().reportConnectionReceived()

        let pushNotificationsPermissionProvider = CommonMCPPushNotificationsPermissionProvider(
            service: Self.pushNotificationsPermission
        )

        return MCPAssembly.ViewModels.makeConnectionRequest(
            userCode: userCode,
            userWallets: userWallets,
            selectedUserWallet: selectedUserWallet,
            pushNotificationsPermissionProvider: pushNotificationsPermissionProvider,
            retrieveUserWalletRegistrationStatus: { userWalletID in
                await BackendAuthenticationAssembly.retrieveUserWalletRegistrationStatus(id: userWalletID)
            },
            fetchUserWalletImage: Self.makeFetchUserWalletImage(),
            updateUserWalletBalance: Self.makeUpdateUserWalletBalance(),
            openSystemSettingsAction: UIApplication.openSystemSettings,
            unregisteredUserWalletSelectedAction: { [weak alertPresenter] in
                let alert = Alert(
                    title: Text(Localization.mcpConnectionRequestWalletNeedsSyncTitle),
                    message: Text(Localization.mcpConnectionRequestWalletNeedsSyncDescription),
                    dismissButton: .default(Text(Localization.commonGotIt))
                )

                alertPresenter?.present(alert: AlertBinder(alert: alert))
            },
            connectionFailedAction: { [weak floatingSheetPresenter, weak alertPresenter] in
                floatingSheetPresenter?.removeActiveSheet()
                let alert = Alert(
                    title: Text(Localization.commonSomethingWentWrong),
                    message: Text(Localization.commonTryAgainLater)
                )

                alertPresenter?.present(alert: AlertBinder(alert: alert))
            },
            connectionAcceptedAction: connectionAcceptedAction,
            closeAction: { [weak floatingSheetPresenter] in
                floatingSheetPresenter?.removeActiveSheet()
            }
        )
    }

    @MainActor
    static func makeSessionDetailsViewModel(
        session: MCPSession,
        sessionRevokedAction: @escaping () -> Void
    ) -> MCPSessionDetailsViewModel? {
        guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId == session.userWalletID }) else {
            return nil
        }

        weak var futureViewModel: MCPSessionDetailsViewModel?

        let viewModel = MCPAssembly.ViewModels.makeSessionDetails(
            session: session,
            userWallet: MCPUserWallet(from: userWalletModel),
            closeAction: { [weak floatingSheetPresenter] in
                guard let futureViewModel else { return }
                floatingSheetPresenter?.removeSheet(withId: futureViewModel.id)
            },
            sessionRevokedAction: { [weak floatingSheetPresenter] in
                if let futureViewModel {
                    floatingSheetPresenter?.removeSheet(withId: futureViewModel.id)
                }
                sessionRevokedAction()
            },
            sessionRevokeFailedAction: { [weak alertPresenter] in
                let alert = Alert(
                    title: Text(Localization.commonSomethingWentWrong),
                    message: Text(Localization.commonTryAgainLater)
                )

                alertPresenter?.present(alert: AlertBinder(alert: alert))
            }
        )

        futureViewModel = viewModel
        return viewModel
    }

    static func makeMCPToken(from walletModel: some WalletModel) -> MCPToken {
        let tokenItem = walletModel.tokenItem
        let blockchain = tokenItem.blockchain

        let displayName: String
        let kind: MCPToken.Kind

        switch tokenItem.amountType {
        case .coin, .reserve, .feeResource:
            displayName = blockchain.coinDisplayName
            kind = .nativeCoin(iconURL: Self.tokenIconURLBuilder.tokenIconURL(id: blockchain.coinId, size: .large))

        case .token(let token):
            displayName = token.name
            if let tokenID = token.id {
                let iconURL = Self.tokenIconURLBuilder.tokenIconURL(id: tokenID, size: .large)
                kind = MCPToken.Kind.token(iconURL: iconURL)
            } else {
                kind = MCPToken.Kind.customToken
            }
        }

        return MCPToken(
            displayName: displayName,
            symbol: tokenItem.currencySymbol,
            network: MCPToken.Blockchain(iconAsset: Self.blockchainImageAssetProvider.provide(by: blockchain, filled: true)),
            kind: kind
        )
    }

    static func makeFormattedAmount(_ amount: Decimal, symbol: String) -> String {
        balanceFormatter.formatCryptoBalance(amount, currencyCode: symbol)
    }
}

// MARK: - Swap intent

extension MCPModuleFactory {
    @MainActor
    static func makeSwapIntentViewModel(
        initialLoadingResult: MCPIntentLoadingResult<MCPSwapIntentProposalState>,
        sheetAppearedAction: @escaping () -> Void,
        retryAction: @escaping () async -> MCPIntentLoadingResult<MCPSwapIntentProposalState>
    ) -> MCPSwapIntentViewModel {
        weak var futureViewModel: MCPSwapIntentViewModel?

        let viewModel = MCPAssembly.ViewModels.makeSwapIntent(
            initialLoadingResult: initialLoadingResult,
            sheetAppearedAction: sheetAppearedAction,
            closeAction: { [weak floatingSheetPresenter] in
                guard let futureViewModel else { return }
                floatingSheetPresenter?.removeSheet(withId: futureViewModel.id)
            },
            retryAction: retryAction
        )

        futureViewModel = viewModel
        return viewModel
    }

    @MainActor
    static func makeSwapIntentProposal(
        state: MCPSwapIntentProposalState,
        proceedAction: @escaping () -> Void
    ) -> MCPIntentLoadingResult<MCPSwapIntentProposalState> {
        MCPIntentLoadingResult.proposal(
            state,
            proceedAction: { [weak floatingSheetPresenter] in
                floatingSheetPresenter?.removeActiveSheet()
                proceedAction()
            }
        )
    }
}

// MARK: - Send intent

extension MCPModuleFactory {
    @MainActor
    static func makeSendIntentViewModel(
        initialLoadingResult: MCPIntentLoadingResult<MCPSendIntentProposalState>,
        sheetAppearedAction: @escaping () -> Void,
        closeAction: @escaping () -> Void,
        retryAction: @escaping () async -> MCPIntentLoadingResult<MCPSendIntentProposalState>
    ) -> MCPSendIntentViewModel {
        weak var futureViewModel: MCPSendIntentViewModel?

        let viewModel = MCPAssembly.ViewModels.makeSendIntent(
            initialLoadingResult: initialLoadingResult,
            sheetAppearedAction: sheetAppearedAction,
            closeAction: { [weak floatingSheetPresenter] in
                if let futureViewModel {
                    floatingSheetPresenter?.removeSheet(withId: futureViewModel.id)
                }
                closeAction()
            },
            retryAction: retryAction
        )

        futureViewModel = viewModel
        return viewModel
    }

    @MainActor
    static func makeSendIntentProposal(
        agent: MCPAgent,
        amount: Decimal,
        walletModel: some WalletModel,
        proceedAction: @escaping () -> Void
    ) -> MCPIntentLoadingResult<MCPSendIntentProposalState> {
        let state = MCPSendIntentProposalState(
            agent: agent,
            amount: makeFormattedSendAmount(amount, tokenItem: walletModel.tokenItem),
            token: makeMCPToken(from: walletModel)
        )

        return MCPIntentLoadingResult.proposal(
            state,
            proceedAction: { [weak floatingSheetPresenter] in
                floatingSheetPresenter?.removeActiveSheet()
                proceedAction()
            }
        )
    }

    static func makeFormattedSendAmount(_ amount: Decimal, tokenItem: TokenItem) -> String {
        SendCryptoValueFormatter(decimals: tokenItem.decimalCount, currencySymbol: tokenItem.currencySymbol, trimFractions: false)
            .string(from: amount)
    }
}

// MARK: - Utility methods

extension MCPModuleFactory {
    private static func makeFetchUserWalletImage() -> @Sendable (UserWalletId) async -> UIImage {
        return { userWalletID in
            guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId == userWalletID }) else {
                assertionFailure("UserWalletModel was not found by a provided UserWalletId. Developer mistake.")
                return UIImage()
            }

            switch userWalletModel.walletIcon {
            case .loadable(let imageProvider):
                return await imageProvider.loadSmallUIImage()
            case .content:
                return UIImage()
            }
        }
    }

    private static func makeUpdateUserWalletBalance() -> @Sendable (UserWalletId) -> AsyncStream<String> {
        return { userWalletID in
            guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId == userWalletID }) else {
                assertionFailure("UserWalletModel was not found by a provided UserWalletId. Developer mistake.")
                return Self.wrap(publisher: Just<String>(""))
            }

            let publisher = userWalletModel
                .totalBalancePublisher
                .withAppCurrencyCode()
                .compactMap { state, currencyCode in
                    switch state {
                    case .empty:
                        return "–"

                    case .loading(let cached):
                        return cached.map { Self.balanceFormatter.formatFiatBalance($0, currencyCode: currencyCode) }

                    case .failed(let cached, _):
                        guard let cached else { return Localization.commonUnreachable }
                        return Self.balanceFormatter.formatFiatBalance(cached, currencyCode: currencyCode)

                    case .loaded(let balance):
                        return Self.balanceFormatter.formatFiatBalance(balance, currencyCode: currencyCode)
                    }
                }

            return Self.wrap(publisher: publisher)
        }
    }

    private static func wrap<Success>(publisher: some Publisher<Success, Never>) -> AsyncStream<Success> {
        AsyncStream { continuation in
            let task = Task {
                for try await value in publisher.values {
                    continuation.yield(value)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

private extension MCPUserWallet {
    init(from userWalletModel: any UserWalletModel) {
        self.init(
            id: userWalletModel.userWalletId,
            thumbnail: userWalletModel.config.walletThumbnailType,
            name: userWalletModel.name,
            isMobileWallet: userWalletModel.config.productType == .mobileWallet,
            isLocked: userWalletModel.isUserWalletLocked
        )
    }
}
