//
//  MCPAssembly.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Foundation
private import os.lock
private import SwiftUI
public import class UIKit.UIImage
public import Alamofire
public import class Kingfisher.ImageCache
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

        public static var fetchSessions: FetchMCPSessionsUseCase {
            FetchMCPSessionsUseCase(client: Infrastructure.sessionClient)
        }

        public static var revokeDeviceSessions: RevokeDeviceMCPSessionsUseCase {
            RevokeDeviceMCPSessionsUseCase(client: Infrastructure.sessionClient)
        }

        public static var revokeUserWalletSessions: RevokeUserWalletMCPSessionsUseCase {
            RevokeUserWalletMCPSessionsUseCase(client: Infrastructure.sessionClient)
        }

        fileprivate static var revokeSession: RevokeMCPSessionUseCase {
            RevokeMCPSessionUseCase(client: Infrastructure.sessionClient, logger: MCPAssembly.configuration.logger)
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
            retrieveUserWalletRegistrationStatus: @escaping RetrieveUserWalletRegistrationStatus,
            fetchUserWalletImage: @escaping @Sendable (UserWalletId) async -> UIImage,
            updateUserWalletBalance: @escaping @Sendable (UserWalletId) -> AsyncStream<String>,
            openSystemSettingsAction: @escaping () -> Void,
            unregisteredUserWalletSelectedAction: @escaping () -> Void,
            connectionFailedAction: @escaping () -> Void,
            connectionAcceptedAction: @escaping (UserWalletId) -> Void,
            closeAction: @escaping () -> Void
        ) -> MCPConnectionRequestViewModel {
            let ensurePushNotificationsAuthorized = EnsurePushNotificationsAuthorizedUseCase(
                provider: pushNotificationsPermissionProvider
            ).callAsFunction

            let interactor = MCPConnectionRequestInteractor(
                fetchRequest: UseCases.fetchConnectionRequest.callAsFunction,
                ensurePushNotificationsAuthorized: ensurePushNotificationsAuthorized,
                retrieveUserWalletRegistrationStatus: retrieveUserWalletRegistrationStatus,
                reject: UseCases.rejectConnection.callAsFunction,
                accept: UseCases.acceptConnection.callAsFunction
            )

            let userWalletImageRepository = MCPUserWalletImageRepository(maxConcurrentFetches: 6, fetchImage: fetchUserWalletImage)

            let delegate = MCPConnectionRequestViewModel.Delegate(
                closeButtonTapped: closeAction,
                openSystemSettingsButtonTapped: openSystemSettingsAction,
                unregisteredUserWalletSelected: unregisteredUserWalletSelectedAction,
                fetchRequestErrorOccurred: { _ in
                    connectionFailedAction()
                },
                proposalRejected: { _ in
                    closeAction()
                },
                proposalAccepted: connectionAcceptedAction,
                proposalAcceptErrorOccurred: { _ in
                    connectionFailedAction()
                }
            )

            return MCPConnectionRequestViewModel(
                userWallets: userWallets,
                userWalletImageRepository: userWalletImageRepository,
                userWalletBalanceUpdater: updateUserWalletBalance,
                selectedUserWallet: selectedUserWallet,
                userCode: userCode,
                interactor: interactor,
                delegate: delegate,
                analyticsReporter: MCPAssembly.configuration.authorizationAnalyticsReporter,
                logger: MCPAssembly.configuration.logger
            )
        }

        public static func makeSwapIntent(
            initialLoadingResult: MCPIntentLoadingResult<MCPSwapIntentProposalState>,
            sheetAppearedAction: @escaping () -> Void,
            closeAction: @escaping () -> Void,
            retryAction: @escaping () async -> MCPIntentLoadingResult<MCPSwapIntentProposalState>
        ) -> MCPSwapIntentViewModel {
            MCPSwapIntentViewModel(
                initialLoadingResult: initialLoadingResult,
                delegate: MCPSwapIntentViewModel.Delegate(
                    sheetAppeared: sheetAppearedAction,
                    flowTerminated: closeAction,
                    issueRetryButtonTapped: retryAction
                )
            )
        }

        public static func makeSendIntent(
            initialLoadingResult: MCPIntentLoadingResult<MCPSendIntentProposalState>,
            sheetAppearedAction: @escaping () -> Void,
            closeAction: @escaping () -> Void,
            retryAction: @escaping () async -> MCPIntentLoadingResult<MCPSendIntentProposalState>
        ) -> MCPSendIntentViewModel {
            MCPSendIntentViewModel(
                initialLoadingResult: initialLoadingResult,
                delegate: MCPSendIntentViewModel.Delegate(
                    sheetAppeared: sheetAppearedAction,
                    flowTerminated: closeAction,
                    issueRetryButtonTapped: retryAction
                )
            )
        }

        public static func makeSessionDetails(
            session: MCPSession,
            userWallet: MCPUserWallet,
            closeAction: @escaping () -> Void,
            sessionRevokedAction: @escaping () -> Void,
            sessionRevokeFailedAction: @escaping () -> Void
        ) -> MCPSessionDetailsViewModel {
            let delegate = MCPSessionDetailsViewModel.Delegate(
                closeButtonTapped: closeAction,
                sessionRevoked: sessionRevokedAction,
                sessionRevokeFailed: { _ in
                    sessionRevokeFailedAction()
                }
            )

            return MCPSessionDetailsViewModel(
                session: session,
                userWallet: userWallet,
                revokeSession: UseCases.revokeSession,
                delegate: delegate,
                analyticsReporter: MCPAssembly.configuration.sessionsAnalyticsReporter,
                logger: MCPAssembly.configuration.logger
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
        let authorizationAnalyticsReporter: any MCPAuthorizationAnalyticsReporter
        let sessionsAnalyticsReporter: any MCPSessionsAnalyticsReporter
        let kingfisherImageCache: ImageCache
        let logger: TangemLogger.Logger

        public init(
            floatingSheetRegistry: FloatingSheetRegistry,
            baseURL: URL,
            requestAdapter: some Alamofire.RequestAdapter,
            requestRetrier: some Alamofire.RequestRetrier,
            authorizationAnalyticsReporter: some MCPAuthorizationAnalyticsReporter,
            sessionsAnalyticsReporter: some MCPSessionsAnalyticsReporter,
            kingfisherImageCache: ImageCache,
            logger: TangemLogger.Logger
        ) {
            self.floatingSheetRegistry = floatingSheetRegistry
            self.baseURL = baseURL
            self.requestAdapter = requestAdapter
            self.requestRetrier = requestRetrier
            self.authorizationAnalyticsReporter = authorizationAnalyticsReporter
            self.sessionsAnalyticsReporter = sessionsAnalyticsReporter
            self.kingfisherImageCache = kingfisherImageCache
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
        let kingfisherImageCache = configuration.kingfisherImageCache

        registry.register(MCPConnectionRequestViewModel.self) { viewModel in
            MCPConnectionRequestView(viewModel: viewModel, imageCache: kingfisherImageCache)
        }

        registry.register(MCPSwapIntentViewModel.self) { viewModel in
            MCPIntentView(viewModel: viewModel) { proposalViewModel in
                MCPSwapIntentProposalView(viewModel: proposalViewModel, kingfisherImageCache: kingfisherImageCache)
            }
        }

        registry.register(MCPSendIntentViewModel.self) { viewModel in
            MCPIntentView(viewModel: viewModel) { proposalViewModel in
                MCPSendIntentProposalView(viewModel: proposalViewModel, kingfisherImageCache: kingfisherImageCache)
            }
        }

        registry.register(MCPSessionDetailsViewModel.self) { viewModel in
            MCPSessionDetailsView(viewModel: viewModel, imageCache: kingfisherImageCache)
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
    }
}
