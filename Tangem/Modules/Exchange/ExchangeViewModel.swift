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

class ExchangeViewModel: ObservableObject {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    @Published var items: ExchangeItems
    @Published private var swapData: SwapData?

    let amountType: Amount.AmountType
    let walletModel: WalletModel
    let card: CardViewModel
    let blockchainNetwork: BlockchainNetwork

    private let exchangeService = ExchangeSdk.buildOneInchExchangeService(isDebug: false)
    private var prefetchedAvailableCoins = [CoinModel]()
    private var bag = Set<AnyCancellable>()

    private lazy var exchangeInteractor = ExchangeTxInteractor(walletModel: walletModel, card: card)

    private var userWalletModel: UserWalletModel? {
        card.userWalletModel
    }

    init(
        amountType: Amount.AmountType,
        walletModel: WalletModel,
        cardViewModel: CardViewModel,
        blockchainNetwork: BlockchainNetwork
    ) {
        self.amountType = amountType
        self.walletModel = walletModel
        self.card = cardViewModel
        self.blockchainNetwork = blockchainNetwork

        let fromItem = ExchangeItem(isMainToken: true,
                                    amountType: amountType,
                                    blockchainNetwork: blockchainNetwork,
                                    exchangeService: exchangeService)

        let toItem = ExchangeItem(isMainToken: false,
                                  amountType: amountType,
                                  blockchainNetwork: blockchainNetwork,
                                  exchangeService: exchangeService)

        self.items = ExchangeItems(sourceItem: fromItem, destinationItem: toItem)
        preloadAvailableTokens()
        bind()
    }
}

// MARK: - Methods

extension ExchangeViewModel {
    /// Change token places
    func onSwapItems() {
        items = ExchangeItems(sourceItem: items.destinationItem, destinationItem: items.sourceItem)
        items.sourceItem.fetchApprove(walletAddress: walletModel.wallet.address)
    }

    /// Fetch tx data, amount and fee
    func onChangeInputAmount() {
        Task {
            let swapParameters = SwapParameters(fromTokenAddress: items.sourceItem.tokenAddress,
                                                toTokenAddress: items.destinationItem.tokenAddress,
                                                amount: items.sourceItem.amount,
                                                fromAddress: walletModel.wallet.address,
                                                slippage: 1)

            let swapResult = await exchangeService.swap(blockchain: ExchangeBlockchain.convert(from: blockchainNetwork), parameters: swapParameters)

            switch swapResult {
            case .success(let swapResponse):
                swapData = swapResponse
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }

    /// Sign and send swap transaction
    func onSwap() {
        guard let swapData else { return }

        exchangeInteractor
            .sendSwapTransaction(swapData: swapData)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    print(error.localizedDescription)
                case .finished:
                    break
                }
            }) { [weak self] _ in
                guard let self else { return }

                self.openSuccessView()
            }
            .store(in: &bag)
    }

    func onApprove() {
        Task {
            do {
                let approveData = try await items.sourceItem.approveTxData()

                exchangeInteractor
                    .sendApprovedTransaction(approveData: approveData)
                    .sink { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            print(error.localizedDescription)
                        }
                    } receiveValue: { [weak self] _ in
                        guard let self else { return }
                        // [REDACTED_TODO_COMMENT]
                    }
                    .store(in: &bag)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
// MARK: - Private

extension ExchangeViewModel {
    /// Spender address
    private func getSpender() async throws -> String {
        let blockchain = ExchangeBlockchain.convert(from: blockchainNetwork)

        let spender = await exchangeService.spender(blockchain: blockchain)

        switch spender {
        case .failure(let error):
            throw error
        case .success(let spender):
            return spender.address
        }
    }

    private func preloadAvailableTokens() {
        tangemApiService
            .loadCoins(requestModel: .init(networkIds: [blockchainNetwork.blockchain.networkId], exchange: true))
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

    private func bind() {
        items
            .sourceItem
            .$amount
            .debounce(for: 1.0, scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.onChangeInputAmount()
            }
            .store(in: &bag)
    }
}

// MARK: - Coordinator

extension ExchangeViewModel {
    func openTokenList() { } // [REDACTED_TODO_COMMENT]

    func openApproveView() { } // [REDACTED_TODO_COMMENT]

    func openSuccessView() { } // [REDACTED_TODO_COMMENT]
}
