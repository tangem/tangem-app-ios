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
    @Published var mainButtonTitle: String = "Swap"

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
        exchangeManager.update(amount: 0.5)
    }

    func userDidTapSwapButton() {
//        withAnimation(.easeInOut(duration: 0.3)) {
        swapCurrencies()
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

extension SwappingViewModel: ExchangeManagerDelegate {
    func exchangeManagerDidUpdate(availabilityState: TangemExchange.SwappingAvailabilityState) {
        DispatchQueue.main.async {
            self.updateState(state: availabilityState)
        }
    }

    func exchangeManagerDidUpdate(swappingModel: TangemExchange.ExchangeSwapDataModel) {

    }

    func exchangeManagerDidUpdate(exchangeItems: TangemExchange.ExchangeItems) {
        updateView(exchangeItems: exchangeItems)
    }
}

private extension SwappingViewModel {
    func updateView(exchangeItems: TangemExchange.ExchangeItems) {
        let source = exchangeItems.source
        let destination = exchangeItems.destination

        sendCurrencyViewModel = SendCurrencyViewModel(
            balance: exchangeItems.sourceBalance.balance,
            maximumFractionDigits: source.decimalCount,
            fiatValue: exchangeItems.sourceBalance.fiatBalance,
            tokenIcon: source.asTokenIconViewModel(),
            tokenSymbol: source.symbol
        )

        var state: ReceiveCurrencyViewModel.State = .loaded(0, fiatValue: 0)
        if let destinationBalance = exchangeItems.destinationBalance {
            state = .loaded(destinationBalance.balance, fiatValue: destinationBalance.fiatBalance)
        }

        receiveCurrencyViewModel = ReceiveCurrencyViewModel(
            state: state,
            tokenIcon: destination.asTokenIconViewModel(),
            tokenSymbol: destination.symbol) { [weak self] in
                self?.userDidTapChangeDestinationButton()
            }
    }

    func updateState(state: TangemExchange.SwappingAvailabilityState) {
        switch state {
        case .idle:
            refreshWarningRowViewModel = nil
            informationSectionViewModels = [
                .fee(DefaultRowViewModel(title: "Fee", detailsType: .text("0"))),
            ]

        case .loading:
            refreshWarningRowViewModel?.update(detailsType: .loader)
            informationSectionViewModels = [
                .fee(DefaultRowViewModel(title: "Fee", detailsType: .loader)),
            ]
        case .available(let swappingData):
            refreshWarningRowViewModel = nil
            let fee = swappingData.gas.description + swappingData.gasPrice

            informationSectionViewModels = [
                .fee(DefaultRowViewModel(title: "Fee", detailsType: .text(fee))),
            ]

        case .requiredPermission:
            refreshWarningRowViewModel = nil

        case .requiredRefresh:
            refreshWarningRowViewModel = DefaultWarningRowViewModel(
                icon: Assets.attention,
                title: "Exchange rate has expired",
                subtitle: "Recalculate route",
                detailsType: .icon(Assets.refreshWarningIcon),
                action: {}
            )
        }
    }

    func setupView() {
        updateView(exchangeItems: exchangeManager.getExchangeItems())
        updateState(state: .loading)

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
//        $sendDecimalValue
//            .compactMap { $0 }
//            .sink { [weak self] in
//                self?.sendCurrencyViewModel?.update(fiatValue: $0 * 2)
//            }
//            .store(in: &bag)

//        $sendDecimalValue
//            .map { ($0 ?? 0) > 0 }
//            .sink { [weak self] in
//                self?.mainButtonIsEnabled = $0
//            }
//            .store(in: &bag)

        $sendDecimalValue
            .dropFirst()
            .compactMap { $0 }
            .removeDuplicates()
            .debounce(for: 0.5, scheduler: DispatchQueue.global())
            .sink { [unowned self] amount in
                self.exchangeManager.update(amount: amount)
            }
            .store(in: &bag)

//        $sendDecimalValue
//            .compactMap { $0 }
//            .delay(for: 1, scheduler: DispatchQueue.main)
//            .sink { [weak self] in
//                self?.receiveCurrencyViewModel?.updateState(.loaded($0 * 0.5, fiatValue: $0 * 2))
//            }
//            .store(in: &bag)
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

private extension Currency {
    func asTokenIconViewModel() -> TokenIconViewModel {
        let style: TokenIconViewModel.Style

        if isToken, let blockchainIconURL {
            style = .tokenCoinIconURL(blockchainIconURL)
        } else {
            style = .blockchain
        }

        return TokenIconViewModel(id: networkId, name: name, style: style)
    }
}
