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
import TangemPay

final class TangemPayAddFundsSheetViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Published private(set) var options: [TangemPayAddFundsSheetOptionView.Option]

    private let userWalletInfo: UserWalletInfo
    private let address: String
    private let swapParameters: PredefinedSwapParameters
    private let networks: [TangemPayBalance.Network]

    private weak var coordinator: TangemPayAddFundsSheetRoutable?

    init(input: Input, coordinator: TangemPayAddFundsSheetRoutable) {
        userWalletInfo = input.userWalletInfo
        address = input.address
        swapParameters = input.swapParameters
        networks = input.networks

        options = (input.isBankTransferAvailable ? [.bankTransfer] : []) + [.swap, .receive]

        self.coordinator = coordinator

        if options.contains(.bankTransfer) {
            Analytics.log(.visaVATopupButtonShowed, contextParams: .userWallet(userWalletInfo.id))
        }
    }

    func userDidTapOption(option: TangemPayAddFundsSheetOptionView.Option) {
        switch option {
        case .swap:
            Analytics.log(.visaScreenButtonVisaSwap, analyticsSystems: .all, contextParams: .userWallet(userWalletInfo.id))
            openSwap()

        case .receive:
            Analytics.log(.visaScreenButtonVisaReceive, analyticsSystems: .all, contextParams: .userWallet(userWalletInfo.id))
            if FeatureProvider.isAvailable(.tangemPayMultichain), !TangemPayNetworkRowResolver.resolve(networks).isEmpty {
                openChooseNetworkSheet()
            } else {
                openReceiveSheet()
            }

        case .bankTransfer:
            Analytics.log(.visaVATopupButtonClicked, contextParams: .userWallet(userWalletInfo.id))
            coordinator?.addFundsSheetRequestBankTransfer()
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
        let swapParameters: PredefinedSwapParameters
        let isBankTransferAvailable: Bool
        let networks: [TangemPayBalance.Network]
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
                )
            ),
            receiveTokenWithdrawNoticeInteractor: TangemPayReceiveTokenWithdrawNoticeInteractor()
        )
        receiveViewModel.start()
        coordinator?.addFundsSheetRequestReceive(viewModel: receiveViewModel)
    }

    func openChooseNetworkSheet() {
        coordinator?.addFundsSheetRequestChooseNetwork(networks: networks)
    }

    func openSwap() {
        coordinator?.addFundsSheetRequestSwap(input: swapParameters)
    }
}
