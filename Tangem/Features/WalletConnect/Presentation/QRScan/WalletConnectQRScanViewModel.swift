//
//  WalletConnectQRScanViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

@MainActor
final class WalletConnectQRScanViewModel: ObservableObject {
    private let cameraAccessProvider: any WalletConnectCameraAccessProvider
    private let openSystemSettingsAction: () -> Void
    private let coordinator: any WalletConnectQRScanRoutable

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

        case .pasteFromClipboardButtonTapped(let clipboardURI):
            handlePasteFromClipboardButtonTapped(clipboardURI)

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
        coordinator.dismiss(with: nil)
    }

    private func handleQRCodeParsed(_ rawQRCode: String) {
        do {
            let qrURI = try WalletConnectURLParser().parse(uriString: rawQRCode)
            coordinator.dismiss(with: .fromQRCode(qrURI))
        } catch {
            // [REDACTED_TODO_COMMENT]
        }
    }

    private func handlePasteFromClipboardButtonTapped(_ clipboardURI: WalletConnectRequestURI) {
        coordinator.dismiss(with: .fromClipboard(clipboardURI))
    }

    private func handleCameraAccessStatusChanged(_ accessGranted: Bool) {
        state.hasCameraAccess = accessGranted
        guard !accessGranted else { return }

        let pasteFromClipboardAction: (() -> Void)?

        if let clipboardURI = state.pasteFromClipboardButton?.clipboardURI {
            pasteFromClipboardAction = { [coordinator] in
                coordinator.dismiss(with: .fromClipboard(clipboardURI))
            }
        } else {
            pasteFromClipboardAction = nil
        }

        state.confirmationDialog = .cameraAccessDenied(
            openSystemSettingsAction: openSystemSettingsAction,
            pasteFromClipboardAction: pasteFromClipboardAction
        )
    }

    private func handleCloseDialogButtonTapped() {
        coordinator.dismiss(with: nil)
    }
}
