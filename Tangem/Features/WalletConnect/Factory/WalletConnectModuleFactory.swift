//
//  WalletConnectModuleFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import class UIKit.UIApplication
import class SwiftUI.UIHostingController
import class Kingfisher.ImageCache
import TangemUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemNetworkUtils

@MainActor
enum WalletConnectModuleFactory {
    @Injected(\.wcService) private static var walletConnectService: any WCService
    @Injected(\.dAppSessionsExtender) private static var dAppsSessionExtender: WalletConnectDAppSessionsExtender
    @Injected(\.userWalletRepository) private static var userWalletRepository: any UserWalletRepository
    @Injected(\.connectedDAppRepository) private static var connectedDAppRepository: any WalletConnectConnectedDAppRepository
    @Injected(\.dAppVerificationService) private static var dAppVerificationService: any WalletConnectDAppVerificationService
    @Injected(\.dAppIconURLResolver) private static var dAppIconURLResolver: WalletConnectDAppIconURLResolver
    @Injected(\.floatingSheetPresenter) private static var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.mailComposePresenter) private static var mailPresenter: MailComposePresenter

    private static let openSystemSettingsAction = UIApplication.openSystemSettings
    private static let cameraAccessProvider = AVWalletConnectCameraAccessProvider()

    private static let supportURLStub = "com.tangem.walletconnect.support"

    private static let disconnectDAppService = ReownWalletConnectDisconnectDAppService(walletConnectService: Self.walletConnectService)

    private static let dAppDataService = ReownWalletConnectDAppDataService(
        walletConnectService: Self.walletConnectService,
        dAppIconURLResolver: Self.dAppIconURLResolver
    )

    private static let dAppProposalApprovalService = ReownWalletConnectDAppProposalApprovalService(
        walletConnectService: Self.walletConnectService
    )

    private static let errorCodeFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    static func makeWalletConnectViewModel(
        coordinator: some WalletConnectRoutable,
        prefetchedConnectedDApps: [WalletConnectConnectedDApp]?
    ) -> WalletConnectViewModel {
        let establishDAppConnectionUseCase = WalletConnectEstablishDAppConnectionUseCase(
            userWalletRepository: userWalletRepository,
            cameraAccessProvider: cameraAccessProvider,
            openSystemSettingsAction: openSystemSettingsAction
        )

        let disconnectDAppUseCase = WalletConnectDisconnectDAppUseCase(
            disconnectDAppService: disconnectDAppService,
            connectedDAppRepository: connectedDAppRepository
        )

        let interactor = WalletConnectInteractor(
            extendConnectedDApps: WalletConnectExtendConnectedDAppsUseCase(sessionsExtender: dAppsSessionExtender),
            getConnectedDApps: WalletConnectGetConnectedDAppsUseCase(repository: connectedDAppRepository),
            establishDAppConnection: establishDAppConnectionUseCase,
            disconnectDApp: disconnectDAppUseCase
        )

        @Injected(\.cryptoAccountsGlobalStateProvider)
        var cryptoAccountsGlobalStateProvider: CryptoAccountsGlobalStateProvider

        return WalletConnectViewModel(
            interactor: interactor,
            userWalletRepository: userWalletRepository,
            cryptoAccountsGlobalStateProvider: cryptoAccountsGlobalStateProvider,
            analyticsLogger: CommonWalletConnectAnalyticsLogger(),
            logger: WCLogger,
            coordinator: coordinator,
            prefetchedConnectedDApps: prefetchedConnectedDApps
        )
    }

    static func makeDAppConnectionViewModel(
        forURI uri: WalletConnectRequestURI,
        source: Analytics.WalletConnectSessionSource
    ) -> WalletConnectDAppConnectionViewModel? {
        let filteredUserWallets = Self.userWalletRepository.models.filter { $0.config.isFeatureVisible(.walletConnect) }

        let hasMultipleAccountsWallet = filteredUserWallets.contains { userWalletModel in
            userWalletModel.accountModelsManager.accountModels.cryptoAccounts().hasMultipleAccounts
        }

        guard filteredUserWallets.isNotEmpty else {
            assertionFailure("UserWalletRepository does not have any UserWalletModel that supports WalletConnect feature. Developer mistake.")
            return nil
        }

        let selectedUserWallet: any UserWalletModel

        if let selectedModel = Self.userWalletRepository.selectedModel, selectedModel.config.isFeatureVisible(.walletConnect) {
            selectedUserWallet = selectedModel
        } else {
            selectedUserWallet = filteredUserWallets[0]
        }

        let getDAppConnectionProposalUseCase = WalletConnectGetDAppConnectionProposalUseCase(
            dAppDataService: dAppDataService,
            dAppProposalApprovalService: dAppProposalApprovalService,
            verificationService: dAppVerificationService,
            uri: uri
        )

        let migrateToAccountsUseCase = WalletConnectToAccountsMigrationUseCase(
            connectedDAppRepository: connectedDAppRepository,
            userWalletRepository: userWalletRepository,
            appSettings: AppSettings.shared,
            logger: WCLogger
        )

        let interactor = WalletConnectDAppConnectionInteractor(
            getDAppConnectionProposal: getDAppConnectionProposalUseCase,
            resolveAvailableBlockchains: WalletConnectResolveAvailableBlockchainsUseCase(),
            approveDAppProposal: WalletConnectApproveDAppProposalUseCase(dAppProposalApprovalService: dAppProposalApprovalService),
            rejectDAppProposal: WalletConnectRejectDAppProposalUseCase(dAppProposalApprovalService: dAppProposalApprovalService),
            persistConnectedDApp: WalletConnectPersistConnectedDAppUseCase(repository: connectedDAppRepository),
            migrateToAccounts: migrateToAccountsUseCase
        )

        let hapticFeedbackGenerator = WalletConnectUIFeedbackGenerator()

        let connectionRequestViewModel = WalletConnectDAppConnectionRequestViewModel(
            state: .loading(
                selectedUserWalletName: selectedUserWallet.name,
                targetSelectionIsAvailable: filteredUserWallets.count > 1 || hasMultipleAccountsWallet
            ),
            interactor: interactor,
            analyticsLogger: CommonWalletConnectDAppConnectionRequestAnalyticsLogger(source: source),
            logger: WCLogger,
            hapticFeedbackGenerator: hapticFeedbackGenerator,
            selectedUserWallet: selectedUserWallet
        )

        return WalletConnectDAppConnectionViewModel(
            connectionRequestViewModel: connectionRequestViewModel,
            hapticFeedbackGenerator: hapticFeedbackGenerator,
            userWallets: filteredUserWallets,
            selectedUserWallet: selectedUserWallet,
            dismissFlowAction: { [weak floatingSheetPresenter] in
                floatingSheetPresenter?.removeActiveSheet()
            }
        )
    }

    static func makeQRScanFlow(
        dismissAction: @escaping (WalletConnectQRScanResult?) -> Void
    ) -> (WalletConnectQRScanCoordinator, WalletConnectQRScanCoordinator.Options) {
        let coordinator = WalletConnectQRScanCoordinator(dismissAction: dismissAction)

        let options = WalletConnectQRScanCoordinator.Options(
            cameraAccessProvider: cameraAccessProvider,
            openSystemSettingsAction: openSystemSettingsAction
        )

        return (coordinator, options)
    }

    static func makeConnectedDAppDetailsViewModel(_ dApp: WalletConnectConnectedDApp) -> WalletConnectConnectedDAppDetailsViewModel {
        let disconnectDAppUseCase = WalletConnectDisconnectDAppUseCase(
            disconnectDAppService: disconnectDAppService,
            connectedDAppRepository: connectedDAppRepository
        )

        return WalletConnectConnectedDAppDetailsViewModel(
            connectedDApp: dApp,
            disconnectDAppUseCase: disconnectDAppUseCase,
            userWalletRepository: userWalletRepository,
            analyticsLogger: CommonWalletConnectConnectedDAppDetailsAnalyticsLogger(dAppData: dApp.dAppData),
            logger: WCLogger,
            closeAction: { [weak floatingSheetPresenter] in
                floatingSheetPresenter?.removeActiveSheet()
            },
            onDisconnect: {
                makeSuccessToast(with: Localization.wcDappDisconnected)
                    .present(layout: .top(padding: 20), type: .temporary())
            }
        )
    }

    static func makeSuccessToast(with message: String) -> Toast<SuccessToast> {
        Toast(view: SuccessToast(text: message))
    }

    // MARK: - Formatters

    private static func formattedErrorCode(from walletConnectError: some UniversalError) -> String {
        errorCodeFormatter.string(from: NSNumber(value: walletConnectError.errorCode)) ?? "\(walletConnectError.errorCode)"
    }

    // MARK: - Errors factory methods

    static func makeDAppProposalLoadingErrorToast(_ proposalLoadingError: WalletConnectDAppProposalLoadingError) -> Toast<WarningToast>? {
        let errorMessage: String

        switch proposalLoadingError {
        case .pairingFailed, .selectedAccountRetrievalFailed:
            errorMessage = Localization.wcAlertUnknownErrorDescription(formattedErrorCode(from: proposalLoadingError))

        case .uriAlreadyUsed,
             .invalidDomainURL,
             .unsupportedDomain,
             .unsupportedBlockchains,
             .noBlockchainsProvidedByDApp,
             .pairingTimeout,
             .cancelledByUser:
            return nil
        }

        return Toast(view: WarningToast(text: errorMessage))
    }

    static func makeDAppProposalApprovalErrorToast(_ proposalApprovalError: WalletConnectDAppProposalApprovalError) -> Toast<WarningToast>? {
        let errorMessage: String

        switch proposalApprovalError {
        case .approvalFailed:
            errorMessage = Localization.wcAlertUnknownErrorDescription(formattedErrorCode(from: proposalApprovalError))

        case .invalidConnectionRequest,
             .proposalExpired,
             .rejectionFailed,
             .cancelledByUser:
            return nil
        }

        return Toast(view: WarningToast(text: errorMessage))
    }

    static func makeDAppPersistenceErrorToast(_ dAppPersistenceError: WalletConnectDAppPersistenceError) -> Toast<WarningToast> {
        return Toast(view: WarningToast(text: Localization.wcAlertUnsupportedMethodTitle))
    }

    static func makeGenericErrorToast(_ error: some Error) -> Toast<WarningToast> {
        Toast(
            view: WarningToast(
                text: Localization.wcAlertUnknownErrorDescription(formattedErrorCode(from: error.toUniversalError()))
            )
        )
    }

    static func makeDAppProposalLoadingErrorViewModel(
        _ proposalLoadingError: WalletConnectDAppProposalLoadingError,
        closeAction: @escaping () -> Void
    ) -> WalletConnectErrorViewModel? {
        let viewState: WalletConnectErrorViewState

        switch proposalLoadingError {
        case .uriAlreadyUsed:
            viewState = WalletConnectErrorViewState(
                icon: .walletConnect,
                title: Localization.wcUriAlreadyUsedTitle,
                subtitle: Localization.wcUriAlreadyUsedDescription,
                buttonStyle: .primary
            )

        case .invalidDomainURL:
            viewState = WalletConnectErrorViewState(
                icon: .walletConnect,
                title: Localization.wcErrorsInvalidDomainTitle,
                subtitle: Localization.wcErrorsInvalidDomainSubtitle,
                buttonStyle: .primary
            )

        case .unsupportedDomain(let unsupportedDomainError):
            viewState = WalletConnectErrorViewState(
                icon: .walletConnect,
                title: Localization.wcAlertUnsupportedDappsTitle,
                subtitle: Localization.wcAlertUnsupportedDappsDescription(unsupportedDomainError.dAppName),
                buttonStyle: .primary
            )

        case .unsupportedBlockchains(let unsupportedBlockchainsError):
            viewState = WalletConnectErrorViewState(
                icon: .blockchain,
                title: Localization.wcAlertUnsupportedNetworksTitle,
                subtitle: Localization.wcAlertUnsupportedNetworksDescription(unsupportedBlockchainsError.dAppName),
                buttonStyle: .primary
            )

        case .noBlockchainsProvidedByDApp(let noBlockchainsProvidedByDAppError):
            viewState = WalletConnectErrorViewState(
                icon: .blockchain,
                title: Localization.wcErrorsNoBlockchainsTitle,
                subtitle: Localization.wcErrorsNoBlockchainsSubtitle(noBlockchainsProvidedByDAppError.dAppName),
                buttonStyle: .primary
            )

        case .pairingTimeout:
            viewState = WalletConnectErrorViewState(
                icon: .walletConnect,
                title: Localization.wcAlertConnectionTimeoutTitle,
                subtitle: Localization.walletConnectErrorTimeout,
                buttonStyle: .primary
            )

        case .pairingFailed, .cancelledByUser, .selectedAccountRetrievalFailed:
            return nil
        }

        return WalletConnectErrorViewModel(
            state: viewState,
            contactSupportAction: makeContactSupportAction(for: proposalLoadingError),
            closeAction: closeAction
        )
    }

    static func makeDAppProposalApprovalErrorViewModel(
        _ proposalApprovalError: WalletConnectDAppProposalApprovalError,
        closeAction: @escaping () -> Void
    ) -> WalletConnectErrorViewModel? {
        let viewState: WalletConnectErrorViewState

        switch proposalApprovalError {
        case .invalidConnectionRequest:
            let subtitle = Localization.wcAlertUnknownErrorDescription(formattedErrorCode(from: proposalApprovalError))

            viewState = WalletConnectErrorViewState(
                icon: .warning,
                title: Localization.wcAlertUnknownErrorTitle,
                subtitle: subtitle,
                buttonStyle: .secondary
            )

        case .proposalExpired:
            viewState = WalletConnectErrorViewState(
                icon: .blockchain,
                title: Localization.wcErrorsProposalExpiredTitle,
                subtitle: Localization.wcErrorsProposalExpiredSubtitle,
                buttonStyle: .primary
            )

        case .approvalFailed, .rejectionFailed, .cancelledByUser:
            return nil
        }

        return WalletConnectErrorViewModel(
            state: viewState,
            contactSupportAction: makeContactSupportAction(for: proposalApprovalError),
            closeAction: closeAction
        )
    }

    static func makeTransactionRequestProcessingErrorViewModel(
        _ transactionRequestProcessingError: WalletConnectTransactionRequestProcessingError,
        closeAction: @escaping () -> Void
    ) -> WalletConnectErrorViewModel? {
        let viewState: WalletConnectErrorViewState

        switch transactionRequestProcessingError {
        case .unsupportedBlockchain(let caipBlockchain):
            viewState = WalletConnectErrorViewState(
                icon: .blockchain,
                title: Localization.wcAlertUnsupportedNetworkTitle,
                subtitle: Localization.wcAlertUnsupportedNetworkDescription(caipBlockchain),
                buttonStyle: .secondary
            )

        case .blockchainToAddRequiresDAppReconnection(let blockchain):
            viewState = WalletConnectErrorViewState(
                icon: .blockchain,
                title: Localization.wcAlertNetworkNotConnectedTitle,
                subtitle: Localization.wcAlertNetworkNotConnectedDescription(blockchain.displayName),
                buttonStyle: .secondary
            )

        case .blockchainToAddIsMissingFromUserWallet(let blockchain):
            viewState = WalletConnectErrorViewState(
                icon: .blockchain,
                title: Localization.wcAlertAddNetworkToPortfolioTitle,
                subtitle: Localization.wcAlertAddNetworkToPortfolioDescription(blockchain.displayName),
                buttonStyle: .secondary
            )

        case .invalidPayload,
             .blockchainToAddDuplicate,
             .unsupportedMethod,
             .walletModelNotFound,
             .userWalletNotFound,
             .userWalletRepositoryIsLocked,
             .userWalletIsLocked,
             .missingEthTransactionSigner,
             .missingGasLoader,
             .eraseMultipleTransactions,
             .accountNotFound:
            // [REDACTED_TODO_COMMENT]
            return nil
        }

        return WalletConnectErrorViewModel(
            state: viewState,
            contactSupportAction: makeContactSupportAction(for: transactionRequestProcessingError),
            closeAction: closeAction
        )
    }

    private static func makeContactSupportAction(for error: some UniversalError) -> () -> Void {
        { [weak floatingSheetPresenter] in
            floatingSheetPresenter?.removeActiveSheet()

            let mailViewModel = MailViewModel(
                logsComposer: LogsComposer(infoProvider: BaseDataCollector()),
                recipient: EmailConfig.default.recipient,
                emailType: .walletConnectUntypedError(formattedErrorCode: Self.formattedErrorCode(from: error))
            )

            mailPresenter.present(viewModel: mailViewModel)
        }
    }
}
