//
//  ExchangeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import ExchangeSdk

class ExchangeViewModel: ObservableObject {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    @Published var inputAmountText: String = ""
    @Published private(set) var outputAmountText: String = ""
    @Published var items: ExchangeItems

    private var exchangeFacade: ExchangeFacade
    private var swapDataModel: ExchangeSwapDataModel?
    private var prefetchedAvailableCoins = [CoinModel]()
    private var bag = Set<AnyCancellable>()

    private var refreshTxDataTimerPublisher = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    private var blockchainNetwork: BlockchainNetwork {
        items.sourceItem.currency.blockchainNetwork
    }

    init(exchangeFacade: ExchangeFacade, sourceCurrency: Currency, destinationCurrency: Currency) {
        self.exchangeFacade = exchangeFacade

        let sourceItem = ExchangeItem(isLocked: true,
                                      currency: sourceCurrency)

        let destinationItem = ExchangeItem(isLocked: false,
                                           currency: destinationCurrency)


        items = ExchangeItems(sourceItem: sourceItem, destinationItem: destinationItem)
        preloadAvailableTokens()
        bind()
    }
}

// MARK: - Methods

extension ExchangeViewModel {
    /// Change token places
    func onSwapItems() {
        Task {
            items = ExchangeItems(sourceItem: items.destinationItem, destinationItem: items.sourceItem)
            do {
                try await exchangeFacade.fetchExchangeAmountLimit(for: items.sourceItem)
            } catch {
                print(error.localizedDescription)
            }

            resetItemsInput()
        }
    }

    /// Sign and send swap transaction
    func onSwap() {
        guard let swapDataModel else { return }

        Task {
            do {
                try await exchangeFacade.sendSwapTransaction(destinationAddress: swapDataModel.destinationAddress,
                                                             amount: inputAmountText,
                                                             gas: "\(swapDataModel.gas)",
                                                             gasPrice: swapDataModel.gasPrice,
                                                             txData: swapDataModel.txData,
                                                             sourceItem: items.sourceItem)
                openSuccessView()
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func onApprove() {
        Task {
            do {
                let approveData = try await exchangeFacade.approveTxData(for: items.sourceItem)
                try await exchangeFacade.submitPermissionForToken(destinationAddress: approveData.tokenAddress,
                                                                  gasPrice: approveData.gasPrice,
                                                                  txData: approveData.data,
                                                                  for: items.sourceItem)
                // [REDACTED_TODO_COMMENT]
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
// MARK: - Private

extension ExchangeViewModel {
    private func bind() {
        $inputAmountText
            .debounce(for: 1.0, scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                self?.onChangeInputAmount()
            }
            .store(in: &bag)

        $inputAmountText
            .sink { [unowned self] value in
                let decimals = Decimal(string: value.replacingOccurrences(of: ",", with: ".")) ?? 0
                self.items.sourceItem.currency.updateAmount(decimals)

                let newAmount = self.items.sourceItem.currency.amount
                let formatter = NumberFormatter()
                formatter.numberStyle = .none

                let newValue = formatter.string(for: newAmount) ?? ""

                if newValue != value {
                    self.inputAmountText = newValue
                }
            }
            .store(in: &bag)
    }

    private func preloadAvailableTokens() {
        tangemApiService
            .loadCoins(requestModel: .init(networkIds: [blockchainNetwork.blockchain.networkId], exchangeable: true))
            .sink {
                if case .failure(let error) = $0 {
                    print(error.localizedDescription)
                }
            } receiveValue: { [weak self] coinModels in
                self?.prefetchedAvailableCoins = coinModels
            }
            .store(in: &bag)
    }

    private func resetItemsInput() {
        outputAmountText = "0"
        self.onChangeInputAmount()
    }

    private func updateSwapData(_ swapDataModel: ExchangeSwapDataModel) async {
        self.swapDataModel = swapDataModel

        await MainActor.run {
            outputAmountText = swapDataModel.toTokenAmount
            self.objectWillChange.send()
        }
    }

    private func onChangeInputAmount() {
        guard !inputAmountText.isEmpty else {
            cancelRefreshTimer()
            outputAmountText = "0"
            return
        }

        cancelRefreshTimer()
        Task {
            do {
                let swapDataModel = try await exchangeFacade.fetchTxDataForSwap(amount: inputAmountText,
                                                                                slippage: 1,
                                                                                items: items)
                await updateSwapData(swapDataModel)

                refreshTimer()
            } catch ExchangeInchError.parsedError(let error) {
                print(error.localizedDescription)
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    private func refreshTimer() {
        refreshTxDataTimerPublisher
            .sink { [weak self] _ in
                self?.onChangeInputAmount()
            }
            .store(in: &bag)
    }

    private func cancelRefreshTimer() {
        refreshTxDataTimerPublisher
            .upstream
            .connect()
            .cancel()
    }
}

// MARK: - Coordinator

extension ExchangeViewModel {
    func openTokenList() { } // [REDACTED_TODO_COMMENT]

    func openApproveView() { } // [REDACTED_TODO_COMMENT]

    func openSuccessView() { } // [REDACTED_TODO_COMMENT]
}
