//
//  MCPModuleFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import class UIKit.UIApplication
import class UIKit.UIImage
import class Alamofire.Interceptor
import enum TangemBackendAuthentication.BackendAuthenticationAssembly
import TangemFoundation
import TangemLocalization
import TangemMCP
import struct TangemNetworkUtils.TimeoutIntervalPlugin
import class TangemNetworkUtils.TangemProvider
import class TangemUI.FloatingSheetRegistry
import TangemUIUtils

enum MCPModuleFactory {
    @Injected(\.floatingSheetPresenter) private static var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.pushNotificationsPermission) private static var pushNotificationsPermission: any PushNotificationsPermissionService
    @Injected(\.userWalletRepository) private static var userWalletRepository: any UserWalletRepository

    private static let balanceFormatter = BalanceFormatter()
    private static let blockchainImageAssetProvider = NetworkImageProvider()
    private static let tokenIconURLBuilder = IconURLBuilder()

    static func configure() {
        guard FeatureProvider.isAvailable(.mcp) else { return }

        let connectionProvider = TangemProvider<MCPConnectionTarget>(
            configuration: .ephemeralConfiguration,
            requestInterceptor: Alamofire.Interceptor(
                adapter: BackendAuthenticationAssembly.requestAdapter,
                retrier: BackendAuthenticationAssembly.requestRetrier
            )
        )

        let agentProvider = TangemProvider<MCPAgentTarget>(
            configuration: .ephemeralConfiguration,
            additionalPlugins: [TimeoutIntervalPlugin()],
            requestInterceptor: Alamofire.Interceptor(
                adapter: BackendAuthenticationAssembly.requestAdapter,
                retrier: BackendAuthenticationAssembly.requestRetrier
            )
        )

        let configuration = MCPAssembly.Configuration(
            floatingSheetRegistry: FloatingSheetRegistry.default,
            baseURL: AppEnvironment.current.backendAuthenticationBaseUrl,
            connectionProvider: connectionProvider,
            agentProvider: agentProvider,
            logger: MCPLogger
        )

        MCPAssembly.configure(configuration)
    }

    @MainActor
    static func makeConnectionRequestViewModel(userCode: String) -> MCPConnectionRequestViewModel? {
        guard FeatureProvider.isAvailable(.mcp) else {
            return nil
        }

        let userWallets = Self.userWalletRepository.models.map(MCPUserWallet.init(from:))

        guard !userWallets.isEmpty else {
            return nil
        }

        let selectedUserWalletID = userWalletRepository.selectedModel?.userWalletId
        let selectedUserWallet = userWallets.first { $0.id == selectedUserWalletID } ?? userWallets[0]

        let pushNotificationsPermissionProvider = CommonMCPPushNotificationsPermissionProvider(
            service: Self.pushNotificationsPermission
        )

        return MCPAssembly.makeConnectionRequestViewModel(
            userCode: userCode,
            userWallets: userWallets,
            selectedUserWallet: selectedUserWallet,
            pushNotificationsPermissionProvider: pushNotificationsPermissionProvider,
            fetchUserWalletImage: Self.makeFetchUserWalletImage(),
            updateUserWalletBalance: Self.makeUpdateUserWalletBalance(),
            openSystemSettingsAction: UIApplication.openSystemSettings,
            closeAction: { [weak floatingSheetPresenter] in
                floatingSheetPresenter?.removeActiveSheet()
            }
        )
    }

    @MainActor
    static func makeSwapIntentViewModel(
        agent: MCPAgent,
        fromAmount: MCPSwapAmount,
        toToken: MCPToken,
        proceedAction: @escaping () -> Void
    ) -> MCPSwapIntentViewModel {
        MCPAssembly.makeSwapIntentViewModel(
            agent: agent,
            fromAmount: fromAmount,
            toToken: toToken,
            closeAction: { [weak floatingSheetPresenter] in
                floatingSheetPresenter?.removeActiveSheet()
            },
            proceedAction: { [weak floatingSheetPresenter] in
                floatingSheetPresenter?.removeActiveSheet()
                proceedAction()
            }
        )
    }

    @MainActor
    static func makeSwapIntentViewModel(
        agent: MCPAgent,
        fromToken: MCPToken,
        toAmount: MCPSwapAmount,
        proceedAction: @escaping () -> Void
    ) -> MCPSwapIntentViewModel {
        MCPAssembly.makeSwapIntentViewModel(
            agent: agent,
            fromToken: fromToken,
            toAmount: toAmount,
            closeAction: { [weak floatingSheetPresenter] in
                floatingSheetPresenter?.removeActiveSheet()
            },
            proceedAction: { [weak floatingSheetPresenter] in
                floatingSheetPresenter?.removeActiveSheet()
                proceedAction()
            }
        )
    }

    static func makeMCPToken(from walletModel: some WalletModel) -> MCPToken {
        let tokenItem = walletModel.tokenItem
        let blockchain = tokenItem.blockchain

        let displayName: String
        let kind: MCPToken.Kind

        switch tokenItem.amountType {
        case .coin, .reserve, .feeResource:
            displayName = blockchain.coinDisplayName
            kind = .nativeCoin

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

// MARK: - Utility methods

extension MCPModuleFactory {
    private static func makeFetchUserWalletImage() -> @Sendable (UserWalletId) async -> UIImage {
        return { userWalletID in
            guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId == userWalletID }) else {
                assertionFailure("UserWalletModel was not found by a provided UserWalletId. Developer mistake.")
                return UIImage()
            }

            return await userWalletModel.walletImageProvider.loadSmallUIImage()
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
            numberOfCards: userWalletModel.config.cardsCount,
            isLocked: userWalletModel.isUserWalletLocked
        )
    }
}
