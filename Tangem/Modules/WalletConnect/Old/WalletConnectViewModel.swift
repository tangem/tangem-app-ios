//
//  WalletConnectViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import AVFoundation

class OldWalletConnectViewModel: ObservableObject {
    @Injected(\.walletConnectService) private var walletConnectService: OldWalletConnectService

    @Published var isActionSheetVisible: Bool = false
    @Published var showCameraDeniedAlert: Bool = false
    @Published var alert: AlertBinder?
    @Published var isServiceBusy: Bool = true

    @Published @MainActor var sessions: [WalletConnectSavedSession] = []

    @MainActor
    var noActiveSessions: Bool { sessions.isEmpty }

    private let disabledLocalizedReason: String?
    private var bag = Set<AnyCancellable>()
    private var pendingURI: WalletConnectRequestURI?
    private var scannedQRCode: CurrentValueSubject<String?, Never> = .init(nil)

    private weak var coordinator: WalletConnectRoutable?

    init(disabledLocalizedReason: String?, coordinator: WalletConnectRoutable) {
        self.disabledLocalizedReason = disabledLocalizedReason
        self.coordinator = coordinator
    }

    deinit {
        WCLogger.debug(self)
    }

    func onAppear() {
        Analytics.log(.walletConnectScreenOpened)
        bind()
    }

    func disconnectSession(_ session: WalletConnectSavedSession) {
        Analytics.log(.buttonStopWalletConnectSession)
        Task { [weak self] in
            await self?.walletConnectService.disconnectSession(with: session.id)
            await runOnMain {
                withAnimation {
                    self?.objectWillChange.send()
                }
            }
        }
    }

    func readFromClipboard() -> WalletConnectRequestURI? {
        guard let pasteboardValue = UIPasteboard.general.string else {
            return nil
        }

        return try? WalletConnectURLParser().parse(uriString: pasteboardValue)
    }

    func pasteFromClipboard() {
        guard let pendingURI else { return }

        openSession(with: pendingURI, source: .clipboard)
        self.pendingURI = nil
    }

    func openSession() {
        Analytics.log(.buttonStartWalletConnectSession)

        if let disabledLocalizedReason {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        pendingURI = readFromClipboard()

        if pendingURI != nil {
            isActionSheetVisible = true
        } else {
            openQRScanner()
        }
    }

    private func openSession(with uri: WalletConnectRequestURI, source: Analytics.WalletConnectSessionSource) {
        Analytics.debugLog(eventInfo: Analytics.WalletConnectDebugEvent.attemptingToOpenSession(url: uri.debugString))
        walletConnectService.openSession(with: uri, source: source)
    }

    private func bind() {
        bag.removeAll()

        subscribeToNewSessions()

        walletConnectService.canEstablishNewSessionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] canEstablishNewSession in
                self?.isServiceBusy = !canEstablishNewSession
            }
            .store(in: &bag)

        scannedQRCode
            .compactMap { $0 }
            .compactMap { [weak self] in
                self?.parseURI($0)
            }
            .sink { [weak self] uri in
                self?.openSession(with: uri, source: .qrCode)
            }
            .store(in: &bag)
    }

    func parseURI(_ uri: String) -> WalletConnectRequestURI? {
        do {
            let uri = try WalletConnectURLParser().parse(uriString: uri)
            return uri
        } catch {
            makeAlert(with: error.localizedDescription)
            return nil
        }
    }

    func makeAlert(with message: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.alert = AlertBuilder.makeOkErrorAlert(message: message)
        }
    }

    private func subscribeToNewSessions() {
        Task {
            for await sessions in await walletConnectService.newSessions {
                WCLogger.info("Loaded v2 sessions: \(sessions)")

                await MainActor.run {
                    withAnimation {
                        self.sessions = sessions
                    }
                }
            }
        }
    }
}

// MARK: - Navigation

extension OldWalletConnectViewModel {
    func openQRScanner() {
        if case .denied = AVCaptureDevice.authorizationStatus(for: .video) {
            showCameraDeniedAlert = true
        } else {
            let binding = Binding<String>(
                get: { [weak self] in
                    self?.scannedQRCode.value ?? ""
                },
                set: { [weak self] in
                    self?.scannedQRCode.send($0)
                }
            )

            coordinator?.openQRScanner(with: binding)
        }
    }
}
