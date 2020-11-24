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

class SendViewModel: ViewModel {
    @Published var navigation: NavigationCoordinator!
    weak var assembly: Assembly!
    weak var ratesService: CoinMarketCapService!
    
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
        return walletModel.txSender.allowsFeeSelection
    }
    
    var shoudShowFeeIncludeSelector: Bool {
        return amountToSend.type == .coin
    }
    
    var shouldShowNetworkBlock: Bool  {
        return shoudShowFeeSelector || shoudShowFeeIncludeSelector
    }

    	var isPayIdSupported: Bool {
		cardViewModel.payId != .notSupported
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
    
    var signer: TransactionSigner
    var cardViewModel: CardViewModel {
        didSet {
            cardViewModel
                .objectWillChange
                .receive(on: RunLoop.main)
                .sink { [weak self] in
                    self?.objectWillChange.send()
                }
                .store(in: &bag)
            
            cardViewModel.state.walletModel!
                .objectWillChange
                .receive(on: RunLoop.main)
                .sink { [weak self] in
                    self?.objectWillChange.send()
                }
                .store(in: &bag)
        }
    }
    
    var walletModel: WalletModel { cardViewModel.state.walletModel! }
    
    var bag = Set<AnyCancellable>()
    
    var currencyUnit: String {
        return isFiatCalculation ? ratesService.selectedCurrencyCode: self.amountToSend.currencySymbol
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
    
    //MARK: Private
    @Published private var validatedDestination: String? = nil
    @Published private var amountValidated: Bool = false
    @Published private var amountToSend: Amount
    
    private var validatedTag: String? = nil
    
    init(amountToSend: Amount, cardViewModel: CardViewModel, signer: TransactionSigner) {
        self.signer = signer
        self.cardViewModel = cardViewModel
        self.amountToSend = amountToSend
        let feeDummyAmount = Amount(with: walletModel.wallet.blockchain,
                                    address: walletModel.wallet.address,
                                    type: .coin,
                                    value: 0)
        self.sendFee = getDescription(for: selectedFee ?? feeDummyAmount, isFiat: isFiatCalculation)
        
        fillTotalBlockWithDefaults()
        bind()
    }
    
    private func getDescription(for amount: Amount?, isFiat: Bool) -> String {
        return isFiat ? walletModel.getFiatFormatted(for: amount) ?? ""
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
        
        walletModel
            .$rates
            .map {[unowned self] newRates -> Bool in
                return newRates[self.amountToSend.currencySymbol] != nil
            }
            .assign(to: \.canFiatCalculation, on: self)
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
                self.amountToSend = self.walletModel.wallet.amounts[self.amountToSend.type]!
                self.amountText = self.walletTotalBalanceDecimals
                
                withAnimation {
                    self.isFeeIncluded = true
                    self.isNetworkFeeBlockOpen = true
                }        }
            .store(in: &bag)
        
        $amountText
            .removeDuplicates()
            .combineLatest($isFiatCalculation)
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .filter {[unowned self] (string, isFiat) -> Bool in
                if isFiat,
                   let fiat = self.walletModel.getFiat(for: self.amountToSend)?.description,
                   string == fiat {
                    return false //prevent cross-convert after max amount tap
                }
                return true
            }
            .sink{ [unowned self] newAmount, isFiat in
                guard let decimals = Decimal(string: newAmount.replacingOccurrences(of: ",", with: ".")) else {
                    self.amountToSend.value = 0
                    return
                }
                
                self.amountToSend.value = isFiat ? self.walletModel.getCrypto(for: decimals,
                                                                              currencySymbol: self.amountToSend.currencySymbol)?.rounded(blockchain: self.walletModel.wallet.blockchain) ?? 0 : decimals
            }
            .store(in: &bag)
        
        $amountToSend //amount validation
            .removeDuplicates()
            .debounce(for: 0.5, scheduler: RunLoop.main, options: nil)
            .sink {[unowned self] newAmount in
                if newAmount.value == 0 {
                    self.amountHint = nil
                    self.amountValidated = false
                    return
                }
                
                if let amountError = self.walletModel.walletManager.validate(amount: newAmount) {
                    self.amountValidated = false
                    self.amountHint = TextHint(isError: true, message: amountError.localizedDescription)
                } else {
                    self.amountValidated = true
                    self.amountHint = nil
                }
            }
            .store(in: &bag)
        
        $selectedFee //update fee label
            .combineLatest($isFiatCalculation)
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .sink{ [unowned self] newAmount, isFiat in
                let feeDummyAmount = Amount(with: self.walletModel.wallet.blockchain, address: self.walletModel.wallet.address, type: .coin, value: 0)
                self.sendFee = self.getDescription(for: newAmount ?? feeDummyAmount, isFiat: isFiat)
            }
            .store(in: &bag)
        
        
        $isFiatCalculation //handle conversion
            .filter {[unowned self] _ in self.amountToSend.value != 0 }
            .sink { [unowned self] value in
                self.amountText = value ? self.walletModel.getFiat(for: self.amountToSend)?.description
                    ?? ""
                    : self.amountToSend.value.description
            }
            .store(in: &bag)
        
        $transaction
            .combineLatest($isFiatCalculation)
            .debounce(for: 0.3, scheduler: RunLoop.main)
            //update total block
            .sink { [unowned self] tx, isFiatCalculation in
                if let tx = tx {
                    self.isSendEnabled = true
                    let totalAmount = tx.amount + tx.fee
                    var totalFiatAmount: Decimal? = nil
                    
                    if let famount = self.walletModel.getFiat(for: tx.amount), let ffee = self.walletModel.getFiat(for: tx.fee) {
                        totalFiatAmount = famount + ffee
                    }
                    
                    let totalFiatAmountFormatted = totalFiatAmount?.currencyFormatted(code: self.ratesService.selectedCurrencyCode)
                    
                    if isFiatCalculation {
                        self.sendAmount = self.walletModel.getFiatFormatted(for: tx.amount) ?? ""
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
                                                                                                 self.walletModel.getFiatFormatted(for: tx.fee)!)
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
                return self.walletModel.txSender.getFee(amount: self.amountToSend, destination: dest)
                    .catch { error -> Just<[Amount]> in
                        print(error)
                        Analytics.log(error: error)
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
            .debounce(for: 0.3, scheduler: RunLoop.main, options: nil)
            .map {[unowned self] amountValidated, destination, fee, isFeeIncluded -> BlockchainSdk.Transaction? in
                
                if !amountValidated || destination == nil || fee == nil {
                    return nil
                }
                
                let result = self.walletModel.walletManager.createTransaction(amount: isFeeIncluded ? self.amountToSend - fee! : self.amountToSend,
                                                                                 fee: fee!,
                                                                                 destinationAddress: destination!)
                switch result {
                case .success(let tx):
                    DispatchQueue.main.async {
                        self.validateWithdrawal(tx)
                    }
                    self.amountHint = nil
                    return tx
                case .failure(let error):
                    self.amountHint = TextHint(isError: true, message: error.errors.first!.localizedDescription)
                    return nil
                }
            }.sink{[unowned self] tx in
                self.transaction = tx
            }
            .store(in: &bag)
    }
    
    func onAppear() {
        validateClipboard()
        
        oldCardAlert = AlertManager().getAlert(.oldDeviceOldCard, for: cardViewModel.cardInfo.card)
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
        return walletModel.wallet.blockchain.validate(address: address)
            && address != walletModel.wallet.address
    }
    
    
    func validateDestination(_ destination: String) {
        validatedDestination = nil
        validatedTag = nil
        destinationHint = nil
        
        if destination.isEmpty {
            return
        }
        
        if let payIdService = cardViewModel.payIDService, 
            isPayIdSupported,
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
    
    func validateWithdrawal(_ transaction: BlockchainSdk.Transaction) {
        if let validator = walletModel.walletManager as? WithdrawalValidator,
           let warning = validator.validate(transaction),
           sendError == nil {
            let alert = Alert(title: Text("common_warning"),
                              message: Text(warning.warningMessage),
                              primaryButton: Alert.Button.default(Text(warning.reduceMessage),
                                                                  action: {
                                                                    self.amountToSend = self.amountToSend - warning.suggestedReduceAmount
                                                                    
                                                                    self.amountText = self.isFiatCalculation ? self.walletModel.getFiat(for:
                                                                                                                                            self.amountToSend)?.description ?? "0" :
                                                                        self.amountToSend.value.description
                                                                  }),
                              secondaryButton: Alert.Button.cancel(Text(warning.ignoreMessage),
                                                                   action: {
                                                                    
                                                                   }))
            UIApplication.shared.endEditing()
            self.sendError = AlertBinder(alert: alert)
        }
    }
    
    func pasteClipboardTapped() {
        if let validatedClipboard = self.validatedClipboard {
            destination = validatedClipboard
        }
    }
    
    func stripBlockchainPrefix(_ string: String) -> String {
        let cleaned = string.split(separator: "?").first.map { String($0) } ?? string
        return cleaned.remove(walletModel.wallet.blockchain.qrPrefix)
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
        walletModel.txSender.send(tx, signer: signer)
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
                    Analytics.logTx(blockchainName: self.cardViewModel.cardInfo.card.cardData?.blockchainName)
                    callback()
                }
                
            }, receiveValue: {[unowned self] signResponse in
                self.cardViewModel.onSign(signResponse)
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
