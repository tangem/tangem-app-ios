//
//  WalletConnectModuleFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import class UIKit.UIApplication
import TangemAssets
import TangemLocalization
import TangemFoundation

@MainActor
enum WalletConnectModuleFactory {
    @Injected(\.wcService) private static var walletConnectService: any WCService
    @Injected(\.userWalletRepository) private static var userWalletRepository: any UserWalletRepository
    @Injected(\.floatingSheetPresenter) private static var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.safariManager) private static var safariManager: SafariManager

    private static let openSystemSettingsAction = UIApplication.openSystemSettings
    private static let cameraAccessProvider = AVWalletConnectCameraAccessProvider()
    // [REDACTED_TODO_COMMENT]
    private static let supportURL: URL = AppEnvironment.current.tangemComBaseUrl

    private static let dateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .numeric
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

        let state = WalletConnectConnectedDAppDetailsViewState(
            navigationBar: WalletConnectConnectedDAppDetailsViewState.NavigationBar(connectedTime: Self.connectedTime(from: dApp)),
            dAppDescriptionSection: WalletConnectConnectedDAppDetailsViewState.DAppDescriptionSection(
                id: dApp.id,
                iconURL: nil,
                name: dApp.sessionInfo.dAppInfo.name,
                domain: dApp.sessionInfo.dAppInfo.url
            ),
            walletSection: WalletConnectConnectedDAppDetailsViewState.WalletSection(walletName: userWallet?.name),
            connectedNetworksSection: WalletConnectConnectedDAppDetailsViewState.ConnectedNetworksSection(
                blockchains: dApp.connectedBlockchains.map { blockchain in
                    WalletConnectConnectedDAppDetailsViewState.BlockchainRowItem(
                        id: blockchain.networkId,
                        asset: NetworkImageProvider().provide(by: blockchain, filled: true),
                        name: blockchain.displayName,
                        currencySymbol: blockchain.currencySymbol
                    )
                }
            )
        )

        return WalletConnectConnectedDAppDetailsViewModel(
            state: state,
            walletConnectService: walletConnectService,
            closeAction: { [weak floatingSheetPresenter] in
                floatingSheetPresenter?.removeActiveSheet()
            }
        )
    }

    static func makeErrorViewModel(for error: WalletConnectV2Error, dAppName: String) -> WalletConnectErrorViewModel? {
        let state: WalletConnectErrorViewState
        let openURLAction: (URL) -> Void = { [safariManager] url in
            safariManager.openURL(url)
        }

        let closeAction: () -> Void = { [weak floatingSheetPresenter] in
            floatingSheetPresenter?.removeActiveSheet()
        }

        switch error {
        case .unsupportedBlockchains, .unsupportedNetwork:
            state = WalletConnectErrorViewState(
                icon: .blockchain,
                title: Localization.wcAlertUnsupportedNetworksTitle,
                subtitle: Localization.wcAlertUnsupportedNetworksDescription(dAppName),
                buttonStyle: .primary
            )

        case .sessionForTopicNotFound:
            state = WalletConnectErrorViewState(
                icon: .walletConnect,
                title: Localization.wcAlertSessionDisconnectedTitle,
                subtitle: Localization.wcAlertSessionDisconnectedDescription,
                buttonStyle: .primary
            )

        case .sessionConnectionTimeout:
            state = WalletConnectErrorViewState(
                icon: .walletConnect,
                title: Localization.wcAlertConnectionTimeoutTitle,
                subtitle: Localization.wcAlertConnectionTimeoutDescription,
                buttonStyle: .primary
            )

        case .wrongCardSelected:
            state = WalletConnectErrorViewState(
                icon: .warning,
                title: Localization.wcAlertWrongCardTitle,
                subtitle: Localization.wcAlertWrongCardDescription,
                buttonStyle: .secondary
            )

        case .unsupportedWCMethod, .dataInWrongFormat, .notEnoughDataInRequest, .walletModelNotFound:
            state = WalletConnectErrorViewState(
                icon: .warning,
                title: Localization.wcAlertUnknownErrorTitle,
                subtitle: "Error code: \(error.code). If the problem persists — feel free [to contact our support.](\(Self.supportURL))",
                buttonStyle: .secondary
            )

        default:
            return nil
        }

        return WalletConnectErrorViewModel(state: state, supportURL: Self.supportURL, openURLAction: openURLAction, closeAction: closeAction)
    }

    // MARK: - Private methods

    private static func connectedTime(from dApp: WalletConnectSavedSession) -> String? {
        // [REDACTED_TODO_COMMENT]
        guard let connectionDate = dApp.connectionDate else { return nil }
        let relativeDateString = dateFormatter.localizedString(for: connectionDate, relativeTo: Date.now)
        let delimiter = " • "
        let timeString = connectionDate.formatted(.dateTime.hour().minute())

        return relativeDateString + delimiter + timeString
    }
}
