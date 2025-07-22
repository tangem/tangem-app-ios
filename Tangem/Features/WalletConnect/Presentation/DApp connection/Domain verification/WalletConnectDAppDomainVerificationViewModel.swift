//
//  WalletConnectDAppDomainVerificationViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemAssets
import TangemLocalization

@MainActor
final class WalletConnectDAppDomainVerificationViewModel: ObservableObject {
    private let closeAction: () -> Void
    private let connectAnywayAction: (() async -> Void)?

    private var cancelTask: Task<Void, Never>?
    private var connectAnywayTask: Task<Void, Never>?

    @Published private(set) var state: WalletConnectDAppDomainVerificationViewState

    init(verifiedDAppName: String, closeAction: @escaping () -> Void) {
        self.closeAction = closeAction
        connectAnywayAction = nil

        state = .verifiedDomain(forDAppName: verifiedDAppName)
    }

    init(
        warningVerificationStatus: WalletConnectDAppVerificationStatus,
        closeAction: @escaping () -> Void,
        connectAnywayAction: @escaping () async -> Void
    ) {
        assert(!warningVerificationStatus.isVerified, "WalletConnectDAppDomainVerificationViewModel invalid init used.")

        self.closeAction = closeAction
        self.connectAnywayAction = connectAnywayAction

        state = .domainWarning(warningVerificationStatus)
    }

    deinit {
        connectAnywayTask?.cancel()
    }
}

// MARK: - View events handling

// [REDACTED_TODO_COMMENT]
extension WalletConnectDAppDomainVerificationViewModel {
    func handle(viewEvent: WalletConnectDAppDomainVerificationViewEvent) {
        switch viewEvent {
        case .navigationCloseButtonTapped, .actionButtonTapped(.done):
            connectAnywayTask?.cancel()
            closeAction()

        case .actionButtonTapped(.cancel):
            connectAnywayTask?.cancel()
            closeAction()

        case .actionButtonTapped(.connectAnyway):
            handleConnectAnywayButtonTapped()
        }
    }

    private func handleConnectAnywayButtonTapped() {
        guard
            let connectAnywayAction,
            let connectAnywayButtonIndex = state.buttons.firstIndex(where: { $0.role == .connectAnyway }),
            state.buttons.allSatisfy({ !$0.isLoading })
        else {
            return
        }

        state.buttons[connectAnywayButtonIndex].isLoading = true

        connectAnywayTask?.cancel()
        connectAnywayTask = Task { [weak self] in
            await connectAnywayAction()
            self?.state.buttons[connectAnywayButtonIndex].isLoading = false
        }
    }
}

private extension WalletConnectDAppDomainVerificationViewState {
    static func verifiedDomain(forDAppName dAppName: String) -> WalletConnectDAppDomainVerificationViewState {
        WalletConnectDAppDomainVerificationViewState(
            severity: .verified,
            iconAsset: iconAsset(for: .verified),
            title: title(for: .verified),
            body: Localization.wcAlertVerifiedDomainDescription(dAppName),
            badge: badge(for: .verified),
            buttons: [.done]
        )
    }

    static func domainWarning(_ verificationStatus: WalletConnectDAppVerificationStatus) -> WalletConnectDAppDomainVerificationViewState {
        return WalletConnectDAppDomainVerificationViewState(
            severity: WalletConnectDAppDomainVerificationViewState.Severity(verificationStatus),
            iconAsset: iconAsset(for: verificationStatus),
            title: title(for: verificationStatus),
            body: body(for: verificationStatus),
            badge: badge(for: verificationStatus),
            buttons: [
                .cancel,
                .connectAnyway,
            ]
        )
    }

    private static func iconAsset(for verificationStatus: WalletConnectDAppVerificationStatus) -> ImageType {
        switch verificationStatus {
        case .verified:
            Assets.Glyphs.verified
        case .unknownDomain, .malicious:
            Assets.Glyphs.knightShield
        }
    }

    private static func title(for verificationStatus: WalletConnectDAppVerificationStatus) -> String {
        switch verificationStatus {
        case .verified:
            Localization.wcAlertVerifiedDomainTitle
        case .unknownDomain, .malicious:
            Localization.securityAlertTitle
        }
    }

    private static func body(for verificationStatus: WalletConnectDAppVerificationStatus) -> String {
        switch verificationStatus {
        case .verified:
            return ""

        case .unknownDomain:
            return Localization.wcAlertDomainIssuesDescription

        case .malicious:
            return Localization.wcAlertDomainIssuesDescription
        }
    }

    private static func badge(for verificationStatus: WalletConnectDAppVerificationStatus) -> String? {
        switch verificationStatus {
        case .verified:
            return nil
        case .unknownDomain:
            return Localization.wcAlertAuditUnknownDomain
        case .malicious:
            return Localization.wcAlertAuditMaliciousDomain
        }
    }
}

private extension WalletConnectDAppDomainVerificationViewState.Severity {
    init(_ verificationStatus: WalletConnectDAppVerificationStatus) {
        switch verificationStatus {
        case .verified:
            self = .verified

        case .unknownDomain:
            self = .attention

        case .malicious:
            self = .critical
        }
    }
}
