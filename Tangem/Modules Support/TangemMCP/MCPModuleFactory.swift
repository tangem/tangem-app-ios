//
//  MCPModuleFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import class UIKit.UIApplication
import class UIKit.UIImage
import class Alamofire.Interceptor
import TangemBackendAuthentication
import TangemFoundation
import TangemLocalization
import TangemMCP
import class TangemNetworkUtils.TangemProvider
import TangemUI

enum MCPModuleFactory {
    @Injected(\.userWalletRepository) static var userWalletRepository: any UserWalletRepository

    static func configure() {
        guard FeatureProvider.isAvailable(.mcp) else { return }

        let configuration = TangemMCPAssembly.Configuration(
            floatingSheetRegistry: FloatingSheetRegistry.default,
            baseURL: AppEnvironment.current.backendAuthenticationBaseUrl,
            provider: TangemProvider<MCPConnectionTarget>(
                configuration: .ephemeralConfiguration,
                requestInterceptor: Alamofire.Interceptor(
                    adapter: BackendAuthenticationAssembly.requestAdapter,
                    retrier: BackendAuthenticationAssembly.requestRetrier
                )
            ),
            logger: MCPLogger
        )

        TangemMCPAssembly.configure(configuration)
    }

    @MainActor
    static func makeConnectionRequestViewModel(userCode: String) -> MCPConnectionRequestViewModel? {
        guard FeatureProvider.isAvailable(.mcp) else {
            return nil
        }

        @Injected(\.floatingSheetPresenter) var floatingSheetPresenter: any FloatingSheetPresenter
        @Injected(\.pushNotificationsPermission) var pushNotificationsPermissionService: any PushNotificationsPermissionService

        let userWallets = Self.userWalletRepository.models.map(MCPUserWallet.init(from:))

        guard !userWallets.isEmpty else {
            return nil
        }

        let selectedUserWalletID = userWalletRepository.selectedModel?.userWalletId
        let selectedUserWallet = userWallets.first { $0.id == selectedUserWalletID } ?? userWallets[0]

        let pushNotificationsPermissionProvider = CommonMCPPushNotificationsPermissionProvider(
            service: pushNotificationsPermissionService
        )

        return TangemMCPAssembly.makeConnectionRequestViewModel(
            userCode: userCode,
            userWallets: userWallets,
            selectedUserWallet: selectedUserWallet,
            pushNotificationsPermissionProvider: pushNotificationsPermissionProvider,
            fetchUserWalletImage: Self.makeFetchUserWalletImage(),
            updateUserWalletBalance: Self.makeUpdateUserWalletBalance(),
            openSystemSettingsAction: UIApplication.openSystemSettings,
            closeAction: floatingSheetPresenter.removeActiveSheet
        )
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
            let formatter = BalanceFormatter()

            guard let userWalletModel = Self.userWalletRepository.models.first(where: { $0.userWalletId == userWalletID }) else {
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
                        return cached.map { formatter.formatFiatBalance($0, currencyCode: currencyCode) }

                    case .failed(let cached, _):
                        guard let cached else { return Localization.commonUnreachable }
                        return formatter.formatFiatBalance(cached, currencyCode: currencyCode)

                    case .loaded(let balance):
                        return formatter.formatFiatBalance(balance, currencyCode: currencyCode)
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
