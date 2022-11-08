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
    private var swapData: SwapData?

    let currency: ExchangeCurrency
    let exchangeManager: ExchangeManager
    let signer: TangemSigner

    private var prefetchedAvailableCoins = [CoinModel]()
    private var bag = Set<AnyCancellable>()

    private var exchangeFacade: ExchangeFacade

    private var blockchainNetwork: BlockchainNetwork {
        exchangeManager.blockchainNetwork
    }

    init(
        currency: ExchangeCurrency,
        exchangeManager: ExchangeManager,
        signer: TangemSigner
    ) {
        self.exchangeManager = exchangeManager
        self.signer = signer
        self.currency = currency
        self.exchangeFacade = ExchangeFacade(exchangeManager: exchangeManager, signer: signer)

        let sourceItem = ExchangeItem(isLockedForChange: true,
                                      currency: currency)

        let destinationItem: ExchangeItem
        switch currency.type {
        case .coin:
            destinationItem = ExchangeItem(isLockedForChange: false,
                                           currency: ExchangeCurrency.daiToken(exchangeManager: exchangeManager))
        case .token:
            destinationItem = ExchangeItem(isLockedForChange: false,
                                           currency: ExchangeCurrency(type: .coin(blockchainNetwork: exchangeManager.blockchainNetwork)))
        }

        items = ExchangeItems(sourceItem: sourceItem, destinationItem: destinationItem)
        preloadAvailableTokens()
        bind()
    }

    convenience init(exchangeManager: ExchangeManager,
                     signer: TangemSigner) {
        let currency = ExchangeCurrency(type: .coin(blockchainNetwork: exchangeManager.blockchainNetwork))
        self.init(currency: currency, exchangeManager: exchangeManager, signer: signer)
    }
}

// MARK: - Methods

extension ExchangeViewModel {
    /// Change token places
    func onSwapItems() {
        Task {
            items = ExchangeItems(sourceItem: items.destinationItem, destinationItem: items.sourceItem)
            await exchangeFacade.fetchApprove(for: items.sourceItem)

            resetItemsInput()
            
            withAnimation {
                self.objectWillChange.send()
            }
        }
    }

    /// Fetch tx data, amount and fee
    func onChangeInputAmount() {
        let swapParameters = SwapParameters(fromTokenAddress: items.sourceItem.tokenAddress,
                                            toTokenAddress: items.destinationItem.tokenAddress,
                                            amount: inputAmountText,
                                            fromAddress: exchangeManager.walletAddress,
                                            slippage: 1)

        Task {
            do {
                let swapData = try await exchangeFacade.fetchSwapData(parameters: swapParameters, items: items)
                await updateSwapData(swapData)
            } catch ExchangeInchError.parsedError(let error) {
                print(error.localizedDescription)
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    /// Sign and send swap transaction
    func onSwap() {
        guard let swapData else { return }

        Task {
            do {
                _ = try await exchangeFacade.sendSwapTransaction(swapData: swapData, sourceItem: items.sourceItem)
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
                _ = try await exchangeFacade.sendApprovedTransaction(approveData: approveData, for: items.sourceItem)
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
            .sink { [weak self] _ in
                self?.onChangeInputAmount()
            }
            .store(in: &bag)

        $inputAmountText
            .sink { [unowned self] value in
                let decimals = Decimal(string: value.replacingOccurrences(of: ",", with: ".")) ?? 0
                let newAmount = currency.createAmount(with: decimals).value
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
        inputAmountText = ""
        outputAmountText = ""
        withAnimation {
            self.objectWillChange.send()
        }
    }

    private func updateSwapData(_ swapData: SwapData) async {
        self.swapData = swapData
        
        await MainActor.run {
            outputAmountText = swapData.toTokenAmount
            withAnimation {
                self.objectWillChange.send()
            }
        }
    }
}

// MARK: - Coordinator

extension ExchangeViewModel {
    func openTokenList() { } // [REDACTED_TODO_COMMENT]

    func openApproveView() { } // [REDACTED_TODO_COMMENT]

    func openSuccessView() { } // [REDACTED_TODO_COMMENT]
}
