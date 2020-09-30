//
//  SendViewModel.swift
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
import TangemSdk

struct TextHint {
    let isError: Bool
    let message: String
}

class SendViewModel: ObservableObject {
    //MARK: Navigation
    @Published var showQR = false
    @Published var showCameraDeniedAlert = false
    
    //MARK: Input
    @Published var validatedClipboard: String? = nil
    @Published var destination: String = ""
    @Published var amountText: String = "0"
    @Published var isFiatCalculation: Bool = false
    @Published var isFeeIncluded: Bool = false
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
    @Published var sendTotal: String = ""
    @Published var sendFee: String = ""
    @Published var sendTotalSubtitle: String = ""
    @Published var isSendEnabled: Bool = false
    @Published var selectedFee: Amount? = nil
    @Published var transaction: BlockchainSdk.Transaction? = nil
    @Published var canFiatCalculation: Bool = true
    @Published var oldCardAlert: AlertBinder?
    @Published var isFeeLoading: Bool = false
    
    @Published var sendError: AlertBinder?
    @Binding var sdkService: TangemSdkService
    @Binding var cardViewModel: CardViewModel {
        didSet {
            bind()
        }
    }
    
    var currencyUnit: String {
        return isFiatCalculation ? self.cardViewModel.selectedCurrency: self.amountToSend.currencySymbol
    }
    
    var walletTotalBalanceDecimals: String {
        guard let wallet = cardViewModel.wallet else {
            return ""
        }
        
        let amount = wallet.amounts[self.amountToSend.type]
        return isFiatCalculation ? self.cardViewModel.getFiat(for: amount)?.description ?? ""
            : amount?.value.description ?? ""
    }
    
    var walletTotalBalanceFormatted: String {
        let amount = cardViewModel.wallet?.amounts[self.amountToSend.type]
        let value = getDescription(for: amount)
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
        if let wallet = self.cardViewModel.wallet {
            let feeDummyAmount = Amount(with: wallet.blockchain,
                                        address: wallet.address,
                                        type: .coin,
                                        value: 0)
           self.sendFee = getDescription(for: selectedFee ?? feeDummyAmount)
        }

        self.canFiatCalculation = self.cardViewModel.hasRates(for: amountToSend)
        fillTotalBlockWithDefaults()
        bind()
    }
    
    private func getDescription(for amount: Amount?) -> String {
        return isFiatCalculation ? self.cardViewModel.getFiatFormatted(for: amount) ?? ""
            : amount?.description ?? ""
    }
    
    private func fillTotalBlockWithDefaults() {
        //let sendDummyAmount = Amount(with: self.amountToSend, value: 0)
        self.sendAmount = "-" //getDescription(for: sendDummyAmount)
        self.sendTotal = "-" // amountToSend.type == .coin ? getDescription(for: sendDummyAmount) : "-"
        self.sendTotalSubtitle = ""
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
            .debounce(for: 1.0, scheduler: RunLoop.main, options: nil)
            .sink{ [unowned self] newText in
                self.validateDestination(newText)
        }
        .store(in: &bag)
        
        $maxAmountTapped //handle max amount tap
            .debounce(for: 0.3, scheduler: RunLoop.main, options: nil)
            .dropFirst()
            .sink { [unowned self] _ in
                if let wallet = self.cardViewModel.wallet {
                    self.amountToSend = wallet.amounts[self.amountToSend.type]!
                    self.amountText = self.walletTotalBalanceDecimals
                    
                    withAnimation {
                        self.isFeeIncluded = true
                        self.isNetworkFeeBlockOpen = true
                    }
                }
        }
        .store(in: &bag)
        
        $amountText //handle amount input
            .filter { string -> Bool in
                if self.isFiatCalculation,
                    let fiat =  self.cardViewModel.getFiat(for: self.amountToSend)?.description,
                    string == fiat {
                    return false //prevent cross-convert after max amount tap
                }
                return true
            }
            .sink{ [unowned self] newAmount in
                guard let decimals = Decimal(string: newAmount.replacingOccurrences(of: ",", with: ".")),
                    let wallet = self.cardViewModel.wallet else {
                    self.amountToSend.value = 0
                    return
                }
                
                self.amountToSend.value = self.isFiatCalculation ? self.cardViewModel.getCrypto(for: decimals,
                                                                                                currencySymbol:  self.amountToSend.currencySymbol)?.rounded(blockchain: wallet.blockchain) ?? 0 : decimals
        }
        .store(in: &bag)
        
        $amountToSend //amount validation
            .debounce(for: 0.5, scheduler: RunLoop.main, options: nil)
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
                if let wallet = self.cardViewModel.wallet {
                    let feeDummyAmount = Amount(with: wallet.blockchain, address: wallet.address, type: .coin, value: 0)
                    self.sendFee = self.getDescription(for: newAmount ?? feeDummyAmount)
                }
        }
        .store(in: &bag)
        
        
        $isFiatCalculation //handle conversion
            .filter {[unowned self] _ in self.amountToSend.value != 0 }
            .sink { [unowned self] value in
                self.amountText = value ? self.cardViewModel.getFiat(for: self.amountToSend)?.description
                    ?? ""
                    : self.amountToSend.value.description
        }
        .store(in: &bag)
        
        $transaction //update total block
            .sink { [unowned self] tx in
                if let tx = tx {
                    self.isSendEnabled = true
                    let totalAmount = tx.amount + tx.fee
                    var totalFiatAmount: Decimal? = nil
                    
                    if let famount = self.cardViewModel.getFiat(for: tx.amount), let ffee = self.cardViewModel.getFiat(for: tx.fee) {
                        totalFiatAmount = famount + ffee
                    }
                    
                    let totalFiatAmountFormatted = totalFiatAmount?.currencyFormatted(code: self.cardViewModel.selectedCurrency)
                    
                    if self.isFiatCalculation {
                        self.sendAmount = self.cardViewModel.getFiatFormatted(for: tx.amount) ?? ""
                        self.sendTotal = totalFiatAmountFormatted ?? "-"
                        self.sendTotalSubtitle = tx.amount.type == tx.fee.type ?
                            String(format: "send_total_subtitle_format".localized, totalAmount.description) :
                            String(format: "send_total_subtitle_asset_format".localized,
                                   tx.amount.description,
                                   tx.fee.description)
                    } else {
                        self.sendAmount = tx.amount.description
                        self.sendTotal =  (tx.amount + tx.fee).description
                        self.sendTotalSubtitle = totalFiatAmountFormatted == nil ? "-" :  String(format: "send_total_subtitle_fiat_format".localized,
                                                                                        totalFiatAmountFormatted!,
                                                                                        self.cardViewModel.getFiatFormatted(for: tx.fee)!)
                    }
                    
                } else {
                    self.fillTotalBlockWithDefaults()
                    self.isSendEnabled = false
                }
        }
        .store(in: &bag)
        
        $amountValidated //update fee
            .filter { $0 }
            .combineLatest($validatedDestination.compactMap { $0 })
            .debounce(for: 0.3, scheduler: RunLoop.main, options: nil)
            .flatMap { [unowned self] _, dest -> AnyPublisher<[Amount], Never> in
                self.isFeeLoading = true
                return self.txSender.getFee(amount: self.amountToSend, destination: dest)
                    .catch { error -> Just<[Amount]> in
                        print(error)
                        return Just([Amount]())
                }.eraseToAnyPublisher()
        }
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { [unowned self] completion in
            self.isFeeLoading = false
            self.fees = []
            }, receiveValue: {[unowned self] fees in
                self.isFeeLoading = false
                self.fees = fees
        })
            .store(in: &bag)
        
        
        $fees //handle fee selection
            .combineLatest($selectedFeeLevel)
            .debounce(for: 0.3, scheduler: RunLoop.main, options: nil)
            .sink{ [unowned self] fees, level in
                if fees.isEmpty {
                    self.selectedFee = nil
                } else {
                    self.selectedFee = fees.count > 1 ? fees[self.selectedFeeLevel] : fees.first!
                }
        }
        .store(in: &bag)
        
        
        $amountValidated
            .combineLatest($validatedDestination,
                           $selectedFee,
                           $isFeeIncluded)
            .map {[unowned self] amountValidated, destination, fee, isFeeIncluded -> BlockchainSdk.Transaction? in
              
                if !amountValidated || destination == nil || fee == nil {
                    return nil
                }
                
                let result = self.cardViewModel.walletManager!.createTransaction(amount: isFeeIncluded ? self.amountToSend - fee! : self.amountToSend,
                                                                                 fee: fee!,
                                                                                 destinationAddress: destination!)
                switch result {
                case .success(let tx):
                    self.amountHint = nil
                    return tx
                case .failure(let error):
                    var message: String
                    if error.contains(.wrongTotal) {
                        message = "send_validation_invalid_total".localized
                    } else if  error.contains(.wrongFee) {
                        message =  "send_validation_invalid_fee".localized
                    } else {
                        message = "send_validation_invalid_amount".localized
                    }
                    self.amountHint = TextHint(isError: true, message: message)
                    return nil
                }
        }.sink{[unowned self] tx in
            self.transaction = tx
        }
        .store(in: &bag)
    }
    
    func onAppear() {
        validateClipboard()
        
        oldCardAlert = AlertManager().getAlert(.oldDeviceOldCard, for: cardViewModel.card)
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
        return cardViewModel.wallet?.blockchain.validate(address: address) ?? false
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
    
    func send(_ callback: @escaping () -> Void) {
        guard var tx = self.transaction else {
            return
        }
        
        if let payIdTag = self.validatedTag {
            tx.infos[Transaction.InfoKey.destinationTag] = payIdTag
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addLoadingView()
        txSender.send(tx, signer: sdkService.signer)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [unowned self] completion in
                appDelegate.removeLoadingView()
               
                if case let .failure(error) = completion {
                    if case .userCancelled = error.toTangemSdkError() {
                        return
                    }
                    Analytics.log(error: error)
                    self.sendError = error.detailedError.alertBinder
                } else {
                    callback()
                }
              
                }, receiveValue: {[unowned self] signResponse in
                    self.cardViewModel.card.walletSignedHashes = signResponse.walletSignedHashes
            })
            .store(in: &bag)
    }
    
    func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}
