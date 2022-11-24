//
//  ExchangeManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public protocol ExchangeManager {
    func availableNetworks() -> [String]
    func getExchangeItems() -> ExchangeItems
//    func update(exchangeItems: ExchangeItems)

    func stopTimer()
    func refreshTimer()
}

class CommonExchangeManager {
    // MARK: - Dependencies
    private let provider: ExchangeProvider

    // MARK: - Internal
    private lazy var refreshTxDataTimerPublisher = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    private var exchangeItems: ExchangeItems

    private var bag: Set<AnyCancellable> = []

    init(provider: ExchangeProvider, exchangeItems: ExchangeItems) {
        self.provider = provider
        self.exchangeItems = exchangeItems
    }
}

// MARK: - Private

private extension CommonExchangeManager {

}

// MARK: - ExchangeManager

extension CommonExchangeManager: ExchangeManager {
    func getExchangeItems() -> ExchangeItems {
        return exchangeItems
    }

    func refreshTimer() {
        refreshTxDataTimerPublisher
            .sink { [weak self] _ in
//                self?.onChangeInputAmount()
                // [REDACTED_TODO_COMMENT]
            }
            .store(in: &bag)
    }

    func stopTimer() {
        refreshTxDataTimerPublisher
            .upstream
            .connect()
            .cancel()
    }

//    func getExchangeNetworkId() -> String {
//        exchangeItems.to.blockchainNetwork.id
//    }
//
//    func update(exchangeItems: ExchangeItems) {
//        self.exchangeItems = exchangeItems
//        // [REDACTED_TODO_COMMENT]
//    }
//
//    /// Change token places
//    func onSwapItems() {
//        Task {
//            items = ExchangeItems(sourceItem: items.destinationItem, destinationItem: items.sourceItem)
//            do {
//                try await exchangeFacade.fetchExchangeAmountLimit(for: items.sourceItem)
//            } catch {
//                print(error.localizedDescription)
//            }
//
//            resetItemsInput()
//        }
//    }
//
//    /// Sign and send swap transaction
//    func onSwap() {
//        guard let swapDataModel else { return }
//
//        Task {
//            do {
//                try await exchangeFacade.sendSwapTransaction(destinationAddress: swapDataModel.destinationAddress,
//                                                             amount: inputAmountText,
//                                                             gas: "\(swapDataModel.gas)",
//                                                             gasPrice: swapDataModel.gasPrice,
//                                                             txData: swapDataModel.txData,
//                                                             sourceItem: items.sourceItem)
//                openSuccessView()
//            } catch {
//                print(error.localizedDescription)
//            }
//        }
//    }
//
//    func onApprove() {
//        Task {
//            do {
//                let approveData = try await exchangeFacade.approveTxData(for: items.sourceItem)
//                try await exchangeFacade.submitPermissionForToken(destinationAddress: approveData.tokenAddress,
//                                                                  gasPrice: approveData.gasPrice,
//                                                                  txData: approveData.data,
//                                                                  for: items.sourceItem)
//                // [REDACTED_TODO_COMMENT]
//            } catch {
//                print(error.localizedDescription)
//            }
//        }
//    }
}
