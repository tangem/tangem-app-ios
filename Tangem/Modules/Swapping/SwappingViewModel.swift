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

    @Published var sendCurrencyViewModel: SendCurrencyViewModel
    @Published var receiveCurrencyViewModel: ReceiveCurrencyViewModel
    @Published var isLoading: Bool = false

    @Published var sendDecimalValue: Decimal?

    // MARK: - Dependencies

    private unowned let coordinator: SwappingRoutable

    // MARK: - Private

    private var bag: Set<AnyCancellable> = []

    init(
        coordinator: SwappingRoutable
    ) {
        self.coordinator = coordinator

        // Temp solution, will be changed on Currency input
        sendCurrencyViewModel = SendCurrencyViewModel(
            balance: 3043.75,
            fiatValue: 0,
            tokenIcon: .init(tokenItem: .blockchain(.bitcoin(testnet: false)))
        )
        receiveCurrencyViewModel = ReceiveCurrencyViewModel(
            state: .loaded(0, fiatValue: 0),
            tokenIcon: .init(tokenItem: .blockchain(.polygon(testnet: false))),
            didTapTokenView: {}
        )

        bind()
    }

    func bind() {
        $sendDecimalValue
//            .print()
            .compactMap { $0 }
            .sink {
                self.sendCurrencyViewModel.update(fiatValue: $0 * 2)
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
            .sink {
                self.receiveCurrencyViewModel.updateState(.loaded($0 * 0.5, fiatValue: $0 * 2))
            }
            .store(in: &bag)
    }

    func swapButtonDidTap() {
        withAnimation(.easeInOut(duration: 0.3)) {
            swapCurrencies()
        }
    }

    func swapCurrencies() {
        if receiveCurrencyViewModel.state.value != 0 {
            sendDecimalValue = receiveCurrencyViewModel.state.value
        }

        let sendTokenItem = sendCurrencyViewModel.tokenIcon

        sendCurrencyViewModel = SendCurrencyViewModel(
            balance: Decimal(Int.random(in: 0 ... 100)),
            fiatValue: receiveCurrencyViewModel.state.fiatValue ?? 0,
            tokenIcon: receiveCurrencyViewModel.tokenIcon
        )

        receiveCurrencyViewModel = ReceiveCurrencyViewModel(
            state: .loading,
            tokenIcon: sendTokenItem
        ) {}

        isLoading.toggle()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isLoading.toggle()
        }
    }
}
