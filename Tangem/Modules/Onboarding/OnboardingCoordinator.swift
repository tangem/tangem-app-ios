//
//  OnboardingCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class OnboardingCoordinator: CoordinatorObject {
    var dismissAction: Action
    var popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Main view models
    @Published private(set) var singleCardViewModel: SingleCardOnboardingViewModel? = nil
    @Published private(set) var twinsViewModel: TwinsOnboardingViewModel? = nil
    @Published private(set) var walletViewModel: WalletOnboardingViewModel? = nil

    // MARK: - Child coordinators
    @Published var mainCoordinator: MainCoordinator? = nil

    // MARK: - Child view models
    @Published var buyCryptoModel: WebViewContainerViewModel? = nil
    @Published var accessCodeModel: OnboardingAccessCodeViewModel? = nil
    @Published var addressQrBottomSheetContentViewVodel: AddressQrBottomSheetContentViewVodel? = nil

    // For non-dismissable presentation
    var onDismissalAttempt: () -> Void = {}

    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: OnboardingCoordinator.Options) {
        let input = options.input
        switch input.steps {
        case .singleWallet:
            let model = SingleCardOnboardingViewModel(input: input, coordinator: self)
            onDismissalAttempt = model.backButtonAction
            singleCardViewModel = model
        case .twins:
            let model = TwinsOnboardingViewModel(input: input, coordinator: self)
            onDismissalAttempt = model.backButtonAction
            twinsViewModel = model
        case .wallet:
            let model = WalletOnboardingViewModel(input: input, coordinator: self)
            onDismissalAttempt = model.backButtonAction
            walletViewModel = model
        }
    }
}

extension OnboardingCoordinator {
    struct Options {
        let input: OnboardingInput
    }
}

extension OnboardingCoordinator: OnboardingTopupRoutable {
    func openCryptoShop(at url: URL, closeUrl: String, action: @escaping (String) -> Void) {
        buyCryptoModel = .init(url: url,
                               title: "wallet_button_topup".localized,
                               addLoadingIndicator: true,
                               withCloseButton: true, urlActions: [closeUrl: { [weak self] response in
                                   DispatchQueue.main.async {
                                       action(response)
                                       self?.buyCryptoModel = nil
                                   }
                               }])
    }

    func openQR(shareAddress: String, address: String, qrNotice: String) {
        addressQrBottomSheetContentViewVodel = .init(shareAddress: shareAddress, address: address, qrNotice: qrNotice)
    }
}

extension OnboardingCoordinator: WalletOnboardingRoutable {
    func openAccessCodeView(callback: @escaping (String) -> Void) {
        accessCodeModel = .init(successHandler: { [weak self] code in
            self?.accessCodeModel = nil
            callback(code)
        })
    }
}

extension OnboardingCoordinator: OnboardingRoutable {
    func closeOnboarding() {
        dismiss()
    }
}
