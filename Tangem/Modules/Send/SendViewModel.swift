//
//  SendViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk
import TangemSdk
import stellarsdk
import AVFoundation

class SendViewModel: ObservableObject {
    @Injected(\.appWarningsService) private var warningsService: AppWarningsProviding

    @Published var showCameraDeniedAlert = false

    // MARK: Input
    @Published var validatedClipboard: String? = nil
    @Published var destination: String = ""
    @Published var amountText: String = "0"

    @Published var isFiatCalculation: Bool = false
    @Published var isFeeIncluded: Bool = false
    @Published var selectedFeeLevel: Int = 1
    @Published var maxAmountTapped: Bool = false
    @Published var fees: [Amount] = []

    @ObservedObject var warnings = WarningsContainer() {
        didSet {
            warnings.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [weak self] in
                    withAnimation {
                        self?.objectWillChange.send()
                    }
                })
                .store(in: &bag)
        }
    }

    // MARK: UI
    var shoudShowFeeSelector: Bool {
        walletModel.walletManager.allowsFeeSelection
    }

    var shoudShowFeeIncludeSelector: Bool {
        amountToSend.type == .coin && !isSellingCrypto
    }

    var shouldShowNetworkBlock: Bool  {
        shoudShowFeeSelector || shoudShowFeeIncludeSelector
    }

    var hasAdditionalInputFields: Bool {
        additionalInputFields != .none
    }

    var additionalInputFields: SendAdditionalFields {
        .fields(for: blockchainNetwork.blockchain)
    }

    var inputDecimalsCount: Int? {
        isFiatCalculation ? 2 : amountToSend.decimals
    }

    var isFiatConvertingAvailable: Bool {
        !isSellingCrypto && walletModel.getFiat(for: amountToSend) != nil
    }

    @Published var isNetworkFeeBlockOpen: Bool = false

    // MARK: Output
    @Published var destinationHint: TextHint? = nil
    @Published var amountHint: TextHint? = nil
    @Published var sendAmount: String = " "
    @Published var sendTotal: String = " "
    @Published var sendFee: String = " "
    @Published var sendTotalSubtitle: String = " "

    @Published var selectedFee: Amount? = nil
    @Published var transaction: BlockchainSdk.Transaction? = nil
    @Published var canFiatCalculation: Bool = true
    @Published var isFeeLoading: Bool = false

    var isSendEnabled: Bool {
        let hasDestinationErrorHint = destinationHint?.isError ?? false
        let hasAmountErrorHint = amountHint?.isError ?? false

        return !hasDestinationErrorHint && !hasAmountErrorHint && transaction != nil
    }

    // MARK: Additional input
    @Published var isAdditionalInputEnabled: Bool = false
    @Published var memo: String = ""
    @Published var memoHint: TextHint? = nil
    @Published var validatedMemoId: UInt64? = nil
    @Published var validatedMemo: String? = nil
    @Published var destinationTagStr: String = ""
    @Published var destinationTagHint: TextHint? = nil

    @Published var error: AlertBinder?

    let cardViewModel: CardViewModel

    var walletModel: WalletModel {
        return cardViewModel.walletModels.first(where: { $0.blockchainNetwork == blockchainNetwork })!
    }

    var bag = Set<AnyCancellable>()

    var currencyUnit: String {
        return isFiatCalculation ? AppSettings.shared.selectedCurrencyCode : self.amountToSend.currencySymbol
    }

    var walletTotalBalanceDecimals: String {
        let amount = walletModel.wallet.amounts[amountToSend.type]
        return isFiatCalculation ? walletModel.getFiat(for: amount)?.description ?? ""
            : amount?.value.description ?? ""
    }

    var walletTotalBalanceFormatted: String {
        let amount = walletModel.wallet.amounts[self.amountToSend.type]
        let value = getDescription(for: amount)
        return String(format: "send_balance_subtitle_format".localized, value)
    }

    // MARK: Private
    @Published private var validatedDestination: String? = nil
    @Published private var validatedAmount: Amount? = nil

    let amountToSend: Amount

    private(set) var isSellingCrypto: Bool
    private var lastError: Error? = nil
    private var scannedQRCode: CurrentValueSubject<String?, Never> = .init(nil)

    @Published private var validatedXrpDestinationTag: UInt32? = nil

    private let feeRetrySubject = CurrentValueSubject<Void, Never>(())

    private var blockchainNetwork: BlockchainNetwork

    private var lastClipboardChangeCount: Int?

    private unowned let coordinator: SendRoutable

    init(amountToSend: Amount,
         blockchainNetwork: BlockchainNetwork,
         cardViewModel: CardViewModel,
         coordinator: SendRoutable) {
        self.blockchainNetwork = blockchainNetwork
        self.cardViewModel = cardViewModel
        self.amountToSend = amountToSend
        self.coordinator = coordinator
        isSellingCrypto = false
        fillTotalBlockWithDefaults()
        bind()
        setupWarnings()
    }

    convenience init(amountToSend: Amount,
                     destination: String,
                     blockchainNetwork: BlockchainNetwork,
                     cardViewModel: CardViewModel,
                     coordinator: SendRoutable) {
        self.init(amountToSend: amountToSend,
                  blockchainNetwork: blockchainNetwork,
                  cardViewModel: cardViewModel,
                  coordinator: coordinator)
        isSellingCrypto = true
        self.destination = destination
        canFiatCalculation = false
        sendAmount = amountToSend.value.description
        amountText = sendAmount
        bind()
    }

    private func getDescription(for amount: Amount?) -> String {
        if isFiatCalculation {
            return walletModel.getFiatFormatted(for: amount) ?? ""
        }

        return amount?.description ?? ""
    }

    private func fillTotalBlockWithDefaults() {
        let dummyAmount = Amount(with: amountToSend, value: 0)

        updateFee(amount: selectedFee)
        self.sendAmount = getDescription(for: dummyAmount)
        self.sendTotal = getDescription(for: dummyAmount)
        self.sendTotalSubtitle = " "
    }

    // MARK: - Subscriptions
    func bind() {
        bag = Set<AnyCancellable>()

        cardViewModel
            .objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &bag)

        walletModel
            .objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &bag)

        walletModel
            .$rates
            .map { [unowned self] newRates -> Bool in
                return newRates[self.amountToSend.currencySymbol] != nil
            }
            .weakAssign(to: \.canFiatCalculation, on: self)
            .store(in: &bag)

        $destination // destination validation
            .debounce(for: 1.0, scheduler: RunLoop.main, options: nil)
            .removeDuplicates()
            .sink { [unowned self] newText in
                self.validateDestination(newText)
            }
            .store(in: &bag)

        $transaction    // update total block
            .combineLatest($isFiatCalculation.uiPublisherWithFirst)
            .sink { [unowned self] tx, isFiatCalculation in
                if let tx = tx {
                    self.updateViewWith(transaction: tx)
                } else {
                    self.fillTotalBlockWithDefaults()
                }
            }
            .store(in: &bag)

        $isFiatCalculation
            .receive(on: DispatchQueue.global())
            .dropFirst()
            .sink { _ in
                Analytics.log(.buttonSwapCurrency)
            }.store(in: &bag)

        $isFiatCalculation // handle conversion
            .uiPublisher
            .filter { [unowned self] _ in self.amountText != "0" }
            .sink { [unowned self] value in
                guard let decimals = Decimal(string: self.amountText.replacingOccurrences(of: ",", with: ".")) else {
                    return
                }

                let currencyId = self.walletModel.currencyId(for: self.amountToSend.type)

                if let converted = value ? self.walletModel.getFiat(for: decimals, currencyId: currencyId)
                    : self.walletModel.getCrypto(for: Amount(with: self.amountToSend, value: decimals)) {
                    self.amountText = converted.description
                } else {
                    self.amountText = "0"
                }

//                self.amountText = value ? self.walletModel.getFiat(for: self.amountToSend)?.description
//                    ?? ""
//                    : self.valida.value.description
            }
            .store(in: &bag)

        // MARK: Amount
        $amountText
            .uiPublisher
            .combineLatest($isFiatCalculation.uiPublisherWithFirst)
            .removeDuplicates(by: { prev, current in
                prev.0 == current.0
            })
//            .filter {[unowned self] (string, isFiat) -> Bool in
//                if isFiat,
//                   let fiat = self.walletModel.getFiat(for: self.amountToSend)?.description,
//                   string == fiat {
//                    return false //prevent cross-convert after max amount tap
//                }
//                return true
//            }
            .sink { [unowned self] newAmountString, isFiat in
                guard let decimals = Decimal(string: newAmountString.replacingOccurrences(of: ",", with: ".")) else {
                    self.amountHint = nil
                    self.validatedAmount = nil
                    return
                }

                let newAmountValue = isFiat ? self.walletModel.getCrypto(for: Amount(with: self.amountToSend, value: decimals)) ?? 0 : decimals
                let newAmount = Amount(with: self.amountToSend, value: newAmountValue)

                if let amountError = self.walletModel.walletManager.validate(amount: newAmount) {
                    self.amountHint = TextHint(isError: true, message: amountError.localizedDescription)
                    self.validatedAmount = nil
                } else {
                    self.amountHint = nil
                    self.validatedAmount = newAmount
                }

            }
            .store(in: &bag)

        $validatedAmount // update fee
            .dropFirst()
            .compactMap { $0 }
            .combineLatest($validatedDestination.compactMap { $0 }, feeRetrySubject)
            .flatMap { [unowned self] amount, dest, _ -> AnyPublisher<[Amount], Never> in
                self.isFeeLoading = true
                return self.walletModel.getFee(amount: amount, destination: dest)
                    .catch { [unowned self] error -> Just<[Amount]> in
                        print(error)
                        Analytics.log(error: error)

                        let ok = Alert.Button.default(Text("common_ok"))
                        let retry = Alert.Button.default(Text("common_retry")) { [unowned self] in
                            self.feeRetrySubject.send()
                        }
                        let alert = Alert(title: Text(WalletError.failedToGetFee.localizedDescription), primaryButton: retry, secondaryButton: ok)
                        self.error = AlertBinder(alert: alert)

                        return Just([Amount]())
                    }.eraseToAnyPublisher()
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [unowned self] completion in
                self.isFeeLoading = false
                self.fees = []
            }, receiveValue: { [unowned self] fees in
                self.isFeeLoading = false
                self.fees = fees
            })
            .store(in: &bag)

        $validatedAmount
            .combineLatest($validatedDestination,
                           $selectedFee,
                           $isFeeIncluded)
            .sink { [unowned self] (amount, destination, fee, isFeeIncluded) in
                guard let amount = amount, let destination = destination, let fee = fee else {
                    if (destination?.isEmpty == false) || destination == nil {
                        self.transaction = nil
                    }
                    return
                }

                do {
                    let tx = try self.walletModel.walletManager.createTransaction(amount: isFeeIncluded ? amount - fee : amount,
                                                                                  fee: fee,
                                                                                  destinationAddress: destination)
                    DispatchQueue.main.async {
                        self.validateWithdrawal(tx, amount)
                    }

                    self.amountHint = nil
                    self.transaction = tx

                } catch {
                    self.amountHint = TextHint(isError: true, message: error.localizedDescription)
                    self.transaction = nil
                }
            }
            .store(in: &bag)

        $maxAmountTapped // handle max amount tap
            .dropFirst()
            .sink { [unowned self] _ in
                self.amountText = self.walletTotalBalanceDecimals
                withAnimation {
                    self.isFeeIncluded = true
                    self.isNetworkFeeBlockOpen = true
                }
            }
            .store(in: &bag)

        // MARK: Fee
        $fees // handle fee selection
            .combineLatest($selectedFeeLevel)
            .sink { [unowned self] fees, level in
                if fees.isEmpty {
                    self.selectedFee = nil
                } else {
                    self.selectedFee = fees.count > 1 ? fees[level] : fees.first!
                }
            }
            .store(in: &bag)

        $selectedFee // update fee label
            .uiPublisher
            .sink { [unowned self] newAmount in
                self.updateFee(amount: newAmount)
            }
            .store(in: &bag)

        // MARK: Memo + destination tag
        $destinationTagStr
            .uiPublisher
            .sink(receiveValue: { [unowned self] destTagStr in
                self.validatedXrpDestinationTag = nil
                self.destinationTagHint = nil

                if destTagStr.isEmpty { return }

                let tag = UInt32(destTagStr)
                self.validatedXrpDestinationTag = tag
                self.destinationTagHint = tag == nil ? TextHint(isError: true, message: "send_extras_error_invalid_destination_tag".localized) : nil
            })
            .store(in: &bag)

        $memo
            .uiPublisher
            .sink(receiveValue: { [unowned self] memo in
                self.validatedMemoId = nil
                self.memoHint = nil
                self.validatedMemo = nil

                if memo.isEmpty { return }

                switch blockchainNetwork.blockchain {
                case .binance:
                    self.validatedMemo = memo
                case .stellar:
                    if let memoId = UInt64(memo) {
                        self.validatedMemoId = memoId
                    } else {
                        self.validatedMemo = memo
                    }
                default:
                    break
                }
            })
            .store(in: &bag)

        scannedQRCode
            .compactMap { $0 }
            .sink { [unowned self] qrCodeString in
                let withoutPrefix = qrCodeString.remove(contentsOf: self.walletModel.wallet.blockchain.qrPrefixes)
                let splitted = withoutPrefix.split(separator: "?")
                self.destination = splitted.first.map { String($0) } ?? withoutPrefix
                if splitted.count > 1 {
                    let queryItems = splitted[1].lowercased().split(separator: "&")
                    for queryItem in queryItems {
                        if queryItem.contains("amount") {
                            self.amountText = queryItem.replacingOccurrences(of: "amount=", with: "")
                            break
                        }
                    }
                }
            }
            .store(in: &bag)
    }

    func onAppear() {
        validateClipboard()
        setupWarnings()
    }

    func onBecomingActive() {
        validateClipboard()
    }

    // MARK: - Validation
    func validateClipboard() {
        let clipboardChangeCount = UIPasteboard.general.changeCount
        if clipboardChangeCount == lastClipboardChangeCount {
            return
        }

        validatedClipboard = nil
        lastClipboardChangeCount = clipboardChangeCount

        guard let input = UIPasteboard.general.string else {
            return
        }

        if validateAddress(input) {
            validatedClipboard = input
        }
    }

    func validateAddress(_ address: String) -> Bool {
        return walletModel.wallet.blockchain.validate(address: address)
            && !walletModel.wallet.addresses.contains(where: { $0.value == address })
    }


    func validateDestination(_ destination: String) {
        validatedDestination = nil
        destinationHint = nil
        isAdditionalInputEnabled = false

        if destination.isEmpty {
            return
        }

        if validateAddress(destination) {
            validatedDestination = destination
            setAdditionalInputVisibility(for: destination)
        } else {
            destinationHint = TextHint(isError: true,
                                       message: "send_validation_invalid_address".localized)
            setAdditionalInputVisibility(for: nil)
        }
    }

    func validateWithdrawal(_ transaction: BlockchainSdk.Transaction, _ totalAmount: Amount) {
        if let validator = walletModel.walletManager as? WithdrawalValidator,
           let warning = validator.validate(transaction),
           error == nil {
            let alert = Alert(title: Text("common_warning"),
                              message: Text(warning.warningMessage),
                              primaryButton: Alert.Button.default(Text(warning.reduceMessage),
                                                                  action: {

                                                                      let newAmount = totalAmount - warning.suggestedReduceAmount
                                                                      self.amountText = self.isFiatCalculation ? self.walletModel.getFiat(for: newAmount)?.description ?? "0" :
                                                                          newAmount.value.description
                                                                  }),
                              secondaryButton: Alert.Button.cancel(Text(warning.ignoreMessage),
                                                                   action: {

                                                                   }))
            UIApplication.shared.endEditing()
            self.error = AlertBinder(alert: alert, error: nil)
        }
    }

    // MARK: Validation end -

    func pasteClipboardTapped() {
        Analytics.log(.buttonPaste)
        if let validatedClipboard = self.validatedClipboard {
            destination = validatedClipboard
        }
    }

    func setAdditionalInputVisibility(for address: String?) {
        let isInputEnabled: Bool
        defer {
            withAnimation {
                isAdditionalInputEnabled = isInputEnabled
            }
        }

        guard let address = address else {
            isInputEnabled = false
            return
        }

        switch additionalInputFields {
        case .destinationTag:
            let xrpXAddress = try? XRPAddress.decodeXAddress(xAddress: address)
            isInputEnabled = xrpXAddress == nil
        case .memo:
            isInputEnabled = true
        default:
            isInputEnabled = false
        }
    }

    // MARK: - Send

    func send() {
        guard var tx = self.transaction else {
            return
        }

        if isAdditionalInputEnabled {
            switch blockchainNetwork.blockchain {
            case .binance:
                if let memo = self.validatedMemo {
                    tx.params = BinanceTransactionParams(memo: memo)
                }
            case .xrp:
                if let destinationTag = self.validatedXrpDestinationTag {
                    tx.params = XRPTransactionParams(destinationTag: destinationTag)
                }
            case .stellar:
                if let memoId = self.validatedMemoId {
                    tx.params = StellarTransactionParams(memo: .id(memoId))
                } else if let memoText = self.validatedMemo {
                    tx.params = StellarTransactionParams(memo: .text(memoText))
                }
            default:
                break
            }
        }

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addLoadingView()

        let isDemo = walletModel.isDemo
        walletModel.send(tx, signer: cardViewModel.signer)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }

                appDelegate.removeLoadingView()

                if case let .failure(error) = completion {
                    if case .userCancelled = error.toTangemSdkError() {
                        return
                    }

                    self.cardViewModel.logSdkError(error,
                                                   action: .sendTx,
                                                   parameters: [.blockchain: self.walletModel.wallet.blockchain.displayName])

                    self.lastError = error
                    self.error = error.alertBinder
                } else {
                    if !isDemo {
                        if self.isSellingCrypto {
                            Analytics.log(.transactionIsSent)
                            Analytics.log(.transactionSent, params: [.token: "\(tx.amount.currencySymbol)"])
                            Analytics.log(.userSoldCrypto, params: [.currencyCode: self.blockchainNetwork.blockchain.currencySymbol])
                        } else {
                            Analytics.logTx(blockchainName: self.blockchainNetwork.blockchain.displayName)
                        }
                    }

                    DispatchQueue.main.async {
                        let alert = AlertBuilder.makeSuccessAlert(message: isDemo ? "alert_demo_feature_disabled".localized
                            : "send_transaction_success".localized,
                            okAction: self.close)
                        self.error = alert
                    }
                }

            }, receiveValue: { _ in  })
            .store(in: &bag)
    }

    func warningButtonAction(at index: Int, priority: WarningPriority, button: WarningButton) {
        guard let warning = warnings.warning(at: index, with: priority) else { return }

        warningsService.hideWarning(warning)
    }

    func openSystemSettings() {
        UIApplication.openSystemSettings()
    }

    private func setupWarnings() {
        warnings = warningsService.warnings(for: .send)
    }
}

// MARK: - Private

private extension SendViewModel {
    func updateViewWith(transaction: BlockchainSdk.Transaction) {
        let totalAmount = transaction.amount + transaction.fee
        let totalInFiatFormatted = totalAndFeeInFiatFormatted(
            from: transaction,
            currencyCode: AppSettings.shared.selectedCurrencyCode
        )

        if isFiatCalculation {
            sendAmount = walletModel.getFiatFormatted(for: transaction.amount,  roundingMode: .plain) ?? ""
            sendTotal = totalInFiatFormatted.total

            if transaction.amount.type == transaction.fee.type {
                sendTotalSubtitle = "send_total_subtitle_format".localized(totalAmount.description)
            } else {
                sendTotalSubtitle = "send_total_subtitle_asset_format".localized(
                    [transaction.amount.description, transaction.fee.description]
                )
            }
        } else {
            sendAmount = transaction.amount.description
            sendTotal = (transaction.amount + transaction.fee).description

            if totalInFiatFormatted.total.isEmpty {
                sendTotalSubtitle = "–"
            } else {
                sendTotalSubtitle = "send_total_subtitle_fiat_format".localized(
                    [totalInFiatFormatted.total, totalInFiatFormatted.fee]
                )
            }
        }

        updateFee(amount: transaction.fee)
    }

    func totalAndFeeInFiatFormatted(from transaction: BlockchainSdk.Transaction, currencyCode: String) -> (total: String, fee: String) {
        guard let famount = walletModel.getFiat(for: transaction.amount, roundingMode: .plain),
              let ffee = walletModel.getFiat(for: transaction.fee, roundingMode: .plain),
              let feeFormatted = walletModel.getFiatFormatted(for: transaction.fee, roundingMode: .plain) else {
            return (total: "", fee: "")
        }

        let totalAmount = famount + ffee
        let totalFiatFormatted = totalAmount.currencyFormatted(code: currencyCode)

        return (total: totalFiatFormatted, fee: feeFormatted)
    }

    /// If the amount will be nil then will be use dummy amount
    func updateFee(amount: Amount?) {
        sendFee = formattedFee(amount: amount ?? .zeroCoin(for: walletModel.wallet.blockchain))
    }

    func formattedFee(amount: Amount) -> String {
        let formatted: String

        if isFiatCalculation {
            formatted = walletModel.getFiatFormatted(for: amount, roundingMode: .plain) ?? ""
        } else {
            formatted = amount.description
        }

        if amount.value > 0, walletModel.wallet.blockchain.isFeeApproximate(for: amountToSend.type)  {
            return "< " + formatted
        }

        return formatted
    }
}

// MARK: - Navigation
extension SendViewModel {
    func openMail() {
        let emailDataCollector = SendScreenDataCollector(userWalletEmailData: cardViewModel.emailData,
                                                         walletModel: walletModel,
                                                         amountToSend: amountToSend,
                                                         feeText: sendFee,
                                                         destination: destination,
                                                         amountText: amountText,
                                                         lastError: lastError)

        let recipient = cardViewModel.emailConfig?.recipient ?? EmailConfig.default.recipient
        coordinator.openMail(with: emailDataCollector, recipient: recipient)
    }

    func close() {
        coordinator.closeModule()
    }

    func openQRScanner() {
        Analytics.log(.buttonQRCode)
        if case .denied = AVCaptureDevice.authorizationStatus(for: .video) {
            self.showCameraDeniedAlert = true
        } else {
            let binding = Binding<String>(
                get: { [weak self] in
                    self?.scannedQRCode.value ?? ""
                },
                set: { [weak self] in
                    self?.scannedQRCode.send($0)
                })

            coordinator.openQRScanner(with: binding)
        }
    }
}
