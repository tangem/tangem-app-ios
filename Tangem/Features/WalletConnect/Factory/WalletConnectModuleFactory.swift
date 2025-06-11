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
import TangemAssets
import TangemLocalization
import TangemFoundation

@MainActor
enum WalletConnectModuleFactory {
    @Injected(\.wcService) private static var walletConnectService: any WCService
    @Injected(\.userWalletRepository) private static var userWalletRepository: any UserWalletRepository
    @Injected(\.floatingSheetPresenter) private static var floatingSheetPresenter: any FloatingSheetPresenter

    private static let openSystemSettingsAction = UIApplication.openSystemSettings
    private static let cameraAccessProvider = AVWalletConnectCameraAccessProvider()

    private static let supportURLStub = "com.tangem.walletconnect.support"

    private static let dAppDataService = ReownWalletConnectDAppDataService(walletConnectService: Self.walletConnectService)
    private static let dAppProposalApprovalService = ReownWalletConnectDAppProposalApprovalService(
        walletConnectService: Self.walletConnectService
    )

    private static let dAppVerificationService = BlockaidWalletConnectDAppVerificationService(
        apiService: BlockaidFactory().makeBlockaidAPIService()
    )

    private static let dateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .numeric
        return formatter
    }()

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

        return WalletConnectViewModel(
            walletConnectService: walletConnectService,
            userWalletRepository: userWalletRepository,
            establishDAppConnectionUseCase: establishDAppConnectionUseCase,
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
            connectDApp: WalletConnectConnectDAppUseCase(dAppProposalApprovalService: dAppProposalApprovalService),
            rejectDAppProposal: WalletConnectRejectDAppProposalUseCase(dAppProposalApprovalService: dAppProposalApprovalService)
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

    static func makeConnectedDAppDetailsViewModel(_ dApp: WalletConnectSavedSession) -> WalletConnectConnectedDAppDetailsViewModel {
        let userWallet = userWalletRepository.models.first(where: { $0.userWalletId.stringValue == dApp.userWalletId })
        let imageProvider = NetworkImageProvider()

        let state = WalletConnectConnectedDAppDetailsViewState(
            navigationBar: WalletConnectConnectedDAppDetailsViewState.NavigationBar(connectedTime: Self.connectedTime(from: dApp)),
            dAppDescriptionSection: .content(
                WalletConnectDAppDescriptionViewModel.ContentState(
                    // [REDACTED_TODO_COMMENT]
                    iconURL: nil,
                    name: dApp.sessionInfo.dAppInfo.name,
                    domain: URL(string: dApp.sessionInfo.dAppInfo.url)
                )
            ),
            walletSection: WalletConnectConnectedDAppDetailsViewState.WalletSection(walletName: userWallet?.name),
            connectedNetworksSection: WalletConnectConnectedDAppDetailsViewState.ConnectedNetworksSection(
                blockchains: dApp.connectedBlockchains.map { blockchain in
                    WalletConnectConnectedDAppDetailsViewState.BlockchainRowItem(
                        id: blockchain.networkId,
                        asset: imageProvider.provide(by: blockchain, filled: true),
                        name: blockchain.displayName,
                        currencySymbol: blockchain.currencySymbol
                    )
                }
            )
        )

        return WalletConnectConnectedDAppDetailsViewModel(
            state: state,
            dAppID: dApp.id,
            walletConnectService: walletConnectService,
            closeAction: { [weak floatingSheetPresenter] in
                floatingSheetPresenter?.removeActiveSheet()
            }
        )
    }

    static func makeSuccessToast(with message: String) -> Toast<SuccessToast> {
        Toast(view: SuccessToast(text: message))
    }

    // MARK: - Formatters

    private static func connectedTime(from dApp: WalletConnectSavedSession) -> String? {
        // [REDACTED_TODO_COMMENT]
        guard let connectionDate = dApp.connectionDate else { return nil }
        let relativeDateString = dateFormatter.localizedString(for: connectionDate, relativeTo: Date.now)
        let delimiter = " • "
        let timeString = connectionDate.formatted(.dateTime.hour().minute())

        return relativeDateString + delimiter + timeString
    }

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
