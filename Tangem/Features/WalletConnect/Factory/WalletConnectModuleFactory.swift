//
//  WalletConnectModuleFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import class UIKit.UIApplication

@MainActor
final class WalletConnectModuleFactory {
    @Injected(\.wcService) private var walletConnectService: any WCService
    @Injected(\.userWalletRepository) private var userWalletRepository: any UserWalletRepository
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    private let openSystemSettingsAction = UIApplication.openSystemSettings
    private lazy var cameraAccessProvider = AVWalletConnectCameraAccessProvider()

    private lazy var dateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .numeric
        return formatter
    }()

    nonisolated init() {}

    func makeWalletConnectViewModel(coordinator: some WalletConnectRoutable) -> WalletConnectViewModel {
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

    func makeQRScanFlow(
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

    func makeConnectedDAppDetailsViewModel(_ dApp: WalletConnectSavedSession) -> WalletConnectConnectedDAppDetailsViewModel {
        let userWallet = userWalletRepository.models.first(where: { $0.userWalletId.stringValue == dApp.userWalletId })

        let state = WalletConnectConnectedDAppDetailsViewState(
            navigationBar: WalletConnectConnectedDAppDetailsViewState.NavigationBar(connectedTime: connectedTime(from: dApp)),
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

    // MARK: - Private methods

    private func connectedTime(from dApp: WalletConnectSavedSession) -> String? {
        // [REDACTED_TODO_COMMENT]
        guard let connectionDate = dApp.connectionDate else { return nil }
        let relativeDateString = dateFormatter.localizedString(for: connectionDate, relativeTo: Date.now)
        let delimiter = " • "
        let timeString = connectionDate.formatted(.dateTime.hour().minute())

        return relativeDateString + delimiter + timeString
    }
}
