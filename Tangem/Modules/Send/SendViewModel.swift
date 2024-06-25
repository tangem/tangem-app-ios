//
//  SendViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import BlockchainSdk

protocol SendStepProvider {
    associatedtype ViewModel: ObservableObject
    var viewModel: ViewModel { get }
    var type: SendStepName { get }

    var isValid: Bool { get }
    var isValidPublisher: AnyPublisher<Bool, Never> { get }


}

enum SendStepName {
    case destination
    case amount
    case fee
    case summary
    case finish
}

final class SendViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var stepAnimation: SendView.StepAnimation
    @Published var step: SendStep

    @Published var closeButtonDisabled = false
    @Published var showBackButton = false
    @Published var showTransactionButtons = false

    @Published var mainButtonType: SendMainButtonType
    @Published var mainButtonLoading: Bool = false
    @Published var mainButtonDisabled: Bool = false

    @Published var alert: AlertBinder?

    var title: String? {
        step.name(currencyName: initial.tokenItem.currencySymbol)
    }

    var subtitle: String? {
        step.description(walletName: initial.walletName)
    }

    var closeButtonColor: Color {
        closeButtonDisabled ? Colors.Text.disabled : Colors.Text.primary1
    }

    var showQRCodeButton: Bool {
        switch step {
        case .destination:
            return true
        case .amount, .fee, .summary, .finish:
            return false
        }
    }

    var shouldShowDismissAlert: Bool {
        if case .finish = step {
            return false
        }

        return didReachSummaryScreen
    }

    let sendAmountViewModel: SendAmountViewModel
    let sendDestinationViewModel: SendDestinationViewModel
    let sendFeeViewModel: SendFeeViewModel
    let sendSummaryViewModel: SendSummaryViewModel
    // TODO: Will be separated on steps with equal viewModels
    let sendFinishViewModel: SendSummaryViewModel

    // MARK: - Dependencies

    private let initial: Initial
    private let sendModel: SendModel
    private let sendType: SendType
    private let steps: [SendStep]
    private let walletModel: WalletModel
    private let userWalletModel: UserWalletModel
    private let emailDataProvider: EmailDataProvider
    private let walletInfo: SendWalletInfo
    private let notificationManager: SendNotificationManager
    private let addressTextViewHeightModel: AddressTextViewHeightModel
//    private let sendStepParameters: SendStep.Parameters
    private let keyboardVisibilityService: KeyboardVisibilityService
    private let factory: SendModulesFactory

    private weak var coordinator: SendRoutable?

    private var bag: Set<AnyCancellable> = []
    private var feeUpdateSubscription: AnyCancellable? = nil

    private var currentPageAnimating: Bool? = nil
    private var didReachSummaryScreen: Bool
    /*
     private var validSteps: AnyPublisher<[SendStep], Never> {
         let summaryValid = Publishers.CombineLatest(
             sendModel.transactionCreationError.map { $0 != nil }.eraseToAnyPublisher(),
             notificationManager.hasNotifications(with: .critical)
         )
         .map { hasTransactionErrors, hasCriticalNotifications in
             !hasTransactionErrors && !hasCriticalNotifications
         }
         .eraseToAnyPublisher()

         return Publishers.CombineLatest4(
             sendModel.destinationValid,
             sendModel.amountValid,
             sendModel.feeValid,
             summaryValid
         )
         .receive(on: DispatchQueue.main)
         .map { destinationValid, amountValid, feeValid, summaryValid in
             var validSteps: [SendStep] = []
             if destinationValid {
                 validSteps.append(.destination)
             }
             if amountValid {
                 validSteps.append(.amount)
             }
             if feeValid {
                 validSteps.append(.fee)
             }
             if summaryValid {
                 validSteps.append(.summary)
             }
             return validSteps
         }
         .eraseToAnyPublisher()
     }
     */
    init(
        initial: Initial,
        walletInfo: SendWalletInfo,
        walletModel: WalletModel,
        userWalletModel: UserWalletModel,
        transactionSigner: TransactionSigner,
        sendType: SendType,
        emailDataProvider: EmailDataProvider,
        sendModel: SendModel,
        notificationManager: SendNotificationManager,
        sendFeeInteractor: SendFeeInteractor,
        sendSummaryInteractor: SendSummaryInteractor,
        keyboardVisibilityService: KeyboardVisibilityService,
        sendAmountValidator: SendAmountValidator,
        factory: SendModulesFactory,
        coordinator: SendRoutable
    ) {
        self.initial = initial
        self.walletInfo = walletInfo
        self.coordinator = coordinator
        self.sendType = sendType
        self.walletModel = walletModel
        self.userWalletModel = userWalletModel
        self.emailDataProvider = emailDataProvider
        self.sendModel = sendModel
        self.notificationManager = notificationManager
        self.keyboardVisibilityService = keyboardVisibilityService
        self.factory = factory

        steps = sendType.steps
        step = sendType.firstStep
        didReachSummaryScreen = sendType.firstStep == .summary
        mainButtonType = Self.mainButtonType(for: sendType.firstStep, didReachSummaryScreen: didReachSummaryScreen)
//        stepAnimation = sendType.firstStep == .summary ? .moveAndFade : .slideForward
//        sendStepParameters = SendStep.Parameters(currencyName: walletModel.tokenItem.name, walletName: walletInfo.walletName)

        // TODO: Sepate by steps and inject it
        addressTextViewHeightModel = .init()
        sendAmountViewModel = factory.makeSendAmountViewModel(
            input: sendModel,
            output: sendModel,
            validator: sendAmountValidator,
            sendType: sendType
        )

        sendDestinationViewModel = factory.makeSendDestinationViewModel(
            input: sendModel,
            output: sendModel,
            sendType: sendType,
            addressTextViewHeightModel: addressTextViewHeightModel
        )

        sendFeeViewModel = factory.makeSendFeeViewModel(
            sendFeeInteractor: sendFeeInteractor,
            notificationManager: notificationManager,
            router: coordinator
        )

        sendSummaryViewModel = factory.makeSendSummaryViewModel(
            interactor: sendSummaryInteractor,
            notificationManager: notificationManager,
            addressTextViewHeightModel: addressTextViewHeightModel,
            editableType: sendType.isSend ? .editable : .disable
        )

        sendFinishViewModel = factory.makeSendSummaryViewModel(
            interactor: sendSummaryInteractor,
            notificationManager: notificationManager,
            addressTextViewHeightModel: addressTextViewHeightModel,
            editableType: .notEditable
        )

        sendSummaryViewModel.router = self
        sendSummaryViewModel.setup(sendDestinationInput: sendModel)
        sendSummaryViewModel.setup(sendAmountInput: sendModel)
        sendSummaryViewModel.setup(sendFeeInteractor: sendFeeInteractor)

        sendFinishViewModel.setup(sendDestinationInput: sendModel)
        sendFinishViewModel.setup(sendAmountInput: sendModel)
        sendFinishViewModel.setup(sendFeeInteractor: sendFeeInteractor)
        sendFinishViewModel.setup(sendFinishInput: sendModel)

        sendModel.delegate = self
        notificationManager.setupManager(with: self)

        updateTransactionHistoryIfNeeded()

        bind()
    }

    func onCurrentPageAppear() {
        if currentPageAnimating != nil {
            currentPageAnimating = true
        }
    }

    func onCurrentPageDisappear() {
        currentPageAnimating = false
    }

    func dismiss() {
        Analytics.log(.sendButtonClose, params: [
            .source: step.analyticsSourceParameterValue,
            .fromSummary: .affirmativeOrNegative(for: didReachSummaryScreen),
            .valid: .affirmativeOrNegative(for: !mainButtonDisabled),
        ])

        if shouldShowDismissAlert {
            alert = SendAlertBuilder.makeDismissAlert { [coordinator] in
                coordinator?.dismiss()
            }
        } else {
            coordinator?.dismiss()
        }
    }

//    func next() {
//        // If we try to open another page mid-animation then the appropriate onAppear of the new page will not get called
//        if currentPageAnimating ?? false {
//            return
//        }
//
//        switch mainButtonType {
//        case .next:
//            guard let nextStep = nextStep(after: step) else {
//                assertionFailure("Invalid step logic -- next")
//                return
//            }
//
//            logNextStepAnalytics()
//
//            let openingSummary = (nextStep == .summary)
//            let stepAnimation: SendView.StepAnimation = openingSummary ? .moveAndFade : .slideForward
//
//            let checkCustomFee = shouldCheckCustomFee(currentStep: step)
//            let updateFee = shouldUpdateFee(currentStep: step, nextStep: nextStep)
//            openStep(nextStep, stepAnimation: stepAnimation, checkCustomFee: checkCustomFee, updateFee: updateFee)
//        case .continue:
//            let nextStep = SendStep.summary
//            let checkCustomFee = shouldCheckCustomFee(currentStep: step)
//            let updateFee = shouldUpdateFee(currentStep: step, nextStep: nextStep)
//            openStep(nextStep, stepAnimation: .moveAndFade, checkCustomFee: checkCustomFee, updateFee: updateFee)
//        case .send:
//            sendModel.send()
//        case .close:
//            coordinator?.dismiss()
//        }
//    }
//
//    func back() {
//        guard let previousStep = previousStep(before: step) else {
//            assertionFailure("Invalid step logic -- back")
//            return
//        }
//
//        openStep(previousStep, stepAnimation: .slideBackward, updateFee: false)
//    }

    func share() {
        guard let transactionURL = sendModel.transactionURL else {
            return
        }

        Analytics.log(.sendButtonShare)
        coordinator?.openShareSheet(url: transactionURL)
    }

    func explore() {
        guard let transactionURL = sendModel.transactionURL else {
            return
        }

        Analytics.log(.sendButtonExplore)
        coordinator?.openExplorer(url: transactionURL)
    }

    func scanQRCode() {
        let binding = Binding<String>(get: { "" }, set: { [weak self] in
                self?.parseQRCode($0)
            }
        )

        let networkName = walletModel.blockchainNetwork.blockchain.displayName
        coordinator?.openQRScanner(with: binding, networkName: networkName)
    }

//    func onSummaryAppear() {}
//
//    func onSummaryDisappear() {}

    private func bind() {
        sendModel.isSending
            .assign(to: \.closeButtonDisabled, on: self, ownership: .weak)
            .store(in: &bag)

        sendModel.isSending
            .assign(to: \.mainButtonLoading, on: self, ownership: .weak)
            .store(in: &bag)

//        Publishers.CombineLatest(validSteps, $step)
//            .receive(on: DispatchQueue.main)
//            .map { validSteps, step in
//                #warning("TODO: invert the logic and publish INVALID steps instead (?)")
//                switch step {
//                case .finish:
//                    return false
//                default:
//                    return !validSteps.contains(step)
//                }
//            }
//            .assign(to: \.mainButtonDisabled, on: self, ownership: .weak)
//            .store(in: &bag)

        sendModel
            .destinationPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, destination in
                switch destination.source {
                case .myWallet, .recentAddress:
                    viewModel.stepsManager.userDidTapActionButton(mainButtonType: .next)
                default:
                    break
                }
            }
            .store(in: &bag)

        sendModel
            .sendError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                guard let self, let error else { return }

                Analytics.log(event: .sendErrorTransactionRejected, params: [
                    .token: walletModel.tokenItem.currencySymbol,
                ])

                if case .noAccount(_, let amount) = (error as? WalletError) {
                    let amountFormatted = Amount(
                        with: walletModel.blockchainNetwork.blockchain,
                        type: walletModel.amountType,
                        value: amount
                    ).string()

                    #warning("Use TransactionValidator async validate to get this warning before send tx")
                    let title = Localization.sendNotificationInvalidReserveAmountTitle(amountFormatted)
                    let message = Localization.sendNotificationInvalidReserveAmountText

                    alert = AlertBinder(title: title, message: message)
                } else {
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
                        error: (error as? SendTxError) ?? SendTxError(error: error),
                        openMailAction: openMail
                    )
                    .alertBinder
                }
            }
            .store(in: &bag)

        sendModel
            .transactionFinished
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else { return }

                openFinishPage()

                if walletModel.isDemo {
                    let button = Alert.Button.default(Text(Localization.commonOk)) {
                        self.coordinator?.dismiss()
                    }
                    alert = AlertBuilder.makeAlert(title: "", message: Localization.alertDemoFeatureDisabled, primaryButton: button)
                } else {
                    logTransactionAnalytics()
                }

                if let address = sendModel.destination?.value, let token = walletModel.tokenItem.token {
                    UserWalletFinder().addToken(token, in: walletModel.blockchainNetwork.blockchain, for: address)
                }
            }
            .store(in: &bag)
    }

    private func logTransactionAnalytics() {
        let sourceValue: Analytics.ParameterValue
        switch sendType {
        case .send:
            sourceValue = .transactionSourceSend
        case .sell:
            sourceValue = .transactionSourceSell
        }
        Analytics.log(event: .transactionSent, params: [
            .source: sourceValue.rawValue,
            .token: walletModel.tokenItem.currencySymbol,
            .blockchain: walletModel.blockchainNetwork.blockchain.displayName,
            .feeType: selectedFeeTypeAnalyticsParameter().rawValue,
            .memo: additionalFieldAnalyticsParameter().rawValue,
        ])

        Analytics.log(.sendSelectedCurrency, params: [
            .commonType: sendAmountViewModel.amountType.analyticParameter,
        ])
    }

//    private func nextStep(after step: SendStep) -> SendStep? {
//        guard
//            let currentStepIndex = steps.firstIndex(of: step),
//            (currentStepIndex + 1) < steps.count
//        else {
//            return nil
//        }
//
//        return steps[currentStepIndex + 1]
//    }

//    private func previousStep(before step: SendStep) -> SendStep? {
//        guard
//            let currentStepIndex = steps.firstIndex(of: step),
//            (currentStepIndex - 1) >= 0
//        else {
//            return nil
//        }
//
//        return steps[currentStepIndex - 1]
//    }

    private func openMail(with error: SendTxError) {
        guard let transaction = sendModel.currentTransaction() else { return }

        Analytics.log(.requestSupport, params: [.source: .transactionSourceSend])

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

//    private func showSummaryStepAlertIfNeeded(_ step: SendStep, stepAnimation: SendView.StepAnimation, checkCustomFee: Bool) -> Bool {
//        if checkCustomFee {
//            let events = notificationManager.notificationInputs.compactMap { $0.settings.event as? SendNotificationEvent }
//            for event in events {
//                switch event {
//                case .customFeeTooLow:
//                    Analytics.log(event: .sendNoticeTransactionDelaysArePossible, params: [
//                        .token: walletModel.tokenItem.currencySymbol,
//                    ])
//
//                    alert = SendAlertBuilder.makeCustomFeeTooLowAlert { [weak self] in
//                        self?.openStep(step, stepAnimation: stepAnimation, checkCustomFee: false, updateFee: false)
//                    }
//
//                    return true
//                case .customFeeTooHigh(let orderOfMagnitude):
//                    alert = SendAlertBuilder.makeCustomFeeTooHighAlert(orderOfMagnitude) { [weak self] in
//                        self?.openStep(step, stepAnimation: stepAnimation, checkCustomFee: false, updateFee: false)
//                    }
//
//                    return true
//                default:
//                    break
//                }
//            }
//        }
//
//        return false
//    }

//    private func mainButtonType(for step: SendStep) -> SendMainButtonType {
//        switch step {
//        case .amount, .destination, .fee:
//            if didReachSummaryScreen {
//                return .continue
//            } else {
//                return .next
//            }
//        case .summary:
//            return .send
//        case .finish:
//            return .close
//        }
//    }

    private func updateTransactionHistoryIfNeeded() {
        walletModel.updateTransactionHistoryIfNeeded()
            .sink()
            .store(in: &bag)
    }

    private func updateFee() {
        sendModel.updateFees()
    }

//    private func shouldCheckCustomFee(currentStep: SendStep) -> Bool {
//        switch currentStep {
//        case .fee:
//            return true
//        default:
//            return false
//        }
//    }

//    private func shouldUpdateFee(currentStep: SendStep, nextStep: SendStep) -> Bool {
//        if nextStep == .summary, currentStep.updateFeeOnLeave {
//            return true
//        } else if nextStep.updateFeeOnOpen {
//            return true
//        } else {
//            return false
//        }
//    }

//    private func openStep(_ step: SendStep, stepAnimation: SendView.StepAnimation, checkCustomFee: Bool = true, updateFee: Bool) {
//        let openStepAfterDelay = { [weak self] in
//            // Slight delay is needed, otherwise the animation of the keyboard will interfere with the page change
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                self?.openStep(step, stepAnimation: stepAnimation, checkCustomFee: checkCustomFee, updateFee: false)
//            }
//        }
//
//        if updateFee {
//            self.updateFee()
//            keyboardVisibilityService.hideKeyboard(completion: openStepAfterDelay)
//            return
//        }
//
//        if keyboardVisibilityService.keyboardVisible, !step.opensKeyboardByDefault {
//            keyboardVisibilityService.hideKeyboard(completion: openStepAfterDelay)
//            return
//        }
//
//        if case .summary = step {
//            if showSummaryStepAlertIfNeeded(step, stepAnimation: stepAnimation, checkCustomFee: checkCustomFee) {
//                return
//            }
//
//            didReachSummaryScreen = true
//
//            sendSummaryViewModel.setupAnimations(previousStep: self.step)
//        }
//
//        // Gotta give some time to update animation variable
//        self.stepAnimation = stepAnimation
//
//        mainButtonType = mainButtonType(for: step)
//
//        DispatchQueue.main.async {
//            self.showBackButton = self.previousStep(before: step) != nil && !self.didReachSummaryScreen
//            self.showTransactionButtons = self.sendModel.transactionURL != nil
//            self.step = step
//            self.transactionDescriptionIsVisisble = step == .summary
//        }
//    }

        if updateFee {
            self.updateFee()
            keyboardVisibilityService.hideKeyboard(completion: openStepAfterDelay)
            return
        }

        if keyboardVisibilityService.keyboardVisible, !step.opensKeyboardByDefault {
            keyboardVisibilityService.hideKeyboard(completion: openStepAfterDelay)
            return
        }

        if case .summary = step {
            if showSummaryStepAlertIfNeeded(step, stepAnimation: stepAnimation, checkCustomFee: checkCustomFee) {
                return
            }

            didReachSummaryScreen = true

            sendSummaryViewModel.setupAnimations(previousStep: self.step)
        }

        // Gotta give some time to update animation variable
        self.stepAnimation = stepAnimation

        mainButtonType = Self.mainButtonType(for: step, didReachSummaryScreen: didReachSummaryScreen)

        DispatchQueue.main.async {
            self.showBackButton = self.previousStep(before: step) != nil && !self.didReachSummaryScreen
            self.showTransactionButtons = self.sendModel.transactionURL != nil
            self.step = step
        }
    }

    private func openFinishPage() {
        openStep(.finish, stepAnimation: .moveAndFade, updateFee: false)
    }

    private func parseQRCode(_ code: String) {
        #warning("TODO: Add the necessary UI warnings")
        let parser = QRCodeParser(
            amountType: walletModel.amountType,
            blockchain: walletModel.blockchainNetwork.blockchain,
            decimalCount: walletModel.decimalCount
        )

        guard let result = parser.parse(code) else {
            return
        }

        sendDestinationViewModel.setExternally(address: SendAddress(value: result.destination, source: .qrCode), additionalField: result.memo)
        if let amount = result.amount {
            sendAmountViewModel.setExternalAmount(amount.value)
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
        if initial.feeOptions.count == 1 {
            return .transactionFeeFixed
        }

        switch sendModel.selectedFee?.option {
        case .none:
            assertionFailure("selectedFeeTypeAnalyticsParameter not found")
            return .null
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

    private func additionalFieldAnalyticsParameter() -> Analytics.ParameterValue {
        // If the blockchain doesn't support additional field -- return null
        // Otherwise return full / empty
        switch sendModel.destinationAdditionalField {
        case .notSupported: .null
        case .empty: .empty
        case .filled: .full
        }
    }

    // TODO: Andrey Fedorov - Re-use fee currency & redirect logic from Token Details & Send (IOS-5710)
    private func openNetworkCurrency() {
        guard
            let networkCurrencyWalletModel = userWalletModel.walletModelsManager.walletModels.first(where: {
                $0.tokenItem == walletModel.feeTokenItem && $0.blockchainNetwork == walletModel.blockchainNetwork
            })
        else {
            assertionFailure("Network currency WalletModel not found")
            return
        }

        coordinator?.openFeeCurrency(for: networkCurrencyWalletModel, userWalletModel: userWalletModel)
    }
}


// MARK: - SendModelUIDelegate

extension SendViewModel: SendModelUIDelegate {
    func showAlert(_ alert: AlertBinder) {
        self.alert = alert
    }
}

// MARK: - SendStepsManagerOutput

extension SendViewModel: SendStepsManagerOutput {
    func update(step: SendStep) {
        stepsManager.willOpen(step: step)
        self.step = step
        stepsManager.didOpen(step: step)
    }
    
    func update(animation: SendView.StepAnimation) {
        self.stepAnimation = animation
    }
    
    func update(mainButtonType: SendMainButtonType) {
        self.mainButtonType = mainButtonType
    }

    func update(backButtonVisible: Bool) {
        self.showBackButton = backButtonVisible
    }
}

// MARK: - NotificationTapDelegate

extension SendViewModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId) {}

    func didTapNotificationButton(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .refreshFee:
            sendModel.updateFees()
        case .openFeeCurrency:
            openNetworkCurrency()
        case .leaveAmount(let amount, _):
            reduceAmountBy(amount, from: walletInfo.balanceValue)
        case .reduceAmountBy(let amount, _):
            reduceAmountBy(amount, from: sendModel.amount?.crypto)
        case .reduceAmountTo(let amount, _):
            reduceAmountTo(amount)
        case .generateAddresses,
             .backupCard,
             .buyCrypto,
             .refresh,
             .goToProvider,
             .addHederaTokenAssociation,
             .bookNow,
             .stake,
             .openFeedbackMail,
             .openAppStoreReview:
            assertionFailure("Notification tap not handled")
        }
    }

    private func reduceAmountBy(_ amount: Decimal, from source: Decimal?) {
        guard let source else {
            assertionFailure("WHY")
            return
        }

        var newAmount = source - amount
        if sendModel.isFeeIncluded, let feeValue = sendModel.selectedFee?.value.value?.amount.value {
            newAmount = newAmount - feeValue
        }

        sendAmountViewModel.setExternalAmount(newAmount)
    }

    private func reduceAmountTo(_ amount: Decimal) {
        sendAmountViewModel.setExternalAmount(amount)
    }
}

// MARK: - SendStep

private extension SendStep {
//    var updateFeeOnLeave: Bool {
//        switch self {
//        case .destination, .amount:
//            return true
//        case .fee, .summary, .finish:
//            return false
//        }
//    }

    var isFinish: Bool {
        if case .finish = self {
            return true
        } else {
            return false
        }
    }

//    var updateFeeOnOpen: Bool {
//        switch self {
//        case .fee:
//            return true
//        case .destination, .amount, .summary, .finish:
//            return false
//        }
//    }

    var analyticsSourceParameterValue: Analytics.ParameterValue {
        switch self {
        case .amount:
            return .amount
        case .destination:
            return .address
        case .fee:
            return .fee
        case .summary:
            return .summary
        case .finish:
            return .finish
        }
    }
}

// MARK: - ValidationError

//private extension ValidationError {
//    var step: SendStep? {
//        switch self {
//        case .invalidAmount, .balanceNotFound:
//            // Shouldn't happen as we validate and cover amount errors separately, synchronously
//            return nil
//        case .amountExceedsBalance,
//             .invalidFee,
//             .feeExceedsBalance,
//             .maximumUTXO,
//             .reserve,
//             .dustAmount,
//             .dustChange,
//             .minimumBalance,
//             .totalExceedsBalance,
//             .cardanoHasTokens,
//             .cardanoInsufficientBalanceToSendToken:
//            return .summary
//        }
//    }
//}

private extension SendAmountCalculationType {
    var analyticParameter: Analytics.ParameterValue {
        switch self {
        case .crypto: .token
        case .fiat: .selectedCurrencyApp
        }
    }
}

extension SendViewModel {
    struct Initial {
        let tokenItem: TokenItem
        let walletName: String
        let feeOptions: [FeeOption]
    }
}

protocol SendStepsManagerInput: AnyObject {
    var currentStep: SendStep { get }
}

protocol SendStepsManagerOutput: AnyObject {
    func update(step: SendStep)
    func update(animation: SendView.StepAnimation)

    func update(mainButtonType: SendMainButtonType)
    func update(backButtonVisible: Bool)
}

protocol SendStepsManager {
    func willOpen(step: SendStep)
    func didOpen(step: SendStep)

    func willClose(step: SendStep)
    func didClose(step: SendStep)

    func userDidTapActionButton(mainButtonType: SendMainButtonType)
    func userDidTapBackButton()
}

class CommonSendStepsManager {
//    @Published var mainButtonType: SendMainButtonType
//    @Published var mainButtonLoading: Bool = false
//    @Published var mainButtonDisabled: Bool = false

    private let destinationStep: SendStep
    private let amountStep: SendStep
    private let feeStep: SendStep
    private let summaryStep: SendStep
    private let finishStep: SendStep

    private weak var input: SendStepsManagerInput?
    private weak var output: SendStepsManagerOutput?

    private var animationInProgress: Bool = false

    init(
        destinationStep: SendStep,
        amountStep: SendStep,
        feeStep: SendStep,
        summaryStep: SendStep,
        finishStep: SendStep,
        input: SendStepsManagerInput? = nil,
        output: SendStepsManagerOutput? = nil
    ) {
        self.destinationStep = destinationStep
        self.amountStep = amountStep
        self.feeStep = feeStep
        self.summaryStep = summaryStep
        self.finishStep = finishStep

        self.input = input
        self.output = output
    }


//    init(
//        input: SendStepsManagerInput?,
//        output: SendStepsManagerOutput?
//    ) {
//        self.steps = steps
//        self.input = input
//        self.output = output
//    }

    func back() {
        guard let previousStep = getPreviousStep() else {
            assertionFailure("Invalid step logic -- back")
            return
        }

        openStep(previousStep, animation: .slideBackward)
    }

    func proceed(action: SendMainButtonType) {
        // If we try to open another page mid-animation then the appropriate onAppear of the new page will not get called
        guard !animationInProgress else {
            return
        }

        switch action {
        case .next:
            guard let input, let next = getNextStep(), input.currentStep.canBeOpen(next: next) else {
                return
            }

            let animation: SendView.StepAnimation = {
                switch next {
                case .destination, .amount, .fee, .finish:
                    return .slideForward
                case .summary:
                    return .moveAndFade
                }
            }()

            openStep(next, animation: animation)
        case .continue:
            openStep(summaryStep, animation: .moveAndFade)
        case .send:
            sendModel.send()
        case .close:
            coordinator?.dismiss()
        }
    }

    private func getPreviousStep() -> SendStep? {
        switch input?.currentStep {
        case .none:
            return destinationStep
        case .destination:
            return amountStep
        case .amount:
            return destinationStep
        case .fee, .summary, .finish:
            assertionFailure("There is no previous step")
            return nil
        }
    }

    private func getNextStep() -> SendStep? {
        switch input?.currentStep {
        case .none:
            return destinationStep
        case .destination:
            return amountStep
        case .amount:
            return summaryStep
        case .fee, .summary, .finish:
            assertionFailure("There is no next step")
            return nil
        }
    }

    private func openStep(_ step: SendStep, animation: SendView.StepAnimation) {
        output?.update(animation: animation)
        input.map { step.willBeOpen(previous: $0.currentStep) }
        output?.update(step: step)
    }

//    private func openStep(_ step: SendStep, stepAnimation: SendView.StepAnimation, checkCustomFee: Bool = true, updateFee: Bool) {
//        let openStepAfterDelay = { [weak self] in
//            // Slight delay is needed, otherwise the animation of the keyboard will interfere with the page change
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                self?.openStep(step, stepAnimation: stepAnimation, checkCustomFee: checkCustomFee, updateFee: false)
//            }
//        }

//        if updateFee {
//            self.updateFee()
//            keyboardVisibilityService.hideKeyboard(completion: openStepAfterDelay)
//            return
//        }
//
//        if keyboardVisibilityService.keyboardVisible, !step.opensKeyboardByDefault {
//            keyboardVisibilityService.hideKeyboard(completion: openStepAfterDelay)
//            return
//        }

//        if case .summary = step {
//            if showSummaryStepAlertIfNeeded(step, stepAnimation: stepAnimation, checkCustomFee: checkCustomFee) {
//                return
//            }

//            didReachSummaryScreen = true

//            sendSummaryViewModel.setupAnimations(previousStep: self.step)
//        }

        // Gotta give some time to update animation variable
//        self.stepAnimation = stepAnimation

//        mainButtonType = self.mainButtonType(for: step)
//
//        DispatchQueue.main.async {
//            self.showBackButton = self.previousStep(before: step) != nil && !self.didReachSummaryScreen
//            self.showTransactionButtons = self.sendModel.transactionURL != nil
//            self.step = step
//            self.transactionDescriptionIsVisisble = step == .summary
//        }
//    }
}

// TODO: Update fee
// TODO: Update main button
// TODO: Show alert fee

// MARK: - SendStepsManager

extension CommonSendStepsManager: SendStepsManager {
    func willOpen(step: SendStep) {
        animationInProgress = true

        switch step {
        case .fee:
            // TODO: Update fee
            break
        case .destination, .amount, .summary, .finish:
            break
        }
    }
    
    func didOpen(step: SendStep) {
        animationInProgress = false
    }
    
    func willClose(step: SendStep) {
        switch step {
        case .destination, .amount:
            // TODO: Update fee
            break
        case .fee, .summary, .finish:
            break
        }
    }
    
    func didClose(step: SendStep) {
    }
    
    func userDidTapActionButton(mainButtonType: SendMainButtonType) {
        proceed(action: mainButtonType)
    }

    func userDidTapBackButton() {
        back()
    }
}

// MARK: - SendSummaryRoutable

extension CommonSendStepsManager: SendSummaryRoutable {
    func openStep(_ step: SendStep) {
        guard case .summary = input?.currentStep else {
            assertionFailure("This code should only be called from summary")
            return
        }

        if let auxiliaryViewAnimatable = auxiliaryViewAnimatable(step) {
            auxiliaryViewAnimatable.setAnimatingAuxiliaryViewsOnAppear()
        }

        openStep(step, animation: .moveAndFade)
    }

    private func auxiliaryViewAnimatable(_ step: SendStep) -> AuxiliaryViewAnimatable? {
        switch step {
        case .amount(let viewModel):
            return viewModel
        case .destination(let viewModel):
            return viewModel
        case .fee(let viewModel):
            return viewModel
        case .summary:
            return nil
        case .finish:
            return nil
        }
    }
}

