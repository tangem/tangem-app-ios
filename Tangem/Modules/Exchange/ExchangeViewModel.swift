//
//  ExchangeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExchange

class ExchangeViewModel: ObservableObject {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

//    [REDACTED_USERNAME] var inputAmountText: String = ""
//    [REDACTED_USERNAME] private(set) var outputAmountText: String = ""
//    [REDACTED_USERNAME] var items: ExchangeItems

//    private var exchangeFacade: ExchangeProvider
    private let exchangeManager: ExchangeManager
//    private var swapDataModel: ExchangeSwapDataModel?

    // [REDACTED_TODO_COMMENT]
    private var prefetchedAvailableCoins = [CoinModel]()
    private var bag = Set<AnyCancellable>()

//    private var refreshTxDataTimerPublisher = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    private let router: ExchangeRoutable
//    private var blockchainNetwork: BlockchainNetwork {
//        items.sourceItem.currency.blockchainNetwork
//    }

    // , sourceCurrency: Currency, destinationCurrency: Currency
    init(router: ExchangeRoutable, exchangeManager: ExchangeManager) {
        self.router = router
        self.exchangeManager = exchangeManager
//
//        let sourceItem = ExchangeItem(isLocked: true,
//                                      currency: sourceCurrency)
//
//        let destinationItem = ExchangeItem(isLocked: false,
//                                           currency: destinationCurrency)
//
//
//        items = ExchangeItems(sourceItem: sourceItem, destinationItem: destinationItem)
        preloadAvailableTokens()
//        bind()
    }
}

// MARK: - Methods

extension ExchangeViewModel {

}
// MARK: - Private

extension ExchangeViewModel {

    // [REDACTED_TODO_COMMENT]
//    private func bind() {
//        $inputAmountText
//            .debounce(for: 1.0, scheduler: DispatchQueue.main)
//            .sink { [weak self] value in
//                self?.onChangeInputAmount()
//            }
//            .store(in: &bag)
//
//        $inputAmountText
//            .sink { [unowned self] value in
//                let decimals = Decimal(string: value.replacingOccurrences(of: ",", with: ".")) ?? 0
//                self.items.sourceItem.currency.updateAmount(decimals)
//
//                let newAmount = self.items.sourceItem.currency.amount
//                let formatter = NumberFormatter()
//                formatter.numberStyle = .none
//
//                let newValue = formatter.string(for: newAmount) ?? ""
//
//                if newValue != value {
//                    self.inputAmountText = newValue
//                }
//            }
//            .store(in: &bag)
//    }

    private func preloadAvailableTokens() {
        tangemApiService
            .loadCoins(requestModel: .init(networkIds: [exchangeManager.getExchangeItems().source.networkId], exchangeable: true))
            .sink {
                if case .failure(let error) = $0 {
                    print(error.localizedDescription)
                }
            } receiveValue: { [weak self] coinModels in
                self?.prefetchedAvailableCoins = coinModels
            }
            .store(in: &bag)
    }
//
//    private func resetItemsInput() {
//        outputAmountText = "0"
//        self.onChangeInputAmount()
//    }
//
//    private func updateSwapData(_ swapDataModel: ExchangeSwapDataModel) async {
//        self.swapDataModel = swapDataModel
//
//        await MainActor.run {
//            outputAmountText = swapDataModel.toTokenAmount
//            self.objectWillChange.send()
//        }
//    }
//
//    private func onChangeInputAmount() {
//        guard !inputAmountText.isEmpty else {
//            cancelRefreshTimer()
//            outputAmountText = "0"
//            return
//        }
//
//        cancelRefreshTimer()
//        Task {
//            do {
//                let swapDataModel = try await exchangeFacade.fetchTxDataForSwap(amount: inputAmountText,
//                                                                                slippage: 1,
//                                                                                items: items)
//                await updateSwapData(swapDataModel)
//
//                refreshTimer()
//            } catch ExchangeInchError.parsedError(let error) {
//                print(error.localizedDescription)
//            } catch {
//                print(error.localizedDescription)
//            }
//        }
//    }
}

// MARK: - Coordinator

extension ExchangeViewModel {
    func openTokenList() { } // [REDACTED_TODO_COMMENT]

    func openApproveView() { } // [REDACTED_TODO_COMMENT]

    func openSuccessView() { } // [REDACTED_TODO_COMMENT]
}
