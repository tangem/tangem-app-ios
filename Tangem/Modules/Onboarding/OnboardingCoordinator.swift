//
//  OnboardingCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class OnboardingCoordinator: CoordinatorObject {    
    //MARK: - View models
    @Published var singleCardViewModel: SingleCardOnboardingViewModel? = nil
    @Published var twinsViewModel: TwinsOnboardingViewModel? = nil
    @Published var walletViewModel: WalletOnboardingViewModel? = nil
    @Published var buyCryptoModel: WebViewContainerViewModel? = nil
    @Published var accessCodeModel: OnboardingAccessCodeViewModel? = nil
    @Published var addressQrBottomSheetContentViewVodel: AddressQrBottomSheetContentViewVodel? = nil
    
    //MARK: - Helpers
    @Published var qrBottomSheetKeeper: Bool = false
    
    var dismissAction: () -> Void = {}
    
    //For non-dismissable presentation
    var onDismissalAttempt: () -> Void = {}
    
    func start(with input: OnboardingInput) {
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
    
    func hideQrBottomSheet() {
        qrBottomSheetKeeper.toggle()
    }
}

extension OnboardingCoordinator: OnboardingTopupRoutable {
    func openCryptoShop(at url: URL, closeUrl: String, action: @escaping (String) -> Void) {
        buyCryptoModel = .init(url: url,
                               title: "wallet_button_topup".localized,
                               addLoadingIndicator: true,
                               withCloseButton: true, urlActions: [closeUrl : {[weak self] response in
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
        accessCodeModel = .init(successHandler: {[weak self] code in
            self?.accessCodeModel = nil
            callback(code)
        })
    }
}
