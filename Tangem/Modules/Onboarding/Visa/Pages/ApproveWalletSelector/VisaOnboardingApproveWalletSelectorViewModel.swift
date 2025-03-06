//
//  VisaOnboardingApproveWalletSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemVisa

protocol VisaOnboardingRemoteStateProvider: AnyObject {
    func loadCurrentRemoteState() async throws -> VisaCardActivationRemoteState
}

protocol VisaOnboardingApproveWalletSelectorDelegate: VisaOnboardingAlertPresenter {
    func useExternalWallet()
    func useTangemWallet()
    @MainActor
    func proceedFromCurrentRemoteState() async
}

final class VisaOnboardingApproveWalletSelectorViewModel: ObservableObject {
    @Published private(set) var isLoadingRemoteState: Bool = false
    @Published private(set) var selectedOption: VisaOnboardingApproveWalletSelectorItemView.Option = .tangemWallet

    let instructionNotificationInput: NotificationViewInput = .init(
        style: .plain,
        severity: .info,
        settings: .init(event: VisaNotificationEvent.onboardingAccountActivationInfo, dismissAction: nil)
    )

    private weak var remoteStateProvider: VisaOnboardingRemoteStateProvider?
    private weak var delegate: VisaOnboardingApproveWalletSelectorDelegate?

    init(
        remoteStateProvider: VisaOnboardingRemoteStateProvider?,
        delegate: VisaOnboardingApproveWalletSelectorDelegate?
    ) {
        self.remoteStateProvider = remoteStateProvider
        self.delegate = delegate
    }

    func selectOption(_ option: VisaOnboardingApproveWalletSelectorItemView.Option) {
        selectedOption = option
    }

    func continueAction() {
        switch selectedOption {
        case .tangemWallet:
            delegate?.useTangemWallet()
        case .otherWallet:
            delegate?.useExternalWallet()
        }
    }
}
