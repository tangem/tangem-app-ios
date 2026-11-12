//
//  ConnectionsQRScanViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization
import struct TangemUIUtils.ConfirmationDialogViewModel

@MainActor
final class ConnectionsQRScanViewModel: ObservableObject {
    private let cameraAccessProvider: any WalletConnectCameraAccessProvider
    private let openSystemSettingsAction: () -> Void
    private weak var coordinator: (any ConnectionsQRScanRoutable)?
    private let uriParser = WalletConnectURLParser()
    private let feedbackGenerator = WalletConnectUIFeedbackGenerator()

    private var requestCameraAccessTask: Task<Void, Never>?

    @Published private(set) var state: ConnectionsQRScanViewState

    // [REDACTED_TODO_COMMENT]
    private var qrCodeNotYetProcessed = true

    init(
        state: ConnectionsQRScanViewState,
        cameraAccessProvider: some WalletConnectCameraAccessProvider,
        openSystemSettingsAction: @escaping () -> Void,
        coordinator: some ConnectionsQRScanRoutable
    ) {
        self.state = state
        self.cameraAccessProvider = cameraAccessProvider
        self.openSystemSettingsAction = openSystemSettingsAction
        self.coordinator = coordinator
    }

    deinit {
        requestCameraAccessTask?.cancel()
    }

    private func requestCameraAccess() {
        requestCameraAccessTask?.cancel()
        requestCameraAccessTask = Task { [cameraAccessProvider, weak self] in
            let accessGranted = await cameraAccessProvider.requestCameraAccess()
            self?.handle(viewEvent: .cameraAccessStatusChanged(accessGranted))
        }
    }
}

// MARK: - View events handling

extension ConnectionsQRScanViewModel {
    func handle(viewEvent: ConnectionsQRScanViewEvent) {
        switch viewEvent {
        case .viewDidAppear:
            handleViewDidAppear()

        case .navigationCloseButtonTapped:
            handleNavigationCloseButtonTapped()

        case .pasteFromClipboardButtonTapped(let rawClipboardString):
            handlePasteFromClipboardButtonTapped(rawClipboardString)

        case .qrCodeParsed(let rawQRCode):
            handleQRCodeParsed(rawQRCode)

        case .cameraAccessStatusChanged(let accessGranted):
            handleCameraAccessStatusChanged(accessGranted)

        case .closeDialogButtonTapped:
            handleCloseDialogButtonTapped()
        }
    }

    private func handleViewDidAppear() {
        switch cameraAccessProvider.checkCameraAccess() {
        case .authorized:
            handle(viewEvent: .cameraAccessStatusChanged(true))

        case .denied, .restricted:
            handle(viewEvent: .cameraAccessStatusChanged(false))

        case .notDetermined:
            requestCameraAccess()
        }
    }

    private func handleNavigationCloseButtonTapped() {
        coordinator?.dismiss(with: nil)
    }

    private func handleQRCodeParsed(_ rawQRCode: String) {
        guard qrCodeNotYetProcessed else {
            return
        }

        do {
            let scanResult = try parseScanResult(from: rawQRCode, source: .qrCode)

            qrCodeNotYetProcessed = false
            coordinator?.dismiss(with: scanResult)
        } catch {
            feedbackGenerator.errorNotificationOccurred()
            coordinator?.display(error: error)
        }
    }

    private func handlePasteFromClipboardButtonTapped(_ rawClipboardString: String?) {
        guard let rawClipboardString else { return }

        do {
            let scanResult = try parseScanResult(from: rawClipboardString, source: .clipboard)
            coordinator?.dismiss(with: scanResult)
        } catch {
            feedbackGenerator.errorNotificationOccurred()
            coordinator?.display(error: error)
        }
    }

    private func parseScanResult(
        from rawValue: String,
        source: ConnectionsQRScanResult.Source
    ) throws -> ConnectionsQRScanResult {
        if let userCode = MainQRMCPConnectionRequestUserCodeParser.parse(rawValue) {
            return .mcpConnectionRequest(userCode: userCode, source: source)
        }

        let uri = try uriParser.parse(uriString: rawValue)
        return .walletConnect(uri, source: source)
    }

    private func handleCameraAccessStatusChanged(_ accessGranted: Bool) {
        state.hasCameraAccess = accessGranted

        guard !accessGranted else { return }

        state.confirmationDialog = ConfirmationDialogViewModel(
            title: Localization.commonCameraDeniedAlertTitle,
            subtitle: Localization.commonCameraDeniedAlertMessage,
            buttons: [
                ConfirmationDialogViewModel.Button(title: Localization.commonCameraAlertButtonSettings, action: openSystemSettingsAction),
            ]
        )
    }

    private func handleCloseDialogButtonTapped() {
        coordinator?.dismiss(with: nil)
    }
}
