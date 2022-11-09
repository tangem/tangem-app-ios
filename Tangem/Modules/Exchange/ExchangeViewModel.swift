//
//  ExchangeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import ExchangeSdk
import SwiftUI

class ExchangeViewModel: ObservableObject {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    @Published var inputAmountText: String = ""
    @Published var outputAmountText: String = ""
    @Published var items: ExchangeItems

    private var exchangeFacade: ExchangeFacade
    private var swapDataModel: ExchangeSwapDataModel?
    private var prefetchedAvailableCoins = [CoinModel]()
    private var bag = Set<AnyCancellable>()

    private var refreshTxDataTimerPublisher = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    private var blockchainNetwork: BlockchainNetwork {
        items.sourceItem.currency.type.blockchainNetwork
    }

    init(currency: ExchangeCurrency, exchangeFacade: ExchangeFacade) {
        self.exchangeFacade = exchangeFacade

        let sourceItem = ExchangeItem(isLockedForChange: true,
                                      currency: currency)

        let destinationItem: ExchangeItem
        switch currency.type {
        case .coin:
            destinationItem = ExchangeItem(isLockedForChange: false,
                                           currency: ExchangeCurrency.daiToken(blockchainNetwork: sourceItem.currency.type.blockchainNetwork))
        case .token:
            destinationItem = ExchangeItem(isLockedForChange: false,
                                           currency: ExchangeCurrency(type: .coin(blockchainNetwork: sourceItem.currency.type.blockchainNetwork)))
        }

        items = ExchangeItems(sourceItem: sourceItem, destinationItem: destinationItem)
        preloadAvailableTokens()
        bind()
    }

    convenience init(blockchainNetwork: BlockchainNetwork, exchangeFacade: ExchangeFacade) {
        let currency = ExchangeCurrency(type: .coin(blockchainNetwork: blockchainNetwork))
        self.init(currency: currency, exchangeFacade: exchangeFacade)
    }
}

// MARK: - Methods

extension ExchangeViewModel {
    /// Change token places
    func onSwapItems() {
        Task {
            items = ExchangeItems(sourceItem: items.destinationItem, destinationItem: items.sourceItem)
            await exchangeFacade.fetchExchangeAmountLimit(for: items.sourceItem)

            resetItemsInput()

            withAnimation {
                self.objectWillChange.send()
            }
        }
    }

    /// Sign and send swap transaction
    func onSwap() {
        guard let swapDataModel else { return }

        Task {
            do {
                _ = try await exchangeFacade.sendSwapTransaction(destinationAddress: swapDataModel.destinationAddress,
                                                                 amount: inputAmountText,
                                                                 gas: "\(swapDataModel.gas)",
                                                                 gasPrice: swapDataModel.gasPrice,
                                                                 txData: swapDataModel.txData,
                                                                 sourceItem: items.sourceItem)
                self.openSuccessView()
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func onApprove() {
        Task {
            do {
                let approveData = try await exchangeFacade.approveTxData(for: items.sourceItem)
                _ = try await exchangeFacade.submitPermissionForToken(destinationAddress: approveData.to,
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
                if value.isEmpty {
                    self?.cancelRefreshTimer()
                }
                self?.onChangeInputAmount()
            }
            .store(in: &bag)

        $inputAmountText
            .sink { [unowned self] value in
                let decimals = Decimal(string: value.replacingOccurrences(of: ",", with: ".")) ?? 0
                let newAmount = self.items.sourceItem.currency.createAmount(with: decimals).value
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
            .sink { completion in
                switch completion {
                case .finished: break
                case .failure(let error):
                    print(error.localizedDescription)
                }
            } receiveValue: { [weak self] coinModels in
                self?.prefetchedAvailableCoins = coinModels
            }
            .store(in: &bag)
    }

    private func resetItemsInput() {
        outputAmountText = ""
        self.onChangeInputAmount()
        withAnimation {
            self.objectWillChange.send()
        }
    }

    private func updateSwapData(_ swapDataModel: ExchangeSwapDataModel) async {
        self.swapDataModel = swapDataModel

        await MainActor.run {
            outputAmountText = swapDataModel.toTokenAmount
            withAnimation {
                self.objectWillChange.send()
            }
        }
    }

    private func onChangeInputAmount() {
        guard !inputAmountText.isEmpty else {
            cancelRefreshTimer()
            outputAmountText = ""
            self.objectWillChange.send()
            return
        }

        cancelRefreshTimer()
        Task {
            do {
                let swapDataModel = try await exchangeFacade.fetchTxDataForSwap(amount: inputAmountText,
                                                                                slippage: 1,
                                                                                items: items)
                await updateSwapData(swapDataModel)

                self.refreshTimer()
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
