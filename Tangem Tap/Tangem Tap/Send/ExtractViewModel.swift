//
//  ExtractViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import EFQRCode
import BlockchainSdk

struct TextHint {
    let isError: Bool
    let message: String
}

//enum CurrencyUnit {
//    case crypto(symbol: String)
//    case fiat(symbol: String)
//}

class ExtractViewModel: ObservableObject {
    //MARK: Navigation
    @Published var showQR = false
    
    //MARK: Input
    @Published var validatedClipboard: String? = nil
    @Published var destination: String = ""
    @Published var amountText: String = "0"
    @Published var isFiatCalculation: Bool = false
    @Published var isFeeIncluded: Bool = true
    @Published var selectedFeeLevel: Int = 1
    @Published var maxAmountTapped: Bool = false
    @Published var fees: [Amount] = []
    
    //MARK: UI
    var shoudShowFeeSelector: Bool {
        return txSender.allowsFeeSelection
    }
    
    var shoudShowFeeIncludeSelector: Bool {
        return amountToSend.type == .coin
    }
    
    var shouldShowNetworkBlock: Bool  {
        return shoudShowFeeSelector || shoudShowFeeIncludeSelector
    }
    
    @Published var isNetworkFeeBlockOpen: Bool = false
    
    //MARK: Output
    @Published var destinationHint: TextHint? = nil
    @Published var amountHint: TextHint? = nil
    @Published var sendAmount: String = ""
    @Published var sendFee: String = ""
    @Published var sendTotal: String = ""
    @Published var sendTotalSubtitle: String = ""
    @Published var isSendEnabled: Bool = false
    @Published var selectedFee: Amount? = nil
    @Published var transaction: BlockchainSdk.Transaction? = nil
    
    @Binding var sdkService: TangemSdkService
    @Binding var cardViewModel: CardViewModel {
        didSet {
            bind()
        }
    }
    
    var currencyUnit: String {
        return isFiatCalculation ? self.cardViewModel.selectedFiat.rawValue : self.amountToSend.currencySymbol
    }
    
    var walletTotalBalanceDecimals: String {
        let amount = cardViewModel.wallet?.amounts[self.amountToSend.type]
        return isFiatCalculation ? self.cardViewModel.getFiat(for: amount)?.description ?? ""
            : amount?.value.description ?? ""
    }
    
    var walletTotalBalanceFormatted: String {
        let amount = cardViewModel.wallet?.amounts[self.amountToSend.type]
        let value = isFiatCalculation ? self.cardViewModel.getFiatFormatted(for: amount) ?? ""
            : amount?.description ?? ""
        return String(format: "send_balance_subtitle_format".localized, value)
    }
    
    //MARK: Private
    @Published private var validatedDestination: String? = nil
    @Published private var amountValidated: Bool = false
    private var validatedTag: String? = nil
    private var bag = Set<AnyCancellable>()
    @Published private var amountToSend: Amount
    private var txSender: TransactionSender {
        cardViewModel.walletManager as! TransactionSender
    }
    
    
    
    init(amountToSend: Amount, cardViewModel: Binding<CardViewModel>, sdkSerice: Binding<TangemSdkService>) {
        self._sdkService = sdkSerice
        self._cardViewModel = cardViewModel
        self.amountToSend = amountToSend
        bind()
    }
    
    func bind() {
        bag = Set<AnyCancellable>()
        
        cardViewModel.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [unowned self] in
                self.objectWillChange.send()
        }
        .store(in: &bag)
        
        $destination //destination validation
            .throttle(for: 0.3, scheduler: RunLoop.main, latest: true)
            .sink{ [unowned self] newText in
                print(newText)
                self.validateDestination(newText)
        }
        .store(in: &bag)
        
        $maxAmountTapped //handle max amount tap
            .dropFirst()
            .sink { [unowned self] _ in
                self.amountToSend = self.cardViewModel.wallet!.amounts[self.amountToSend.type]!
                self.amountText = self.walletTotalBalanceDecimals
        }
        .store(in: &bag)
        
        $amountText //handle amount input
            .throttle(for: 0.3, scheduler: RunLoop.main, latest: true)
            .sink{ [unowned self] newAmount in
                guard let decimals = Decimal(string: newAmount.replacingOccurrences(of: ",", with: ".")) else {
                    self.amountToSend.value = 0
                    return
                }
                
                self.amountToSend.value = self.isFiatCalculation ? self.cardViewModel.getCrypto(for: decimals, currencySymbol: self.amountToSend.currencySymbol) ?? 0 : decimals
        }
        .store(in: &bag)
        
        $amountToSend //amount validation
            .sink {[unowned self] newAmount in
                if newAmount.value == 0 {
                    self.amountHint = nil
                    self.amountValidated = false
                    return
                }
                
                if !self.cardViewModel.walletManager!.validate(amount: newAmount) {
                    self.amountValidated = false
                    self.amountHint = TextHint(isError: true, message: "send_validation_invalid_amount".localized)
                } else {
                    self.amountValidated = true
                    self.amountHint = nil
                }
        }
        .store(in: &bag)
        
        $selectedFee //update fee label
            .sink{ [unowned self] newAmount in
                self.sendFee = self.isFiatCalculation ?
                    self.cardViewModel.getFiatFormatted(for: newAmount) ?? ""
                    : newAmount?.description ?? ""
        }
        .store(in: &bag)
        
        
        $isFiatCalculation //handle conversion
            .sink { [unowned self] value in
                self.amountText = value ? self.cardViewModel.getFiat(for: self.amountToSend)?.description ?? ""
                    : self.amountToSend.value.description
        }
        .store(in: &bag)
        
        $transaction //update total block
            .sink { [unowned self] tx in
                if let tx = tx {
                    self.isSendEnabled = true
                    let totalAmount = tx.amount + tx.fee
                    let totalFiatAmount = self.cardViewModel.getFiatFormatted(for: totalAmount)
                    if self.isFiatCalculation {
                        self.sendAmount = self.cardViewModel.getFiatFormatted(for: tx.amount) ?? ""
                        self.sendTotal = totalFiatAmount ?? ""
                        self.sendTotalSubtitle = tx.amount.type == tx.fee.type ?
                            String(format: "send_total_subtitle_format".localized, totalAmount.description) :
                            String(format: "send_total_subtitle_asset_format".localized,
                                   tx.amount.description,
                                   tx.fee.description)
                    } else {
                        self.sendAmount = tx.amount.description
                        self.sendTotal = totalAmount.description
                        self.sendTotalSubtitle = totalFiatAmount == nil ? "" : "~\(totalFiatAmount!)"
                    }
                    
                } else {
                    self.sendAmount = ""
                    self.sendTotal = ""
                    self.sendTotalSubtitle = ""
                    self.isSendEnabled = false
                }
        }
        .store(in: &bag)
        
        $amountValidated //update fee
            .filter { $0 }
            .map {[unowned self] _ in  self.amountToSend}
            .combineLatest($validatedDestination.compactMap { $0 })
            .throttle(for: 0.3, scheduler: RunLoop.main, latest: true)
            .flatMap {[unowned self] in
                self.txSender.getFee(amount: $0, destination: $1)
                    .catch{ error -> Just<[Amount]> in
                        print(error)
                        return Just([Amount]())
                }
                .subscribe(on: DispatchQueue.global())}
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { [unowned self] completion in
            self.fees = []
            }, receiveValue: {[unowned self] fees in
                self.fees = fees
        })
            .store(in: &bag)
        
        
        $fees //handle fee selection
            .combineLatest($selectedFeeLevel)
            .throttle(for: 0.3, scheduler: RunLoop.main, latest: true)
            .sink{ [unowned self] fees, level in
                if fees.isEmpty {
                    self.selectedFee = nil
                } else {
                    self.selectedFee = fees.count > 1 ? fees[self.selectedFeeLevel] : fees.first!
                }
        }
        .store(in: &bag)
        
        
        $amountValidated
            .filter { $0 }
            .map {[unowned self] _ in self.amountToSend}
            .combineLatest($validatedDestination.compactMap { $0 },
                           $selectedFee.compactMap{ $0 },
                           $isFeeIncluded)
            .throttle(for: 0.3, scheduler: RunLoop.main, latest: true)
            .map {[unowned self] amount, destination, fee, isFeeIncluded -> BlockchainSdk.Transaction? in
                let result = self.cardViewModel.walletManager!.createTransaction(amount: isFeeIncluded ? amount - fee : amount,
                                                                                 fee: fee,
                                                                                 destinationAddress: destination)
                switch result {
                case .success(let tx):
                    return tx
                case .failure(let error):
                    //[REDACTED_TODO_COMMENT]
                    return nil
                }
        }.sink{[unowned self] tx in
            self.transaction = tx
        }
        .store(in: &bag)
    }
    
    func onAppear() {
        validateClipboard()
    }
    
    func validateClipboard() {
        validatedClipboard = nil
        
        guard let input = UIPasteboard.general.string else {
            return
        }
        
        if cardViewModel.payIDService?.validate(input) ?? false || validateAddress(input) {
            validatedClipboard = input
        }
    }
    
    func validateAddress(_ address: String) -> Bool {
        return cardViewModel.wallet!.blockchain.validate(address: address)
            && address != cardViewModel.wallet!.address
    }
    
    
    func validateDestination(_ destination: String) {
        validatedDestination = nil
        validatedTag = nil
        destinationHint = nil
        
        if destination.isEmpty {
            return
        }
        
        if let payIdService = cardViewModel.payIDService,
            payIdService.validate(destination) {
            payIdService.resolve(destination) {[weak self] result in
                switch result {
                case .success(let resolvedDetails):
                    if let address = resolvedDetails.address,
                        self?.validateAddress(address) ?? false {
                        self?.validatedDestination = resolvedDetails.address
                        self?.validatedTag = resolvedDetails.tag
                        self?.destinationHint = TextHint(isError: false,
                                                         message: address)
                    } else {
                        self?.destinationHint = TextHint(isError: true,
                                                         message: "send_validation_invalid_address".localized)
                    }
                case .failure(let error):
                    self?.destinationHint = TextHint(isError: true,
                                                     message: error.localizedDescription)
                }
            }
            
        } else {
            if validateAddress(destination) {
                validatedDestination = destination
            } else {
                destinationHint = TextHint(isError: true,
                                           message: "send_validation_invalid_address".localized)
            }
        }
    }
    
    func pasteClipboardTapped() {
        if let validatedClipboard = self.validatedClipboard {
            destination = validatedClipboard
        }
    }
    
    func stripBlockchainPrefix(_ string: String) -> String {
        if let qrPrefix = cardViewModel.wallet?.blockchain.qrPrefix {
            return string.remove(qrPrefix)
        } else {
            return string
        }
    }
    
    func send() {
        guard let tx = self.transaction else {
            return
        }
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addLoadingView()
        //[REDACTED_TODO_COMMENT]
        txSender.send(tx, signer: sdkService.tangemSdk)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [unowned self] completion in
                appDelegate.removeLoadingView()
                if case let .failure(error) = completion {
                    //[REDACTED_TODO_COMMENT]
                    //dismiss
                    
                }
                }, receiveValue: {_ in
                    //[REDACTED_TODO_COMMENT]
                    //dismiss
                    //show tx inc/outg
            })
            .store(in: &bag)
    }
}


//ссообщение при попытке отправит транзакцию
//подкраска ошибок и ккак вообще показать
//детальный видЖ входящие транзакции
