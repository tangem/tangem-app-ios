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
    @Injected(\.exchangeOneInchService) private var exchangeService: ExchangeServiceProtocol
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    @Published var items: ExchangeItems
    @Published private var swapData: SwapData?

    let amount: Amount
    let walletModel: WalletModel
    let card: CardViewModel
    let blockchainNetwork: BlockchainNetwork

    private var prefetchedAvailableCoins = [CoinModel]()
    private var bag = Set<AnyCancellable>()

    private lazy var exchangeInteractor = ExchangeTxInteractor(walletModel: walletModel, card: card)

    private var userWalletModel: UserWalletModel? {
        card.userWalletModel
    }

    init(
        amount: Amount,
        walletModel: WalletModel,
        cardViewModel: CardViewModel,
        blockchainNetwork: BlockchainNetwork
    ) {
        self.amount = amount
        self.walletModel = walletModel
        self.card = cardViewModel
        self.blockchainNetwork = blockchainNetwork

        let fromItem = ExchangeItem(isMainToken: true,
                                    amount: amount,
                                    blockchainNetwork: blockchainNetwork)

        let toItem = ExchangeItem(isMainToken: false,
                                  amount: amount,
                                  blockchainNetwork: blockchainNetwork)

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
        exchangeInteractor.fetchApprove(for: items.sourceItem)
    }

    /// Fetch tx data, amount and fee
    func onChangeInputAmount() {
        Task {
            let swapParameters = SwapParameters(fromTokenAddress: items.sourceItem.tokenAddress,
                                                toTokenAddress: items.destinationItem.tokenAddress,
                                                amount: items.sourceItem.amountText,
                                                fromAddress: walletModel.wallet.address,
                                                slippage: 1)

            let swapResult = await exchangeService.swap(blockchain: ExchangeBlockchain.convert(from: blockchainNetwork),
                                                        parameters: swapParameters)

            switch swapResult {
            case .success(let swapResponse):
                swapData = swapResponse

                await MainActor.run {
                    items.destinationItem.amountText = swapResponse.toTokenAmount
                }
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
                let approveData = try await exchangeInteractor.approveTxData(for: items.sourceItem)

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
    private func bind() {
        items
            .sourceItem
            .$amountText
            .debounce(for: 1.0, scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.onChangeInputAmount()
            }
            .store(in: &bag)
    }

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
}

// MARK: - Coordinator

extension ExchangeViewModel {
    func openTokenList() { } // [REDACTED_TODO_COMMENT]

    func openApproveView() { } // [REDACTED_TODO_COMMENT]

    func openSuccessView() { } // [REDACTED_TODO_COMMENT]
}
