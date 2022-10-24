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

class ExchangeViewModel: ObservableObject {
    @Injected(\.rateAppService) private var rateAppService: RateAppService
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    
    @Published var viewItem: ExchangeViewItem
    
    @Published private var swapInformation: SwapDTO?
    
    let amountType: Amount.AmountType
    let walletModel: WalletModel
    let cardViewModel: CardViewModel
    let blockchainNetwork: BlockchainNetwork
    var bag = Set<AnyCancellable>()
    let exchangeFacade: ExchangeFacade = ExchangeFacadeImpl(enableDebugMode: true)
    
    var timer: Timer? 
    
    init(
        amountType: Amount.AmountType,
        walletModel: WalletModel,
        cardViewModel: CardViewModel,
        blockchainNetwork: BlockchainNetwork
    ) {
        self.amountType = amountType
        self.walletModel = walletModel
        self.cardViewModel = cardViewModel
        self.blockchainNetwork = blockchainNetwork
        self.viewItem = ExchangeViewItem(fromItem: ExchangeItem(isMainToken: true, amountType: amountType, blockchainNetwork: blockchainNetwork),
                                         toItem: ExchangeItem(isMainToken: false, amountType: amountType, blockchainNetwork: blockchainNetwork))
        bind()
    }
    
    func bind() {
        tangemApiService.loadCoins(requestModel: CoinsListRequestModel.init(networkIds: [blockchainNetwork.blockchain.networkId]))
            .sink { error in
                switch error {
                case .finished: break
                case .failure(let error):
                    print(error.localizedDescription)
                }
            } receiveValue: { coinModels in
                for coinModel in coinModels {
                    print(coinModel)
                }
            }
            .store(in: &bag)
    }
    
    /// Change token places
    func swapItems() {
        viewItem = ExchangeViewItem(fromItem: viewItem.toItem, toItem: viewItem.fromItem)
        viewItem.fromItem.fetchApprove(walletAddress: walletModel.wallet.address)
    }
    
    /// Fetch tx data, amount and fee
    func fetchSwapData() {
        Task {
            let swapParameters = SwapParameters(fromTokenAddress: viewItem.fromItem.tokenAddress,
                                                toTokenAddress: viewItem.toItem.tokenAddress,
                                                amount: viewItem.fromItem.amount,
                                                fromAddress: walletModel.wallet.address,
                                                slippage: 1)
            
            let swapResult = await exchangeFacade.swap(blockchain: ExchangeBlockchain.convert(from: blockchainNetwork),
                                                       parameters: swapParameters)
            switch swapResult {
            case .success(let swapResponse):
                swapInformation = swapResponse
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    /// Sign and send swap transaction
    func executeTransaction() {
        let tx = Transaction.dummyTx(blockchain: blockchainNetwork.blockchain, type: amountType, destinationAddress: "") //[REDACTED_TODO_COMMENT]
        
        walletModel
            .walletManager
            .send(tx, signer: cardViewModel.signer)
            .sink { error in
                print(error)
            } receiveValue: { _ in
                print("SUCCESS")
            }
            .store(in: &bag)
    }
}
