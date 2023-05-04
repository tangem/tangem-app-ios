//
//  SwappingInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSwapping

class SwappingInteractor {
    // MARK: - Public

    public let state = CurrentValueSubject<SwappingAvailabilityState, Never>(.idle)

    // MARK: - Dependencies

    private let swappingManager: SwappingManager
    private let userWalletModel: UserWalletModel
    private let currencyMapper: CurrencyMapping
    private let blockchainNetwork: BlockchainNetwork

    // MARK: - Private

    private var updateStateTask: Task<Void, Error>?

    init(
        swappingManager: SwappingManager,
        userWalletModel: UserWalletModel,
        currencyMapper: CurrencyMapping,
        blockchainNetwork: BlockchainNetwork
    ) {
        self.swappingManager = swappingManager
        self.userWalletModel = userWalletModel
        self.currencyMapper = currencyMapper
        self.blockchainNetwork = blockchainNetwork
    }
}

// MARK: - Public

extension SwappingInteractor {
    func getAvailabilityState() -> SwappingAvailabilityState {
        state.value
    }

    func getSwappingItems() -> SwappingItems {
        swappingManager.getSwappingItems()
    }

    func getReferrerAccountFee() -> Decimal? {
        swappingManager.getReferrerAccount()?.fee
    }

    func update(swappingItems: SwappingItems) async -> SwappingItems {
        AppLog.shared.debug("[Swap] SwappingInteractor will update swappingItems to \(swappingItems)")
        updateState(.idle)
        swappingManager.update(swappingItems: swappingItems)
        return await swappingManager.refreshBalances()
    }

    func update(amount: Decimal?) {
        AppLog.shared.debug("[Swap] SwappingInteractor will update amount to \(amount as Any)")
        swappingManager.update(amount: amount)
        refresh(type: .full)
    }

    func update(approvePolicy: SwappingApprovePolicy) {
        guard swappingManager.getSwappingItems().source.isToken else {
            assertionFailure("Don't call this method if source currency isn't a token")
            return
        }

        swappingManager.update(approvePolicy: approvePolicy)
        refresh(type: .full)
    }

    func refresh(type: SwappingManagerRefreshType) {
        AppLog.shared.debug("[Swap] SwappingInteractor received the request for refresh with \(type)")

        guard let amount = swappingManager.getAmount(), amount > 0 else {
            updateState(.idle)
            return
        }

        AppLog.shared.debug("[Swap] SwappingInteractor start refreshing task")
        updateState(.loading(type))
        updateStateTask = Task {
            await updateState(swappingManager.refresh(type: type))
        }
    }

    func cancelRefresh() {
        guard updateStateTask != nil else {
            return
        }

        AppLog.shared.debug("[Swap] SwappingInteractor cancel the refreshing task")

        updateStateTask?.cancel()
        updateStateTask = nil
    }

    func didSendApproveTransaction(swappingTxData: SwappingTransactionData) {
        swappingManager.didSendApproveTransaction(swappingTxData: swappingTxData)
        refresh(type: .full)
    }

    func didSendSwapTransaction(swappingTxData: SwappingTransactionData) {
        updateState(.idle)
        addDestinationTokenToUserWalletList()
    }
}

// MARK: - Private

private extension SwappingInteractor {
    func updateState(_ state: SwappingAvailabilityState) {
        AppLog.shared.debug("[Swap] SwappingInteractor update state to \(state)")

        self.state.send(state)
    }

    func addDestinationTokenToUserWalletList() {
        guard let destination = getSwappingItems().destination,
              let token = currencyMapper.mapToToken(currency: destination) else {
            return
        }

        let entry = StorageEntry(blockchainNetwork: blockchainNetwork, token: token)
        userWalletModel.append(entries: [entry])
        userWalletModel.updateWalletModels()
    }
}
