//
//  WalletConnectQRScanViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization
import struct TangemUIUtils.ConfirmationDialogViewModel

@MainActor
final class WalletConnectQRScanViewModel: ObservableObject {
    private let cameraAccessProvider: any WalletConnectCameraAccessProvider
    private let openSystemSettingsAction: () -> Void
    private weak var coordinator: (any WalletConnectQRScanRoutable)?
    private let uriParser = WalletConnectURLParser()
    private let feedbackGenerator = WalletConnectUIFeedbackGenerator()

    private var requestCameraAccessTask: Task<Void, Never>?

    @Published private(set) var state: WalletConnectQRScanViewState

    init(
        state: WalletConnectQRScanViewState,
        cameraAccessProvider: some WalletConnectCameraAccessProvider,
        openSystemSettingsAction: @escaping () -> Void,
        coordinator: some WalletConnectQRScanRoutable
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

extension WalletConnectQRScanViewModel {
    func handle(viewEvent: WalletConnectQRScanViewEvent) {
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
        do {
            let qrURI = try uriParser.parse(uriString: rawQRCode)
            coordinator?.dismiss(with: .fromQRCode(qrURI))
        } catch {
            feedbackGenerator.errorNotificationOccurred()
            coordinator?.display(error: error)
        }
    }

    private func handlePasteFromClipboardButtonTapped(_ rawClipboardString: String?) {
        guard let rawClipboardString else { return }

        do {
            let clipboardURI = try uriParser.parse(uriString: rawClipboardString)
            coordinator?.dismiss(with: .fromClipboard(clipboardURI))
        } catch {
            feedbackGenerator.errorNotificationOccurred()
            coordinator?.display(error: error)
        }
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
