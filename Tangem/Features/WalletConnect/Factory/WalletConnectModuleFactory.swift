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

    static func makeWalletConnectViewModel(coordinator: some WalletConnectRoutable) -> WalletConnectViewModel {
        let establishDAppConnectionUseCase = WalletConnectEstablishDAppConnectionUseCase(
            userWalletRepository: userWalletRepository,
            uriProvider: UIPasteBoardWalletConnectURIProvider(pasteboard: .general, parser: .init()),
            cameraAccessProvider: cameraAccessProvider,
            openSystemSettingsAction: openSystemSettingsAction
        )

        let disconnectDAppUseCase = WalletConnectDisconnectDAppUseCase(
            disconnectDAppService: disconnectDAppService,
            connectedDAppRepository: connectedDAppRepository
        )

        let getConnectedDAppsUseCase = WalletConnectGetConnectedDAppsUseCase(repository: connectedDAppRepository)

        return WalletConnectViewModel(
            establishDAppConnectionUseCase: establishDAppConnectionUseCase,
            getConnectedDAppsUseCase: getConnectedDAppsUseCase,
            dAppsSessionExtender: dAppsSessionExtender,
            disconnectDAppUseCase: disconnectDAppUseCase,
            userWalletRepository: userWalletRepository,
            coordinator: coordinator
        )
    }

    static func makeDAppConnectionViewModel(
        forURI uri: WalletConnectRequestURI,
        source: Analytics.WalletConnectSessionSource
    ) -> WalletConnectDAppConnectionViewModel? {
        let filteredUserWallets = Self.userWalletRepository.models.filter { $0.config.isFeatureVisible(.walletConnect) }

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
            uri: uri,
            analyticsSource: source
        )

        let interactor = WalletConnectDAppConnectionInteractor(
            getDAppConnectionProposal: getDAppConnectionProposalUseCase,
            resolveAvailableBlockchains: WalletConnectResolveAvailableBlockchainsUseCase(),
            approveDAppProposal: WalletConnectApproveDAppProposalUseCase(dAppProposalApprovalService: dAppProposalApprovalService),
            rejectDAppProposal: WalletConnectRejectDAppProposalUseCase(dAppProposalApprovalService: dAppProposalApprovalService),
            persistConnectedDApp: WalletConnectPersistConnectedDAppUseCase(repository: connectedDAppRepository)
        )

        return WalletConnectDAppConnectionViewModel(
            interactor: interactor,
            hapticFeedbackGenerator: WalletConnectUIFeedbackGenerator(),
            userWallets: filteredUserWallets,
            selectedUserWallet: selectedUserWallet,
            dismissFlowAction: { [weak floatingSheetPresenter] in
                floatingSheetPresenter?.removeActiveSheet()
            }
        )
    }

    static func makeQRScanFlow(
        clipboardURI: WalletConnectRequestURI?,
        dismissAction: @escaping (WalletConnectQRScanResult?) -> Void
    ) -> (WalletConnectQRScanCoordinator, WalletConnectQRScanCoordinator.Options) {
        let coordinator = WalletConnectQRScanCoordinator(dismissAction: dismissAction)

        let options = WalletConnectQRScanCoordinator.Options(
            clipboardURI: clipboardURI,
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
            closeAction: { [weak floatingSheetPresenter] in
                floatingSheetPresenter?.removeActiveSheet()
            },
            onDisconnect: {
                makeSuccessToast(with: "dApp disconnected")
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

    // [REDACTED_TODO_COMMENT]

    static func makeDAppProposalLoadingErrorToast(_ proposalLoadingError: WalletConnectDAppProposalLoadingError) -> Toast<WarningToast>? {
        let errorMessage: String

        switch proposalLoadingError {
        case .pairingFailed:
            errorMessage = """
            An error occurred. Code: \(formattedErrorCode(from: proposalLoadingError))
            If the problem persists — feel free to contact our support.
            """

        case .uriAlreadyUsed,
             .invalidDomainURL,
             .unsupportedDomain,
             .unsupportedBlockchains,
             .noBlockchainsProvidedByDApp,
             .cancelledByUser:
            return nil
        }

        return Toast(view: WarningToast(text: errorMessage))
    }

    static func makeDAppProposalApprovalErrorToast(_ proposalApprovalError: WalletConnectDAppProposalApprovalError) -> Toast<WarningToast>? {
        let errorMessage: String

        switch proposalApprovalError {
        case .approvalFailed:
            errorMessage = """
            Connection failed. Code: \(formattedErrorCode(from: proposalApprovalError))
            If the problem persists — feel free to contact our support.
            """

        case .invalidConnectionRequest,
             .proposalExpired,
             .rejectionFailed,
             .cancelledByUser:
            return nil
        }

        return Toast(view: WarningToast(text: errorMessage))
    }

    static func makeDAppPersistenceErrorToast(_ dAppPersistenceError: WalletConnectDAppPersistenceError) -> Toast<WarningToast> {
        // [REDACTED_TODO_COMMENT]
        return Toast(view: WarningToast(text: ""))
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
                title: "URI already used",
                subtitle: "Ensure that each pairing attempt uses a fresh and unique URI",
                buttonStyle: .primary
            )

        case .invalidDomainURL:
            viewState = WalletConnectErrorViewState(
                icon: .walletConnect,
                title: "Invalid dApp domain",
                subtitle: "Try pairing again with a fresh URI",
                buttonStyle: .primary
            )

        case .unsupportedDomain(let unsupportedDomainError):
            viewState = WalletConnectErrorViewState(
                icon: .walletConnect,
                title: "Unsupported dApp",
                subtitle: "\(unsupportedDomainError.dAppName) is not supported by Tangem",
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
                title: "No networks",
                subtitle: """
                \(noBlockchainsProvidedByDAppError.dAppName) does not specify any blockchains — neither required nor optional.
                Please ensure you used the correct URI
                """,
                buttonStyle: .primary
            )

        case .pairingFailed, .cancelledByUser:
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
            let subtitle =
                """
                Error code: \(formattedErrorCode(from: proposalApprovalError)).
                If the problem persists \(AppConstants.emDashSign) feel free [to contact our support.](\(Self.supportURLStub))
                """

            viewState = WalletConnectErrorViewState(
                icon: .warning,
                title: Localization.wcAlertUnknownErrorTitle,
                subtitle: subtitle,
                buttonStyle: .secondary
            )

        case .proposalExpired:
            viewState = WalletConnectErrorViewState(
                icon: .blockchain,
                title: "Connection proposal expired",
                subtitle: "Please, generate a new URI and attempt connecting again",
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

    private static func makeContactSupportAction(for error: some UniversalError) -> () -> Void {
        { [weak floatingSheetPresenter] in
            floatingSheetPresenter?.removeActiveSheet()

            let mailViewModel = MailViewModel(
                logsComposer: LogsComposer(infoProvider: BaseDataCollector()),
                recipient: EmailConfig.default.recipient,
                emailType: .walletConnectUntypedError(formattedErrorCode: Self.formattedErrorCode(from: error))
            )
            let mailView = MailView(viewModel: mailViewModel)
            AppPresenter.shared.show(UIHostingController(rootView: mailView))
        }
    }
}
