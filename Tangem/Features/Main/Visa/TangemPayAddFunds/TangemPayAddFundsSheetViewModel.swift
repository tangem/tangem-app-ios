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
    private let tangemPayDestinationWalletWrapper: TangemPayDestinationWalletWrapper
    private weak var coordinator: TangemPayAddFundsSheetRoutable?

    init(input: Input, coordinator: TangemPayAddFundsSheetRoutable) {
        userWalletInfo = input.userWalletInfo
        address = input.address
        tangemPayDestinationWalletWrapper = input.tangemPayDestinationWalletWrapper

        self.coordinator = coordinator
    }

    func userDidTapOption(option: TangemPayAddFundsSheetOptionView.Option) {
        switch option {
        case .swap: openSwap()
        case .receive: openReceiveSheet()
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
        let tangemPayDestinationWalletWrapper: TangemPayDestinationWalletWrapper
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
            destination: tangemPayDestinationWalletWrapper
        )
        coordinator?.addFundsSheetRequestSwap(input: expressInput)
    }
}
