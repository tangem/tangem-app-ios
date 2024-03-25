//
//  SendViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import BlockchainSdk
import AVFoundation

final class SendViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var stepAnimation: SendView.StepAnimation? = .slideForward
    @Published var step: SendStep
    @Published var showBackButton = false
    @Published var currentStepInvalid: Bool = false
    @Published var alert: AlertBinder?

    var title: String? {
        step.name(for: sendStepParameters)
    }

    var hasSubtitle: Bool {
        subtitle != nil
    }

    var subtitle: String? {
        step.description(for: sendStepParameters)
    }

    var showNavigationButtons: Bool {
        step.hasNavigationButtons
    }

    var showNextButton: Bool {
        !didReachSummaryScreen
    }

    var showContinueButton: Bool {
        didReachSummaryScreen
    }

    var showQRCodeButton: Bool {
        switch step {
        case .destination:
            return true
        case .amount, .fee, .summary, .finish:
            return false
        }
    }

    let sendAmountViewModel: SendAmountViewModel
    let sendDestinationViewModel: SendDestinationViewModel
    let sendFeeViewModel: SendFeeViewModel
    let sendSummaryViewModel: SendSummaryViewModel

    // MARK: - Dependencies

    private let sendModel: SendModel
    private let sendType: SendType
    private let steps: [SendStep]
    private let walletModel: WalletModel
    private let userWalletModel: UserWalletModel
    private let emailDataProvider: EmailDataProvider
    private let walletInfo: SendWalletInfo
    private let notificationManager: CommonSendNotificationManager
    private let fiatCryptoAdapter: CommonSendFiatCryptoAdapter
    private let sendStepParameters: SendStep.Parameters

    private weak var coordinator: SendRoutable?

    private var bag: Set<AnyCancellable> = []
    private var feeUpdateSubscription: AnyCancellable? = nil

    private var didReachSummaryScreen = false

    private var currentStepValid: AnyPublisher<Bool, Never> {
        let inputFieldsValid = $step
            .flatMap { [weak self] step -> AnyPublisher<Bool, Never> in
                guard let self else {
                    return .just(output: true)
                }

                switch step {
                case .amount:
                    return sendModel.amountValid
                case .destination:
                    return sendModel.destinationValid
                case .fee:
                    return sendModel.feeValid
                case .summary, .finish:
                    return .just(output: true)
                }
            }

        let hasTransactionCreationError = Publishers.CombineLatest($step, sendModel.transactionCreationError)
            .map { step, error in
                guard let validationError = error as? ValidationError else { return false }
                return validationError.step == step
            }

        return Publishers.CombineLatest(inputFieldsValid, hasTransactionCreationError)
            .map { inputFieldsValid, hasTransactionCreationError in
                inputFieldsValid && !hasTransactionCreationError
            }
            .eraseToAnyPublisher()
    }

    init(
        walletName: String,
        walletModel: WalletModel,
        userWalletModel: UserWalletModel,
        transactionSigner: TransactionSigner,
        sendType: SendType,
        emailDataProvider: EmailDataProvider,
        coordinator: SendRoutable
    ) {
        self.coordinator = coordinator
        self.sendType = sendType
        self.walletModel = walletModel
        self.userWalletModel = userWalletModel
        self.emailDataProvider = emailDataProvider

        let addressService = SendAddressServiceFactory(walletModel: walletModel).makeService()
        #warning("[REDACTED_TODO_COMMENT]")
        sendModel = SendModel(walletModel: walletModel, transactionSigner: transactionSigner, addressService: addressService, sendType: sendType)

        let steps = sendType.steps
        guard let firstStep = steps.first else {
            fatalError("No steps provided for the send type")
        }
        self.steps = steps
        step = firstStep

        let tokenIconInfo = TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom)
        let cryptoIconURL: URL?
        if let tokenId = walletModel.tokenItem.id {
            cryptoIconURL = IconURLBuilder().tokenIconURL(id: tokenId)
        } else {
            cryptoIconURL = nil
        }

        let fiatIconURL = IconURLBuilder().fiatIconURL(currencyCode: AppSettings.shared.selectedCurrencyCode)

        walletInfo = SendWalletInfo(
            walletName: walletName,
            balanceValue: walletModel.balanceValue,
            balance: Localization.sendWalletBalanceFormat(walletModel.balance, walletModel.fiatBalance),
            blockchain: walletModel.blockchainNetwork.blockchain,
            currencyId: walletModel.tokenItem.currencyId,
            feeCurrencySymbol: walletModel.tokenItem.blockchain.currencySymbol,
            feeCurrencyId: walletModel.tokenItem.blockchain.currencyId,
            isFeeApproximate: walletModel.tokenItem.blockchain.isFeeApproximate(for: walletModel.amountType),
            tokenIconInfo: tokenIconInfo,
            cryptoIconURL: cryptoIconURL,
            cryptoCurrencyCode: walletModel.tokenItem.currencySymbol,
            fiatIconURL: fiatIconURL,
            fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            amountFractionDigits: walletModel.tokenItem.decimalCount,
            feeFractionDigits: walletModel.feeTokenItem.decimalCount,
            feeAmountType: walletModel.feeTokenItem.amountType
        )

        notificationManager = CommonSendNotificationManager(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            input: sendModel
        )

        fiatCryptoAdapter = CommonSendFiatCryptoAdapter(
            cryptoCurrencyId: walletInfo.currencyId,
            currencySymbol: walletInfo.cryptoCurrencyCode,
            decimals: walletInfo.amountFractionDigits
        )

        sendStepParameters = SendStep.Parameters(currencyName: walletModel.tokenItem.name, walletName: walletInfo.walletName)

        sendAmountViewModel = SendAmountViewModel(input: sendModel, fiatCryptoAdapter: fiatCryptoAdapter, walletInfo: walletInfo)
        sendDestinationViewModel = SendDestinationViewModel(input: sendModel)
        sendFeeViewModel = SendFeeViewModel(input: sendModel, notificationManager: notificationManager, walletInfo: walletInfo)
        sendSummaryViewModel = SendSummaryViewModel(input: sendModel, notificationManager: notificationManager, fiatCryptoValueProvider: fiatCryptoAdapter, walletInfo: walletInfo)

        fiatCryptoAdapter.setInput(sendAmountViewModel)
        fiatCryptoAdapter.setOutput(sendModel)

        sendFeeViewModel.router = coordinator
        sendSummaryViewModel.router = self

        notificationManager.setupManager(with: self)

        bind()
    }

    func next() {
        guard let nextStep = nextStep(after: step) else {
            assertionFailure("Invalid step logic -- next")
            return
        }

        logNextStepAnalytics()

        let stepAnimation: SendView.StepAnimation? = (nextStep == .summary) ? nil : .slideForward
        openStep(nextStep, stepAnimation: stepAnimation)
    }

    func back() {
        guard let previousStep = previousStep(before: step) else {
            assertionFailure("Invalid step logic -- back")
            return
        }

        openStep(previousStep, stepAnimation: .slideBackward)
    }

    func `continue`() {
        openStep(.summary, stepAnimation: nil)
    }

    func scanQRCode() {
        let binding = Binding<String>(
            get: {
                ""
            },
            set: { [weak self] in
                self?.parseQRCode($0)
            }
        )

        let networkName = walletModel.blockchainNetwork.blockchain.displayName
        coordinator?.openQRScanner(with: binding, networkName: networkName)
    }

    private func bind() {
        currentStepValid
            .map {
                !$0
            }
            .assign(to: \.currentStepInvalid, on: self, ownership: .weak)
            .store(in: &bag)

        sendModel
            .destinationPublisher
            .sink { [weak self] destination in
                guard let self else { return }

                if showNextButton {
                    switch destination?.source {
                    case .myWallet, .recentAddress:
                        next()
                    default:
                        break
                    }
                }
            }
            .store(in: &bag)

        sendModel
            .sendError
            .sink { [weak self] error in
                guard let self, let error else { return }

                Analytics.log(event: .sendErrorTransactionRejected, params: [
                    .token: walletModel.tokenItem.currencySymbol,
                ])

                let errorCode: String
                let reason = String(error.localizedDescription.dropTrailingPeriod)
                if let errorCodeProviding = error as? ErrorCodeProviding {
                    errorCode = "\(errorCodeProviding.errorCode)"
                } else {
                    errorCode = "-"
                }

                alert = SendError(
                    title: Localization.sendAlertTransactionFailedTitle,
                    message: Localization.sendAlertTransactionFailedText(reason, errorCode),
                    error: error,
                    openMailAction: openMail
                )
                .alertBinder
            }
            .store(in: &bag)

        sendModel
            .transactionFinished
            .removeDuplicates()
            .sink { [weak self] transactionFinished in
                guard let self, transactionFinished else { return }

                openFinishPage()

                if walletModel.isDemo {
                    let button = Alert.Button.default(Text(Localization.commonOk)) {
                        self.coordinator?.dismiss()
                    }
                    alert = AlertBuilder.makeAlert(title: "", message: Localization.alertDemoFeatureDisabled, primaryButton: button)
                }

                Analytics.log(.sendSelectedCurrency, params: [
                    .commonType: sendAmountViewModel.useFiatCalculation ? .selectedCurrencyApp : .token,
                ])
            }
            .store(in: &bag)

        sendModel
            .destinationPublisher
            .sink { destination in
                guard let destination else { return }

                Analytics.logDestinationAddress(isAddressValid: destination.value != nil, source: destination.source)
            }
            .store(in: &bag)
    }

    private func nextStep(after step: SendStep) -> SendStep? {
        guard
            let currentStepIndex = steps.firstIndex(of: step),
            (currentStepIndex + 1) < steps.count
        else {
            return nil
        }

        return steps[currentStepIndex + 1]
    }

    private func previousStep(before step: SendStep) -> SendStep? {
        guard
            let currentStepIndex = steps.firstIndex(of: step),
            (currentStepIndex - 1) >= 0
        else {
            return nil
        }

        return steps[currentStepIndex - 1]
    }

    private func openMail(with error: Error) {
        guard let transaction = sendModel.currentTransaction() else { return }

        let emailDataCollector = SendScreenDataCollector(
            userWalletEmailData: emailDataProvider.emailData,
            walletModel: walletModel,
            fee: transaction.fee.amount,
            destination: transaction.destinationAddress,
            amount: transaction.amount,
            isFeeIncluded: sendModel.isFeeIncluded,
            lastError: error
        )
        let recipient = emailDataProvider.emailConfig?.recipient ?? EmailConfig.default.recipient
        coordinator?.openMail(with: emailDataCollector, recipient: recipient)
    }

    private func showSummaryStepAlertIfNeeded(_ step: SendStep, stepAnimation: SendView.StepAnimation?, checkCustomFee: Bool) -> Bool {
        if sendModel.totalExceedsBalance {
            Analytics.log(event: .sendNoticeNotEnoughFee, params: [
                .token: walletModel.tokenItem.currencySymbol,
                .blockchain: walletModel.tokenItem.blockchain.displayName,
            ])

            alert = SendAlertBuilder.makeSubtractFeeFromAmountAlert { [weak self] in
                self?.sendModel.includeFeeIntoAmount()
                self?.openStep(step, stepAnimation: stepAnimation)
            }

            return true
        }

        if checkCustomFee, notificationManager.hasNotificationEvent(.customFeeTooLow) {
            Analytics.log(event: .sendNoticeTransactionDelaysArePossible, params: [
                .token: walletModel.tokenItem.currencySymbol,
            ])

            alert = SendAlertBuilder.makeCustomFeeTooLowAlert { [weak self] in
                self?.openStep(step, stepAnimation: stepAnimation, checkCustomFee: false)
            }

            return true
        }

        return false
    }

    private func openStep(_ step: SendStep, stepAnimation: SendView.StepAnimation?, checkCustomFee: Bool = true) {
        if case .summary = step {
            if showSummaryStepAlertIfNeeded(step, stepAnimation: stepAnimation, checkCustomFee: checkCustomFee) {
                return
            }

            didReachSummaryScreen = true
        }

        self.stepAnimation = stepAnimation

        let animateStepChanges: () -> Void = {
            withAnimation(SendView.Constants.backButtonAnimation) {
                self.showBackButton = self.previousStep(before: step) != nil && !self.didReachSummaryScreen
            }

            withAnimation(SendView.Constants.defaultAnimation) {
                self.step = step
            }
        }

        if stepAnimation != nil {
            // Gotta give some time to update animation variable
            DispatchQueue.main.async {
                animateStepChanges()
            }
        } else {
            animateStepChanges()
        }

        // Hide the keyboard with a delay, otherwise the animation is going to be screwed up
        if !step.opensKeyboardByDefault {
            DispatchQueue.main.asyncAfter(deadline: .now() + SendView.Constants.animationDuration) {
                UIApplication.shared.endEditing()
            }
        }
    }

    private func openFinishPage() {
        guard let sendFinishViewModel = SendFinishViewModel(input: sendModel, fiatCryptoValueProvider: fiatCryptoAdapter, walletInfo: walletInfo) else {
            assertionFailure("WHY?")
            return
        }

        sendFinishViewModel.router = coordinator
        openStep(.finish(model: sendFinishViewModel), stepAnimation: nil)
    }

    private func parseQRCode(_ code: String) {
        #warning("[REDACTED_TODO_COMMENT]")
        let parser = QRCodeParser(
            amountType: walletModel.amountType,
            blockchain: walletModel.blockchainNetwork.blockchain,
            decimalCount: walletModel.decimalCount
        )

        guard let result = parser.parse(code) else {
            return
        }

        sendModel.setDestination(SendAddress(value: result.destination, source: .qrCode))
        sendModel.setAmount(result.amount)

        if let memo = result.memo {
            sendModel.setDestinationAdditionalField(memo)
        }
    }

    private func logNextStepAnalytics() {
        switch step {
        case .fee:
            Analytics.log(event: .sendFeeSelected, params: [.feeType: selectedFeeTypeAnalyticsParameter().rawValue])
        default:
            break
        }
    }

    private func selectedFeeTypeAnalyticsParameter() -> Analytics.ParameterValue {
        if sendModel.feeOptions.count == 1 {
            return .transactionFeeFixed
        }

        switch sendModel.selectedFeeOption {
        case .slow:
            return .transactionFeeMin
        case .market:
            return .transactionFeeNormal
        case .fast:
            return .transactionFeeMax
        case .custom:
            return .transactionFeeCustom
        }
    }

    // [REDACTED_TODO_COMMENT]
    private func openNetworkCurrency() {
        guard
            let networkCurrencyWalletModel = userWalletModel.walletModelsManager.walletModels.first(where: {
                $0.tokenItem == .blockchain(walletModel.tokenItem.blockchainNetwork) && $0.blockchainNetwork == walletModel.blockchainNetwork
            })
        else {
            assertionFailure("Network currency WalletModel not found")
            return
        }

        coordinator?.openFeeCurrency(for: networkCurrencyWalletModel, userWalletModel: userWalletModel)
    }
}

extension SendViewModel: SendSummaryRoutable {
    func openStep(_ step: SendStep) {
        guard self.step == .summary else {
            assertionFailure("This code should only be called from summary")
            return
        }

        if let auxiliaryViewAnimatable = auxiliaryViewAnimatable(step) {
            auxiliaryViewAnimatable.setAnimatingAuxiliaryViewsOnAppear()
        }

        openStep(step, stepAnimation: nil)
    }

    func send() {
        sendModel.send()
    }

    private func auxiliaryViewAnimatable(_ step: SendStep) -> AuxiliaryViewAnimatable? {
        switch step {
        case .amount:
            return sendAmountViewModel
        case .destination:
            return sendDestinationViewModel
        case .fee:
            return sendFeeViewModel
        case .summary:
            return nil
        case .finish:
            return nil
        }
    }
}

extension SendViewModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId) {}

    func didTapNotificationButton(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .refreshFee:
            feeUpdateSubscription = sendModel.updateFees()
                .mapToVoid()
                .sink()
        case .openFeeCurrency:
            openNetworkCurrency()
        case .reduceAmountBy(let amount, _):
            reduceAmountBy(amount)
        case .reduceAmountTo(let amount, _):
            reduceAmountTo(amount)
        default:
            assertionFailure("Notification tap not handled")
        }
    }

    private func reduceAmountBy(_ amount: Decimal) {
        guard var newAmount = sendModel.validatedAmountValue else { return }

        newAmount = newAmount - Amount(with: walletModel.tokenItem.blockchain, type: walletModel.amountType, value: amount)
        if sendModel.isFeeIncluded, let feeValue = sendModel.feeValue?.amount {
            newAmount = newAmount + feeValue
        }

        sendModel.setAmount(newAmount)
    }

    private func reduceAmountTo(_ amount: Decimal) {
        var newAmount = amount

        if sendModel.isFeeIncluded, let feeValue = sendModel.feeValue?.amount.value {
            newAmount = newAmount + feeValue
        }

        sendModel.setAmount(Amount(with: walletModel.tokenItem.blockchain, type: walletModel.amountType, value: newAmount))
    }
}

// MARK: - ValidationError

private extension ValidationError {
    var step: SendStep? {
        switch self {
        case .invalidAmount, .balanceNotFound:
            // Shouldn't happen as we validate and cover amount errors separately, synchronously
            return nil
        case .amountExceedsBalance, .invalidFee, .feeExceedsBalance, .maximumUTXO, .reserve:
            return .fee
        case .dustAmount, .dustChange, .minimumBalance, .totalExceedsBalance:
            return .summary
        }
    }
}
