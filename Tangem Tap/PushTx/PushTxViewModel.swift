//
//  PushTxViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine

class PushTxViewModel: ViewModel {
    
    weak var navigation: NavigationCoordinator!
    weak var assembly: Assembly!
    weak var ratesService: CoinMarketCapService!
    
    
    var destination: String { transaction.destinationAddress }
    
    var previousTotal: String { getDescription(for: (transaction.amount + transaction.fee), isFiat: isFiatCalculation) }
    
    var currency: String {
        isFiatCalculation ? ratesService.selectedCurrencyCode : transaction.amount.currencySymbol
    }
    
    var walletTotalBalanceDecimals: String {
        let amount = walletModel.wallet.amounts[amountToSend.type]
        return isFiatCalculation ? walletModel.getFiat(for: amount)?.description ?? ""
            : amount?.value.description ?? ""
    }
    
    var walletTotalBalanceFormatted: String {
        let amount = walletModel.wallet.amounts[self.amountToSend.type]
        let value = getDescription(for: amount, isFiat: isFiatCalculation)
        return String(format: "send_balance_subtitle_format".localized, value)
    }
    
    var walletModel: WalletModel {
        cardViewModel.walletModels!.first(where: { $0.wallet.blockchain ==  blockchain })!
    }
    
    var amountToSend: Amount { transaction.amount }
    var previousFeeAmount: Amount { transaction.fee }
    
    @Published var amountHint: TextHint?
    @Published var selectedFeeLevel: Int = 1
    @Published var isFeeLoading: Bool = false
    @Published var isSendEnabled: Bool = false
    @Published var sendError: AlertBinder?
    @Published var canFiatCalculation: Bool = true
    @Published var isFiatCalculation: Bool = false
    @Published var fees: [Amount] = []
    @Published var selectedFee: Amount? = nil
    
    @Published var sendFee: String = ""
    @Published var sendTotal: String = ""
    @Published var sendTotalSubtitle: String = ""
    
    let cardViewModel: CardViewModel
    let blockchain: Blockchain
    
    var emailDataCollector: PushScreenDataCollector!
    var transaction: BlockchainSdk.Transaction
    
    lazy var amountDecimal: String = { "\(walletModel.getFiat(for: amountToSend) ?? 0)" }()
    lazy var amount: String = { transaction.amount.description }()
    lazy var previousFee: String = { transaction.fee.description }()
    
    private var signer: TransactionSigner
    
    private var emptyValue: String {
        getDescription(for: Amount.zeroCoin(for: blockchain), isFiat: isFiatCalculation)
    }
    
    private var bag: Set<AnyCancellable> = []
    
    @Published private var newTransaction: BlockchainSdk.Transaction?
    
    init(transaction: Transaction, blockchain: Blockchain, cardViewModel: CardViewModel, signer: TransactionSigner, ratesService: CoinMarketCapService) {
        self.blockchain = blockchain
        self.cardViewModel = cardViewModel
        self.signer = signer
        self.ratesService = ratesService
        self.transaction = transaction
        sendFee = emptyValue
        sendTotal = emptyValue
        sendTotalSubtitle = emptyValue
        
        bind()
        fillPreviousTxInfo(isFiat: isFiatCalculation)
        loadNewFees()
    }
    
    func send(_ callback: @escaping () -> Void) {
        guard
            let tx = newTransaction,
            let previousTxHash = transaction.hash,
            let pusher = walletModel.walletManager as? TransactionPusher
        else {
            return
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addLoadingView()
        pusher.pushTransaction(with: previousTxHash, newTransaction: tx, signer: signer)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [unowned self] completion in
                appDelegate.removeLoadingView()
                
                if case let .failure(error) = completion {
                    if case .userCancelled = error.toTangemSdkError() {
                        return
                    }
                    Analytics.logCardSdkError(error.toTangemSdkError(), for: .pushTx, card: cardViewModel.cardInfo.card, parameters: [.blockchain: walletModel.wallet.blockchain.displayName])
                    emailDataCollector.lastError = error
                    self.sendError = error.alertBinder
                } else {
                    walletModel.startUpdatingTimer()
                    Analytics.logTx(blockchainName: self.cardViewModel.cardInfo.card.cardData?.blockchainName)
                    callback()
                }
                
            }, receiveValue: { _ in  })
            .store(in: &bag)
    }
    
    private func getDescription(for amount: Amount?, isFiat: Bool) -> String {
        isFiat ?
            walletModel.getFiatFormatted(for: amount) ?? "" :
            amount?.description ?? emptyValue
    }
    
    private func bind() {
        print("\n\nCreating push tx view model subscriptions \n\n")
        
        bag.removeAll()
        
        walletModel
            .$rates
            .map {[unowned self] newRates -> Bool in
                return newRates[self.amountToSend.currencySymbol] != nil
            }
            .assign(to: \.canFiatCalculation, on: self)
            .store(in: &bag)
        
        $isFiatCalculation
            .sink { [unowned self] isFiat in
                self.fillPreviousTxInfo(isFiat: isFiat)
                self.fillTotalBlock(tx: self.newTransaction, isFiat: isFiat)
                self.updateFeeLabel(fee: self.selectedFee, isFiat: isFiat)
            }
            .store(in: &bag)
        
        $selectedFeeLevel
            .map { [unowned self] feeLevel -> Amount? in
                guard self.fees.count > feeLevel else {
                    return nil
                }
                
                let fee = self.fees[feeLevel]
                return fee
            }
            .assign(to: \.selectedFee, on: self)
            .store(in: &bag)
        
        $fees
            .dropFirst()
            .map { [unowned self] in
                guard $0.count > self.selectedFeeLevel else { return nil }
                
                return $0[self.selectedFeeLevel]
            }
            .assign(to: \.selectedFee, on: self)
            .store(in: &bag)
        
        $selectedFee
            .dropFirst()
            .map { [unowned self] fee -> (BlockchainSdk.Transaction?, Amount?) in
                var errorMessage: String?
                defer {
                    self.amountHint = errorMessage == nil ? nil : .init(isError: true, message: errorMessage!)
                }
                
                guard let fee = fee else {
                    errorMessage = BlockchainSdkError.failedToLoadFee.localizedDescription
                    return (nil, fee)
                }
                
                guard fee > self.transaction.fee else {
                    errorMessage = BlockchainSdkError.feeForPushTxNotEnough.localizedDescription
                    return (nil, fee)
                }
                
                let txResult = walletModel.walletManager.createTransaction(amount: self.transaction.amount, fee: fee, destinationAddress: self.destination)
                switch txResult {
                case .success(let tx):
                    return (tx, fee)
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    return (nil, fee)
                }
            }
            .sink(receiveValue: { txFee in
                let tx = txFee.0
                let fee = txFee.1
                self.newTransaction = tx
                self.isSendEnabled = tx != nil
                self.fillTotalBlock(tx: tx, isFiat: self.isFiatCalculation)
                self.updateFeeLabel(fee: fee)
            })
            .store(in: &bag)
    }
    
    private func loadNewFees() {
        guard
            let pusher = walletModel.walletManager as? TransactionPusher,
            let txHash = transaction.hash
        else {
            return
        }
        
        isFeeLoading = true
        pusher.getPushFee(for: txHash)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isFeeLoading = false
                if case .failure(let error) = completion {
                    print("Failed to load fee error: \(error.localizedDescription)")
                    self?.amountHint = .init(isError: true, message: error.localizedDescription)
                }
            }, receiveValue: { [weak self] fees in
                self?.fees = fees
            })
            .store(in: &bag)
    }
    
    private func fillPreviousTxInfo(isFiat: Bool) {
        amount = getDescription(for: amountToSend, isFiat: isFiat)
        amountDecimal = isFiat ? walletModel.getFiat(for: amountToSend)?.description ?? "" : amountToSend.value.description
        previousFee = getDescription(for: previousFeeAmount, isFiat: isFiat)
    }
    
    private func updateFeeLabel(fee: Amount?, isFiat: Bool? = nil) {
        let isFiat = isFiat ?? isFiatCalculation
        if let fee = fee {
            sendFee = getDescription(for: fee, isFiat: isFiat)
        } else {
            sendFee = getDescription(for: Amount.zeroCoin(for: blockchain), isFiat: isFiat)
        }
    }
    
    private func fillTotalBlock(tx: BlockchainSdk.Transaction? = nil, isFiat: Bool) {
        guard let fee = tx?.fee else {
            sendTotal = emptyValue
            sendTotalSubtitle = emptyValue
            return
        }
        
        let totalAmount = transaction.amount + fee
        var totalFiatAmount: Decimal? = nil
        
        if let fiatAmount = self.walletModel.getFiat(for: transaction.amount), let fiatFee = self.walletModel.getFiat(for: fee) {
            totalFiatAmount = fiatAmount + fiatFee
        }
        
        let totalFiatAmountFormatted = totalFiatAmount?.currencyFormatted(code: self.ratesService.selectedCurrencyCode)
        
        if isFiat {
            sendTotal = totalFiatAmountFormatted ?? emptyValue
            sendTotalSubtitle = amountToSend.type == fee.type ?
                String(format: "send_total_subtitle_format".localized, totalAmount.description) :
                String(format: "send_total_subtitle_asset_format".localized,
                       amountToSend.description,
                       fee.description)
        } else {
            sendTotal =  (amountToSend + fee).description
            sendTotalSubtitle = totalFiatAmountFormatted == nil ? emptyValue :  String(format: "send_total_subtitle_fiat_format".localized,
                                                                                       totalFiatAmountFormatted!,
                                                                                       walletModel.getFiatFormatted(for: fee)!)
        }
    }
    
}
