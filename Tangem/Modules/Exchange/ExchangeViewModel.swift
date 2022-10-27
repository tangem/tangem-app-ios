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
import Exchanger
import BigInt

class ExchangeViewModel: ObservableObject {
    @Injected(\.rateAppService) private var rateAppService: RateAppService
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    @Published var items: ExchangeItems
    @Published private var swapInformation: SwapDTO?

    let amountType: Amount.AmountType
    let walletModel: WalletModel
    let card: CardViewModel
    let blockchainNetwork: BlockchainNetwork

    var bag = Set<AnyCancellable>()
    var prefetchedAvailableCoins: [CoinModel] = []

    private let exchangeFacade: ExchangeFacade = ExchangeFacadeImpl(enableDebugMode: true)
    private let signer: ExchangeSigner = ExchangeSigner()

    private lazy var exchangeInteractor: ExchangeTxInteractor = ExchangeTxInteractor(walletModel: walletModel, card: card)

    private var transactionProcessor: EthereumTransactionProcessor {
        walletModel.walletManager as! EthereumTransactionProcessor
    }

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
        self.items = ExchangeItems(fromItem: ExchangeItem(isMainToken: true, amountType: amountType, blockchainNetwork: blockchainNetwork),
                                   toItem: ExchangeItem(isMainToken: false, amountType: amountType, blockchainNetwork: blockchainNetwork))
        preloadAvailableTokens()
        bind()
    }

    /// Change token places
    func onSwapItems() {
        items = ExchangeItems(fromItem: items.toItem, toItem: items.fromItem)
        items.fromItem.fetchApprove(walletAddress: walletModel.wallet.address)
    }

    /// Fetch tx data, amount and fee
    func onChangeInputAmount() {
        Task {
            let swapParameters = SwapParameters(fromTokenAddress: items.fromItem.tokenAddress,
                                                toTokenAddress: items.toItem.tokenAddress,
                                                amount: items.fromItem.amount,
                                                fromAddress: walletModel.wallet.address,
                                                slippage: 1)

            let swapResult = await exchangeFacade.swap(blockchain: ExchangeBlockchain.convert(from: blockchainNetwork), parameters: swapParameters)

            switch swapResult {
            case .success(let swapResponse):
                swapInformation = swapResponse
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }

    /// Sign and send swap transaction
    func onSwap() {
        guard let swapInformation else { return }

        exchangeInteractor
            .sendSwapTransaction(info: swapInformation)
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
                let approveData = try await items.fromItem.approveTxData()
                
                exchangeInteractor
                    .sendApproveTransaction(info: approveData)
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
                    }.store(in: &bag)
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    // MARK: - Private

    /// Spender address
    private func getSpender() async throws -> String {
        let blockchain = ExchangeBlockchain.convert(from: blockchainNetwork)

        let spender = await exchangeFacade.spender(blockchain: blockchain)

        switch spender {
        case .failure(let error):
            throw error
        case .success(let spenderDTO):
            return spenderDTO.address
        }
    }

    private func preloadAvailableTokens() {
        tangemApiService
            .loadCoins(requestModel: .init(networkIds: [blockchainNetwork.blockchain.networkId],
                                           exchange: true))
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
            .fromItem
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
