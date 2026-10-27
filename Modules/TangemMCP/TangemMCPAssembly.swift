//
//  TangemMCPAssembly.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Foundation
private import os.lock
public import class UIKit.UIImage
private import class Kingfisher.ImageCache
public import class Moya.MoyaProvider
public import TangemUI
public import struct TangemFoundation.UserWalletId
public import struct TangemLogger.Logger

public enum TangemMCPAssembly {
    @MainActor
    public static func makeConnectionRequestViewModel(
        userCode: String,
        userWallets: [MCPUserWallet],
        selectedUserWallet: MCPUserWallet,
        pushNotificationsPermissionProvider: any MCPPushNotificationsPermissionProvider,
        fetchUserWalletImage: @escaping @Sendable (UserWalletId) async -> UIImage,
        updateUserWalletBalance: @escaping @Sendable (UserWalletId) -> AsyncStream<String>,
        openSystemSettingsAction: @escaping () -> Void,
        closeAction: @escaping () -> Void
    ) -> MCPConnectionRequestViewModel {
        let client = MoyaMCPConnectionClient(
            provider: Self.configuration.provider,
            baseURL: Self.configuration.baseURL,
            encoder: JSONEncoder(),
            decoder: JSONDecoder()
        )

        let interactor = MCPConnectionRequestInteractor(
            fetchRequest: FetchMCPConnectionRequestUseCase(client: client),
            ensurePushNotificationsAuthorized: EnsurePushNotificationsAuthorizedUseCase(
                provider: pushNotificationsPermissionProvider
            ),
            reject: RejectMCPConnectionUseCase(client: client),
            accept: AcceptMCPConnectionUseCase(client: client)
        )

        let userWalletImageRepository = MCPUserWalletImageRepository(maxConcurrentFetches: 6, fetchImage: fetchUserWalletImage)

        let delegate = MCPConnectionRequestViewModel.Delegate(
            closeButtonTapped: closeAction,
            openSystemSettingsButtonTapped: openSystemSettingsAction,
            fetchRequestErrorOccurred: { fetchRequestError in
                Self.presentToast(for: fetchRequestError)
                closeAction()
            },
            proposalRejected: { rejectResult in
                switch rejectResult {
                case .success:
                    break
                case .failure(let error):
                    Self.handleProposalRejectError(error)
                }

                closeAction()
            },
            proposalAcceptErrorOccurred: Self.handleProposalAcceptError
        )

        return MCPConnectionRequestViewModel(
            userWallets: userWallets,
            userWalletImageRepository: userWalletImageRepository,
            userWalletBalanceUpdater: updateUserWalletBalance,
            selectedUserWallet: selectedUserWallet,
            userCode: userCode,
            interactor: interactor,
            delegate: delegate,
            logger: Self.configuration.logger
        )
    }
}

// MARK: - Error toasts

// [REDACTED_TODO_COMMENT]

extension TangemMCPAssembly {
    @MainActor
    private static func presentToast(for fetchRequestError: MCPConnectionClientError) {
        let errorMessage = "MCP connection proposal fetch failed"
        let toast = Toast(view: WarningToast(text: errorMessage))

        Self.present(toast: toast)
    }

    @MainActor
    private static func handleProposalRejectError(_ error: MCPConnectionClientError) {
        let errorMessage = "MCP connection decline failed"
        let toast = Toast(view: WarningToast(text: errorMessage))

        Self.present(toast: toast)
    }

    @MainActor
    private static func handleProposalAcceptError(_ error: MCPConnectionClientError) {
        let errorMessage = "MCP connection failed"
        let toast = Toast(view: WarningToast(text: errorMessage))

        Self.present(toast: toast)
    }

    @MainActor
    private static func present(toast: some Toast<WarningToast>) {
        toast.present(layout: .top(padding: 20), type: .temporary())
    }
}

// MARK: - Configuration

extension TangemMCPAssembly {
    public struct Configuration: Sendable {
        let floatingSheetRegistry: FloatingSheetRegistry
        let baseURL: URL
        let provider: MoyaProvider<MCPConnectionTarget>
        let logger: TangemLogger.Logger

        public init(
            floatingSheetRegistry: FloatingSheetRegistry,
            baseURL: URL,
            provider: MoyaProvider<MCPConnectionTarget>,
            logger: TangemLogger.Logger
        ) {
            self.floatingSheetRegistry = floatingSheetRegistry
            self.baseURL = baseURL
            self.provider = provider
            self.logger = logger
        }
    }

    private static let configurationLock = OSAllocatedUnfairLock(initialState: Configuration?.none)

    fileprivate static var configuration: Configuration {
        guard let configuration = configurationLock.withLock(\.self) else {
            preconditionFailure("TangemMCPAssembly.configure(_:) must be called before use.")
        }
        return configuration
    }

    public static func configure(_ configuration: Configuration) {
        configurationLock.withLock {
            precondition($0 == nil, "TangemMCPAssembly.configure(_:) must be called exactly once.")
            $0 = configuration
        }

        Task { @MainActor in
            registerFloatingSheets()
        }
    }

    @MainActor
    private static func registerFloatingSheets() {
        let registry = configuration.floatingSheetRegistry

        registry.register(MCPConnectionRequestViewModel.self) { viewModel in
            MCPConnectionRequestView(viewModel: viewModel, imageCache: kingfisherImageCache)
        }
    }
}

extension TangemMCPAssembly {
    private static let kingfisherImageCache = ImageCache(name: "com.tangem.mcp.icons")
}
