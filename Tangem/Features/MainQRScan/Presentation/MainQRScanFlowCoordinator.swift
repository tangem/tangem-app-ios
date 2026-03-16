//
//  MainQRScanFlowCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import TangemUIUtils

final class MainQRScanFlowCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    private let walletConnectURLParser = WalletConnectURLParser()

    // MARK: - State

    @Published var alert: AlertBinder?

    // MARK: - Child coordinators

    @Published var qrScanCoordinator: MainQRScanCoordinator?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        Task { @MainActor in
            openQRScanner()
        }
    }

    // MARK: - Flow Navigation

    @MainActor
    private func openQRScanner() {
        let dismissAction: Action<String?> = { [weak self] scannedCode in
            self?.qrScanCoordinator = nil

            guard let scannedCode else {
                self?.dismissAction(())
                return
            }

            self?.handleScannedCode(scannedCode)
        }

        let coordinator = MainQRScanCoordinator(
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )
        coordinator.start(with: .init())
        qrScanCoordinator = coordinator
    }

    // MARK: - Result Handling

    @MainActor
    private func handleScannedCode(_ code: String) {
        let value = code.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !value.isEmpty else {
            showUnrecognizedAlert()
            return
        }

        guard let uri = try? walletConnectURLParser.parse(uriString: value) else {
            showUnrecognizedAlert()
            return
        }

        handleWalletConnect(uri: uri)
    }

    @MainActor
    private func handleWalletConnect(uri: WalletConnectRequestURI) {
        guard let viewModel = WalletConnectModuleFactory.makeDAppConnectionViewModel(
            forURI: uri,
            source: .qrCode
        ) else {
            dismissAction(())
            return
        }

        viewModel.loadDAppProposal()
        floatingSheetPresenter.enqueue(sheet: viewModel)
        dismissAction(())
    }

    private func showUnrecognizedAlert() {
        alert = AlertBinder(
            alert: Alert(
                title: Text("Unrecognized QR Code"),
                message: Text("Sorry, this QR code could not be recognized."),
                dismissButton: .default(Text("OK")) { [weak self] in
                    self?.dismissAction(())
                }
            )
        )
    }
}

// MARK: - Options

extension MainQRScanFlowCoordinator {
    struct Options {}
}
