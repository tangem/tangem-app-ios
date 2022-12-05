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

    @Published var mainButtonIsEnabled: Bool = false
    @Published var mainButtonTitle: MainButtonAction = .swap

    var informationSectionViewModels: [InformationSectionViewModel] {
        var section: [InformationSectionViewModel] = [.fee(swappingFeeRowViewModel)]
        if let feeWarningRowViewModel {
            section.append(.warning(feeWarningRowViewModel))
        }

        return section
    }

    @Published private var swappingFeeRowViewModel = SwappingFeeRowViewModel(state: .idle)
    @Published private var feeWarningRowViewModel: DefaultWarningRowViewModel?

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

    func userDidTapSwapButton() {}

    func userDidTapChangeDestinationButton() {
        openTokenListView()
    }

    func userDidTapMainButton() {}
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

// MARK: - ExchangeManagerDelegate

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
        case .idle, .requiredRefresh:
            state = .loaded(0, fiatValue: 0)
        case .loading:
            state = .loading
        case let .preview(result),
             let .available(result, _),
             let .requiredPermission(result, _):
            state = .loaded(result.expectAmount, fiatValue: result.expectFiatAmount)
        }

        receiveCurrencyViewModel = ReceiveCurrencyViewModel(
            state: state,
            tokenIcon: destination.asSwappingTokenIconViewModel()
        )
    }

    func updateState(state: TangemExchange.ExchangeAvailabilityState) {
        updateFeeValue(state: state)
        updateMainButton(state: state)

        switch state {
        case .idle:
            refreshWarningRowViewModel = nil
            feeWarningRowViewModel = nil
            receiveCurrencyViewModel?.updateState(.loaded(0, fiatValue: 0))

        case .loading:
            feeWarningRowViewModel = nil
            refreshWarningRowViewModel?.update(detailsType: .loader)
            receiveCurrencyViewModel?.updateState(.loading)

        case let .preview(result),
             let .available(result, _),
             let .requiredPermission(result, _):
            refreshWarningRowViewModel = nil
            feeWarningRowViewModel = nil
            receiveCurrencyViewModel?.updateState(
                .loaded(result.expectAmount, fiatValue: result.expectFiatAmount)
            )

        case .requiredRefresh(let error):
            receiveCurrencyViewModel?.updateState(.loaded(0, fiatValue: 0))
            refreshWarningRowViewModel = DefaultWarningRowViewModel(
                icon: Assets.attention,
                title: "Exchange rate has expired", // [REDACTED_TODO_COMMENT]
                subtitle: error.localizedDescription, // [REDACTED_TODO_COMMENT]
                detailsType: .icon(Assets.refreshWarningIcon),
                action: { [weak self] in
                    self?.exchangeManager.refresh()
                }
            )
        }
    }

    func updateFeeValue(state: ExchangeAvailabilityState) {
        switch state {
        case .idle, .requiredRefresh:
            swappingFeeRowViewModel.update(state: .idle)
        case .loading:
            swappingFeeRowViewModel.update(state: .loading)
        case let .preview(result),
             let .available(result, _),
             let .requiredPermission(result, _):
            swappingFeeRowViewModel.update(
                state: .fee(
                    fee: result.fee.groupedFormatted(maximumFractionDigits: result.decimalCount),
                    symbol: exchangeManager.getExchangeItems().source.symbol,
                    fiat: result.fiatFee.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)
                )
            )
        }
    }

    func updateMainButton(state: ExchangeAvailabilityState) {
        switch state {
        case .idle, .loading, .requiredRefresh:
            mainButtonIsEnabled = false
            mainButtonTitle = .swap

        case let .preview(result),
             let .available(result, _),
             let .requiredPermission(result, _):
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
}

extension SwappingViewModel {
    enum InformationSectionViewModel: Hashable, Identifiable {
        var id: Int { hashValue }

        case fee(SwappingFeeRowViewModel)
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
                return "swapping_swap".localized
            case .insufficientFunds:
                return "swapping_insufficient_funds".localized
            case .givePermission:
                return "swapping_give_permission".localized
            case .permitAndSwap:
                return "swapping_permit_and_swap".localized
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
