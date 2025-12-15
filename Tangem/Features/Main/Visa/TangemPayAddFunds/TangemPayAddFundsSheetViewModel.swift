//
//  TangemPayAddFundsSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemUI
import TangemVisa

final class TangemPayAddFundsSheetViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Published private(set) var options: [TangemPayAddFundsSheetOptionView.Option] = [.swap, .receive]

    private let userWalletInfo: UserWalletInfo
    private let address: String
    private let tangemPayWalletWrapper: ExpressInteractorTangemPayWalletWrapper
    private weak var coordinator: TangemPayAddFundsSheetRoutable?

    init(input: Input, coordinator: TangemPayAddFundsSheetRoutable) {
        userWalletInfo = input.userWalletInfo
        address = input.address
        tangemPayWalletWrapper = input.tangemPayWalletWrapper

        self.coordinator = coordinator
    }

    func userDidTapOption(option: TangemPayAddFundsSheetOptionView.Option) {
        switch option {
        case .swap:
            Analytics.log(.visaScreenButtonVisaSwap)
            openSwap()

        case .receive:
            Analytics.log(.visaScreenButtonVisaReceive)
            openReceiveSheet()
        }
    }

    func close() {
        coordinator?.closeAddFundsSheet()
    }
}

extension TangemPayAddFundsSheetViewModel {
    struct Input {
        let userWalletInfo: UserWalletInfo
        let address: String
        let tangemPayWalletWrapper: ExpressInteractorTangemPayWalletWrapper
    }
}

extension TangemPayAddFundsSheetViewModel {
    func openReceiveSheet() {
        let receiveViewModel = ReceiveMainViewModel(
            options: .init(
                tokenItem: TangemPayUtilities.usdcTokenItem,
                flow: .crypto,
                addressTypesProvider: TangemPayReceiveAddressTypesProvider(
                    address: address,
                    colorScheme: .whiteBlack
                ),
                isYieldModuleActive: false
            )
        )
        receiveViewModel.start()
        coordinator?.addFundsSheetRequestReceive(viewModel: receiveViewModel)
    }

    func openSwap() {
        let expressInput = ExpressDependenciesDestinationInput(
            userWalletInfo: userWalletInfo,
            source: .loadingAndSet,
            destination: tangemPayWalletWrapper
        )
        coordinator?.addFundsSheetRequestSwap(input: expressInput)
    }
}
