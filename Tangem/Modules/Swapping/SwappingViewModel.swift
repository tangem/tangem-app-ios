//
//  SwappingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class SwappingViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var sendCurrencyViewModel: SendCurrencyViewModel?
    @Published var receiveCurrencyViewModel: ReceiveCurrencyViewModel?
    @Published var isLoading: Bool = false

    @Published var sendDecimalValue: Decimal?
    @Published var refreshWarningRowViewModel: DefaultWarningRowViewModel?
    @Published var informationSectionViewModels: [InformationSectionViewModel] = []
    @Published var mainButtonIsEnabled: Bool = false

    // MARK: - Dependencies

    private unowned let coordinator: SwappingRoutable

    // MARK: - Private

    private var bag: Set<AnyCancellable> = []

    init(
        coordinator: SwappingRoutable
    ) {
        self.coordinator = coordinator

        setupView()
        bind()
    }

    func userDidTapSwapButton() {
        withAnimation(.easeInOut(duration: 0.3)) {
            swapCurrencies()
        }
    }

    func userDidTapChangeDestinationButton() {
        openTokenListView()
    }

    func userDidTapMainButton() {
        if Bool.random() {
            openSuccessView()
        } else {
            openPermissionView()
        }
    }
}

// MARK: - Navigation

private extension SwappingViewModel {
    func openTokenListView() {
        coordinator.presentExchangeableTokenListView(networkIds: ["ethereum"])
    }

    func openSuccessView() {
        coordinator.presentSuccessView(fromCurrency: "ETH", toCurrency: "USDT")
    }

    func openPermissionView() {
        let inputModel = SwappingPermissionViewModel.InputModel(
            smartContractNetworkName: "DAI",
            amount: 1000,
            yourWalletAddress: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
            spenderWalletAddress: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
            fee: 2.14
        )
        coordinator.presentPermissionView(inputModel: inputModel)
    }
}

private extension SwappingViewModel {
    func setupView() {
        // Temp solution, will be changed on Currency input
        sendCurrencyViewModel = SendCurrencyViewModel(
            balance: 3043.75,
            maximumFractionDigits: 8,
            fiatValue: 0,
            tokenIcon: .init(tokenItem: .blockchain(.bitcoin(testnet: false))),
            tokenSymbol: "BTC"
        )

        receiveCurrencyViewModel = ReceiveCurrencyViewModel(
            state: .loaded(0, fiatValue: 0),
            tokenIcon: .init(tokenItem: .blockchain(.polygon(testnet: false))),
            tokenSymbol: "MATIC",
            didTapTokenView: { [weak self] in self?.userDidTapChangeDestinationButton() }
        )

        refreshWarningRowViewModel = DefaultWarningRowViewModel(
            icon: Assets.attention,
            title: "Exchange rate has expired",
            subtitle: "Recalculate route",
            detailsType: .icon(Assets.refreshWarningIcon),
            action: {}
        )

        informationSectionViewModels = [
            .fee(DefaultRowViewModel(
                title: "Fee",
                detailsType: .text("0.155 MATIC (0.14 $)")
            )),
            .warning(DefaultWarningRowViewModel(
                icon: Assets.attention,
                title: nil,
                subtitle: "Not enough funds for fee on your Polygon wallet to create a transaction. Top up your Polygon wallet first.",
                action: {}
            )),
        ]
    }

    func bind() {
        $sendDecimalValue
            .compactMap { $0 }
            .sink { [weak self] in
                self?.sendCurrencyViewModel?.update(fiatValue: $0 * 2)
            }
            .store(in: &bag)

        $sendDecimalValue
            .map { ($0 ?? 0) > 0 }
            .sink { [weak self] in
                self?.mainButtonIsEnabled = $0
            }
            .store(in: &bag)

//        $sendCurrencyValueText
//            .dropFirst()
//            .removeDuplicates()
//            .debounce(for: 0.5, scheduler: DispatchQueue.main)
//            .sink { _ in
//                self.receiveCurrencyViewModel.updateState(.loading)
//            }
//            .store(in: &bag)

        $sendDecimalValue
            .compactMap { $0 }
//            .delay(for: 1, scheduler: DispatchQueue.main)
            .sink { [weak self] in
                self?.receiveCurrencyViewModel?.updateState(.loaded($0 * 0.5, fiatValue: $0 * 2))
            }
            .store(in: &bag)
    }

    func swapCurrencies() {
        guard let receiveCurrencyViewModel, let sendCurrencyViewModel else { return }

        if receiveCurrencyViewModel.state.value != 0 {
            sendDecimalValue = receiveCurrencyViewModel.state.value
        }

        let sendTokenItem = sendCurrencyViewModel.tokenIcon
        let sendTokenSymbol = sendCurrencyViewModel.tokenSymbol

        self.sendCurrencyViewModel = SendCurrencyViewModel(
            balance: Decimal(Int.random(in: 0 ... 100)),
            maximumFractionDigits: 8,
            fiatValue: receiveCurrencyViewModel.state.fiatValue ?? 0,
            tokenIcon: receiveCurrencyViewModel.tokenIcon,
            tokenSymbol: receiveCurrencyViewModel.tokenSymbol
        )

        self.receiveCurrencyViewModel = ReceiveCurrencyViewModel(
            state: .loading,
            tokenIcon: sendTokenItem,
            tokenSymbol: sendTokenSymbol
        ) {}

        isLoading.toggle()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isLoading.toggle()
        }
    }
}

extension SwappingViewModel {
    enum InformationSectionViewModel: Hashable, Identifiable {
        var id: Int { hashValue }

        case fee(DefaultRowViewModel)
        case warning(DefaultWarningRowViewModel)
    }
}
