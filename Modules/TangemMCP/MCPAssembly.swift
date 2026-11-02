//
//  MCPAssembly.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Foundation
private import os.lock
public import class UIKit.UIImage
public import Alamofire
private import class Kingfisher.ImageCache
private import class Moya.MoyaProvider
public import TangemUI
public import struct TangemFoundation.UserWalletId
private import TangemNetworkUtils
public import struct TangemLogger.Logger

public enum MCPAssembly {}

// MARK: - Use cases

public extension MCPAssembly {
    enum UseCases {
        public static var fetchAgent: FetchMCPAgentUseCase {
            FetchMCPAgentUseCase(client: Infrastructure.agentClient, logger: MCPAssembly.configuration.logger)
        }

        fileprivate static var fetchConnectionRequest: FetchMCPConnectionRequestUseCase {
            FetchMCPConnectionRequestUseCase(client: Infrastructure.connectionClient)
        }

        fileprivate static var rejectConnection: RejectMCPConnectionUseCase {
            RejectMCPConnectionUseCase(client: Infrastructure.connectionClient)
        }

        fileprivate static var acceptConnection: AcceptMCPConnectionUseCase {
            AcceptMCPConnectionUseCase(client: Infrastructure.connectionClient)
        }
    }
}

// MARK: - View models

public extension MCPAssembly {
    @MainActor
    enum ViewModels {
        public static func makeConnectionRequest(
            userCode: String,
            userWallets: [MCPUserWallet],
            selectedUserWallet: MCPUserWallet,
            pushNotificationsPermissionProvider: any MCPPushNotificationsPermissionProvider,
            fetchUserWalletImage: @escaping @Sendable (UserWalletId) async -> UIImage,
            updateUserWalletBalance: @escaping @Sendable (UserWalletId) -> AsyncStream<String>,
            openSystemSettingsAction: @escaping () -> Void,
            closeAction: @escaping () -> Void
        ) -> MCPConnectionRequestViewModel {
            let interactor = MCPConnectionRequestInteractor(
                fetchRequest: UseCases.fetchConnectionRequest,
                ensurePushNotificationsAuthorized: EnsurePushNotificationsAuthorizedUseCase(
                    provider: pushNotificationsPermissionProvider
                ),
                reject: UseCases.rejectConnection,
                accept: UseCases.acceptConnection
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
                logger: MCPAssembly.configuration.logger
            )
        }

        public static func makeSwapIntent(
            agent: MCPAgent,
            fromAmount: MCPSwapAmount,
            toToken: MCPToken,
            closeAction: @escaping () -> Void,
            proceedAction: @escaping () -> Void
        ) -> MCPSwapIntentViewModel {
            MCPSwapIntentViewModel(
                closeAction: closeAction,
                primaryAction: proceedAction,
                state: MCPSwapIntentState(agent: agent, fromAmount: fromAmount, toToken: toToken)
            )
        }

        public static func makeSwapIntent(
            agent: MCPAgent,
            fromToken: MCPToken,
            toAmount: MCPSwapAmount,
            closeAction: @escaping () -> Void,
            proceedAction: @escaping () -> Void
        ) -> MCPSwapIntentViewModel {
            MCPSwapIntentViewModel(
                closeAction: closeAction,
                primaryAction: proceedAction,
                state: MCPSwapIntentState(agent: agent, fromToken: fromToken, toAmount: toAmount)
            )
        }

        public static func makeSendIntent(
            id: String,
            agent: MCPAgent,
            amount: String,
            token: MCPToken,
            closeAction: @escaping () -> Void,
            proceedAction: @escaping () -> Void
        ) -> MCPSendIntentViewModel {
            MCPSendIntentViewModel(
                id: id,
                closeAction: closeAction,
                primaryAction: proceedAction,
                state: MCPSendIntentState(agent: agent, amount: amount, token: token)
            )
        }

        public static func makeIntentStatus(
            id: String,
            status: MCPIntentStatus,
            closeAction: @escaping () -> Void,
            primaryAction: @escaping () -> Void
        ) -> MCPIntentStatusViewModel {
            MCPIntentStatusViewModel(
                id: id,
                closeAction: closeAction,
                primaryAction: primaryAction,
                state: MCPIntentStatusState(status: status)
            )
        }
    }
}

// MARK: - Configuration

extension MCPAssembly {
    public struct Configuration: Sendable {
        let floatingSheetRegistry: FloatingSheetRegistry
        let baseURL: URL
        let requestAdapter: any Alamofire.RequestAdapter
        let requestRetrier: any Alamofire.RequestRetrier
        let logger: TangemLogger.Logger

        public init(
            floatingSheetRegistry: FloatingSheetRegistry,
            baseURL: URL,
            requestAdapter: some Alamofire.RequestAdapter,
            requestRetrier: some Alamofire.RequestRetrier,
            logger: TangemLogger.Logger
        ) {
            self.floatingSheetRegistry = floatingSheetRegistry
            self.baseURL = baseURL
            self.requestAdapter = requestAdapter
            self.requestRetrier = requestRetrier
            self.logger = logger
        }
    }

    public static func configure(_ configuration: Configuration) {
        configurationLock.withLock {
            precondition($0 == nil, "MCPAssembly.configure(_:) must be called exactly once.")
            $0 = configuration
        }

        Task { @MainActor in
            registerFloatingSheets()
        }
    }

    private static let configurationLock = OSAllocatedUnfairLock(initialState: MCPAssembly.Configuration?.none)

    fileprivate static var configuration: MCPAssembly.Configuration {
        guard let configuration = configurationLock.withLock(\.self) else {
            preconditionFailure("MCPAssembly.configure(_:) must be called before use.")
        }
        return configuration
    }

    @MainActor
    private static func registerFloatingSheets() {
        let registry = configuration.floatingSheetRegistry

        registry.register(MCPConnectionRequestViewModel.self) { viewModel in
            MCPConnectionRequestView(viewModel: viewModel, imageCache: Infrastructure.kingfisherImageCache)
        }

        registry.register(MCPSwapIntentViewModel.self) { viewModel in
            MCPSwapIntentView(viewModel: viewModel, kingfisherImageCache: Infrastructure.kingfisherImageCache)
        }

        registry.register(MCPSendIntentViewModel.self) { viewModel in
            MCPSendIntentView(viewModel: viewModel, kingfisherImageCache: Infrastructure.kingfisherImageCache)
        }

        registry.register(MCPIntentStatusViewModel.self) { viewModel in
            MCPIntentStatusView(viewModel: viewModel)
        }
    }
}

// MARK: - Infrastructure

extension MCPAssembly {
    private enum Infrastructure {
        private static let jsonEncoder = JSONEncoder()

        private static let jsonDecoder: JSONDecoder = {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .customISO8601
            return decoder
        }()

        private static let requestInterceptor = Alamofire.Interceptor(
            adapter: MCPAssembly.configuration.requestAdapter,
            retrier: MCPAssembly.configuration.requestRetrier
        )

        static let connectionClient = MoyaMCPConnectionClient(
            provider: TangemProvider<MCPDeviceVerificationTarget>(
                configuration: TangemProviderConfiguration.ephemeralConfiguration,
                requestInterceptor: Self.requestInterceptor
            ),
            baseURL: MCPAssembly.configuration.baseURL,
            encoder: Self.jsonEncoder,
            decoder: Self.jsonDecoder
        )

        static let agentClient = MoyaMCPAgentClient(
            provider: TangemProvider<MCPClientTarget>(
                configuration: TangemProviderConfiguration.ephemeralConfiguration,
                additionalPlugins: [TimeoutIntervalPlugin()],
                requestInterceptor: Self.requestInterceptor
            ),
            baseURL: MCPAssembly.configuration.baseURL,
            decoder: Self.jsonDecoder
        )

        static let sessionClient = MoyaMCPSessionClient(
            provider: TangemProvider<MCPSessionsTarget>(
                configuration: TangemProviderConfiguration.ephemeralConfiguration,
                requestInterceptor: Self.requestInterceptor
            ),
            baseURL: MCPAssembly.configuration.baseURL,
            decoder: Self.jsonDecoder
        )

        static let kingfisherImageCache = ImageCache(name: "com.tangem.mcp.icons")
    }
}

// MARK: - Error toasts

// [REDACTED_TODO_COMMENT]
// [REDACTED_TODO_COMMENT]

extension MCPAssembly.ViewModels {
    private static func presentToast(for fetchRequestError: MCPConnectionClientError) {
        let errorMessage = "MCP connection proposal fetch failed"
        let toast = Toast(view: WarningToast(text: errorMessage))

        Self.present(toast: toast)
    }

    private static func handleProposalRejectError(_ error: MCPConnectionClientError) {
        let errorMessage = "MCP connection decline failed"
        let toast = Toast(view: WarningToast(text: errorMessage))

        Self.present(toast: toast)
    }

    private static func handleProposalAcceptError(_ error: MCPConnectionClientError) {
        let errorMessage = "MCP connection failed"
        let toast = Toast(view: WarningToast(text: errorMessage))

        Self.present(toast: toast)
    }

    private static func present(toast: some Toast<WarningToast>) {
        toast.present(layout: .top(padding: 20), type: .temporary())
    }
}
