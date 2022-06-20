//
//  AppCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class AppCoordinator: CoordinatorObject {
    //MARK: - Child coordinators
    @Published var pushedOnboardingCoordinator: OnboardingCoordinator? = nil
    @Published var modalOnboardingCoordinator: OnboardingCoordinator? = nil
    @Published var shopCoordinator: ShopCoordinator? = nil
    @Published var tokenListCoordinator: TokenListCoordinator? = nil
    @Published var sendCoordinator: SendCoordinator? = nil
    @Published var pushTxCoordinator: PushTxCoordinator? = nil
    
    //MARK: - Child view models
    @Published var welcomeViewModel: WelcomeViewModel!
    @Published var mailViewModel: MailViewModel? = nil
    @Published var disclaimerViewModel: DisclaimerViewModel? = nil
    @Published var mainViewModel: MainViewModel? = nil
    @Published var detailsViewModel: DetailsViewModel? = nil
    @Published var modalWebViewModel: WebViewContainerViewModel? = nil
    @Published var pushedWebViewModel: WebViewContainerViewModel? = nil
    @Published var tokenDetailsViewModel: TokenDetailsViewModel? = nil
    @Published var currencySelectViewModel: CurrencySelectViewModel? = nil
    @Published var addressQrBottomSheetContentViewVodel: AddressQrBottomSheetContentViewVodel? = nil
    @Published var walletConnectViewModel: WalletConnectViewModel? = nil
    @Published var cardOperationViewModel: CardOperationViewModel? = nil
    @Published var secManagementViewModel: SecurityManagementViewModel? = nil
    @Published var qrScanViewModel: QRScanViewModel? = nil
    
    //MARK: - Other view bindings
    @Published var safariURL: URL? = nil
    
    //MARK: - Helpers
    @Published var modalOnboardingCoordinatorKeeper: Bool = false
    @Published var qrBottomSheetKeeper: Bool = false
    
    var dismissAction: () -> Void = {}
    
    //MARK: - Private
    private var welcomeLifecycleSubscription: AnyCancellable? = nil
    
    init() {}
    
    func start(withScan: Bool = false) {
        welcomeViewModel = .init(coordinator: self)
        subscribeToWelcomeLifecycle()
        
        if withScan {
            welcomeViewModel.scanCard()
        }
    }
    
    func hideQrBottomSheet() {
        qrBottomSheetKeeper.toggle()
    }
    
    func popToRoot() {
        dismiss()
    }
    
    private func subscribeToWelcomeLifecycle() {
        let p1 = $mailViewModel.dropFirst().map { $0 == nil ? true : false }
        let p2 = $disclaimerViewModel.dropFirst().map { $0 == nil ? true : false }
        let p3 = $shopCoordinator.dropFirst().map { $0 == nil ? true : false }
        let p4 = $modalOnboardingCoordinator.dropFirst().map { $0 == nil ? true : false }
        
        welcomeLifecycleSubscription = p1.merge(with: p2, p3, p4)
            .sink {[unowned self] viewDismissed in
                if viewDismissed {
                    self.welcomeViewModel.becomeActive()
                } else {
                    self.welcomeViewModel.resignActve()
                }
            }
    }
}
