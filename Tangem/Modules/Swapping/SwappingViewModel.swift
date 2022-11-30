//
//  SwappingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import TangemExchange

final class SwappingViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var sendCurrencyViewModel: SendCurrencyViewModel?
    @Published var receiveCurrencyViewModel: ReceiveCurrencyViewModel?
    @Published var isLoading: Bool = false

    @Published var sendDecimalValue: Decimal?
    @Published var refreshWarningRowViewModel: DefaultWarningRowViewModel?
    @Published var informationSectionViewModels: [InformationSectionViewModel] = []
    @Published var mainButtonIsEnabled: Bool = false
    @Published var mainButtonTitle: MainButtonAction = .swap

    // MARK: - Dependencies

    private let exchangeManager: ExchangeManager
    private unowned let coordinator: SwappingRoutable

    // MARK: - Private

    private var bag: Set<AnyCancellable> = []

    init(
        exchangeManager: ExchangeManager,
        coordinator: SwappingRoutable
    ) {
        self.exchangeManager = exchangeManager
        self.coordinator = coordinator

        setupView()
        bind()
        exchangeManager.setDelegate(self)
    }

    func userDidTapSwapButton() {
//        withAnimation(.easeInOut(duration: 0.3)) {
//        swapCurrencies()
//        }
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
        coordinator.presentExchangeableTokenListView(
            networkIds: exchangeManager.getNetworksAvailableToExchange()
        )
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

extension SwappingViewModel: ExchangeManagerDelegate {
    func exchangeManagerDidUpdate(availabilityState: TangemExchange.ExchangeAvailabilityState) {
        DispatchQueue.main.async {
            self.updateState(state: availabilityState)
        }
    }

    func exchangeManagerDidUpdate(availabilityForExchange isAvailable: Bool, limit: Decimal?) {
        DispatchQueue.main.async {
            self.mainButtonTitle = isAvailable ? .swap : .givePermission
            self.sendCurrencyViewModel?.update(isLockedVisible: !isAvailable)
        }
    }

    func exchangeManagerDidUpdate(exchangeItems: TangemExchange.ExchangeItems) {
        DispatchQueue.main.async {
            self.updateView(exchangeItems: exchangeItems)
        }
    }
}

// MARK: - View updates

private extension SwappingViewModel {
    func updateView(exchangeItems: TangemExchange.ExchangeItems) {
        let source = exchangeItems.source
        let destination = exchangeItems.destination

        sendCurrencyViewModel = SendCurrencyViewModel(
            balance: exchangeItems.sourceBalance.balance,
            maximumFractionDigits: source.decimalCount,
            fiatValue: exchangeItems.sourceBalance.fiatBalance,
            isLockedVisible: !exchangeManager.isAvailableForExchange(),
            tokenIcon: source.asSwappingTokenIconViewModel()
        )

        let state: ReceiveCurrencyViewModel.State

        switch exchangeManager.getAvailabilityState() {
        case .loading:
            state = .loading
        case .idle, .available, .requiredPermission, .requiredRefresh:
            if let destinationBalance = exchangeItems.destinationBalance {
                state = .loaded(destinationBalance.balance, fiatValue: destinationBalance.fiatBalance)
            } else {
                state = .loaded(0, fiatValue: 0)
            }
        }

        receiveCurrencyViewModel = ReceiveCurrencyViewModel(
            state: state,
            tokenIcon: destination.asSwappingTokenIconViewModel()
        )
    }

    func updateState(state: TangemExchange.ExchangeAvailabilityState) {
        switch state {
        case .idle:
            mainButtonIsEnabled = false
            refreshWarningRowViewModel = nil
            informationSectionViewModels = [
                .fee(DefaultRowViewModel(title: "Fee", detailsType: .text(""))),
            ]

        case .loading:
            mainButtonIsEnabled = false
            receiveCurrencyViewModel?.updateState(.loading)
            refreshWarningRowViewModel?.update(detailsType: .loader)
            informationSectionViewModels = [
                .fee(DefaultRowViewModel(title: "Fee", detailsType: .loader)),
            ]

        case .available(let result):
            mainButtonIsEnabled = true
            refreshWarningRowViewModel = nil

            informationSectionViewModels = [
                .fee(DefaultRowViewModel(title: "Fee", detailsType: .text(result.fee.groupedFormatted()))),
            ]

        case .requiredPermission(let result):
            mainButtonIsEnabled = true
            refreshWarningRowViewModel = nil
            receiveCurrencyViewModel?.updateState(
                .loaded(result.expectAmount, fiatValue: result.expectFiatAmount)
            )

            let fee = result.fee.groupedFormatted(maximumFractionDigits: result.decimalCount)
            informationSectionViewModels = [
                .fee(DefaultRowViewModel(title: "Fee", detailsType: .text(fee))),
            ]

        case .requiredRefresh(let error):
            mainButtonIsEnabled = false
            receiveCurrencyViewModel?.updateState(.loaded(0, fiatValue: 0))
            informationSectionViewModels = [
                .fee(DefaultRowViewModel(title: "Fee", detailsType: .text("-"))),
            ]
            refreshWarningRowViewModel = DefaultWarningRowViewModel(
                icon: Assets.attention,
                title: "Exchange rate has expired",
                subtitle: error.localizedDescription, //  "Recalculate route"
                detailsType: .icon(Assets.refreshWarningIcon),
                action: {}
            )
        }
    }

    func updateMainButton(state: ExchangeAvailabilityState) {
        switch state {
        case .idle, .loading, .requiredRefresh:
            mainButtonIsEnabled = false

        case .available(let result):
            mainButtonIsEnabled = true

        case .requiredPermission(let result):
            mainButtonIsEnabled = result.isEnoughAmountForExchange
            if result.isEnoughAmountForExchange {
                mainButtonTitle = .givePermission
            } else {
                mainButtonTitle = .insufficientFunds
            }
        }
    }

    func setupView() {
        updateState(state: .idle)
        updateView(exchangeItems: exchangeManager.getExchangeItems())

//        informationSectionViewModels = [
//            .fee(DefaultRowViewModel(
//                title: "Fee",
//                detailsType: .text("0.155 MATIC (0.14 $)")
//            )),
//            .warning(DefaultWarningRowViewModel(
//                icon: Assets.attention,
//                title: nil,
//                subtitle: "Not enough funds for fee on your Polygon wallet to create a transaction. Top up your Polygon wallet first.",
//                action: {}
//            )),
//        ]
    }

    func bind() {
        $sendDecimalValue
            .removeDuplicates()
            .dropFirst()
            .debounce(for: 1, scheduler: DispatchQueue.global())
            .sink { [unowned self] amount in
                self.exchangeManager.update(amount: amount)
            }
            .store(in: &bag)
    }

    /*
        func swapCurrencies() {
            guard let receiveCurrencyViewModel, let sendCurrencyViewModel else { return }

            if receiveCurrencyViewModel.state.value != 0 {
                sendDecimalValue = receiveCurrencyViewModel.state.value
            }

            let sendTokenItem = sendCurrencyViewModel.tokenIcon

            self.sendCurrencyViewModel = SendCurrencyViewModel(
                balance: Decimal(Int.random(in: 0 ... 100)),
                maximumFractionDigits: 8,
                fiatValue: receiveCurrencyViewModel.state.fiatValue ?? 0,
                tokenIcon: receiveCurrencyViewModel.tokenIcon
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
     */
}

extension SwappingViewModel {
    enum InformationSectionViewModel: Hashable, Identifiable {
        var id: Int { hashValue }

        case fee(DefaultRowViewModel)
        case warning(DefaultWarningRowViewModel)
    }

    enum MainButtonAction: Hashable, Identifiable {
        var id: Int { hashValue }

        case swap
        case insufficientFunds
        case givePermission
        case permitAndSwap

        var title: String {
            switch self {
            case .swap:
                return "Swap"
            case .insufficientFunds:
                return "Insufficient funds"
            case .givePermission:
                return "Give permission"
            case .permitAndSwap:
                return "Permit and Swap"
            }
        }

        var icon: MainButton.Icon? {
            switch self {
            case .swap, .permitAndSwap:
                return .trailing(Assets.tangemIconWhite)
            case .givePermission, .insufficientFunds:
                return .none
            }
        }
    }
}

private extension Currency {
    func asSwappingTokenIconViewModel() -> SwappingTokenIconViewModel {
        switch currencyType {
        case .coin:
            return SwappingTokenIconViewModel(
                imageURL: TokenIconURLBuilder().iconURL(id: blockchain.id),
                tokenSymbol: symbol
            )
        case .token:
            return SwappingTokenIconViewModel(
                imageURL: TokenIconURLBuilder().iconURL(id: id),
                networkURL: TokenIconURLBuilder().iconURL(id: blockchain.id, size: .small),
                tokenSymbol: symbol
            )
        }
    }
}
