//
//  LendingDepositAmountViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemLocalization

final class LendingDepositAmountViewModel: ObservableObject {
    typealias StateModel = LendingAmountContentView.StateModel
    typealias Action = LendingDepositAmountContentView.Action

    let amountField: AmountInputFieldModel

    @Published private(set) var state: StateModel

    private let transferModel: TransferModel
    private let sourceToken: SendTransferableToken
    private let analyticsLogger: LendingAnalyticsLogger
    private let interactor: SendAmountInteractor
    private weak var router: LendingDepositAmountRoutable?
    private var lastLoadedFee: Decimal?
    private var pendingSharePercent: Int?
    private var initialFeeEstimate: AnyCancellable?
    private let isShown = CurrentValueSubject<Bool, Never>(false)
    private var feeRefresh: Task<Void, Never>?
    private let isFeeOutdated = CurrentValueSubject<Bool, Never>(false)
    private var bag: Set<AnyCancellable> = []

    init(
        transferModel: TransferModel,
        sourceToken: SendTransferableToken,
        analyticsLogger: LendingAnalyticsLogger,
        router: LendingDepositAmountRoutable?
    ) {
        self.transferModel = transferModel
        self.sourceToken = sourceToken
        self.analyticsLogger = analyticsLogger
        self.router = router

        interactor = CommonSendAmountInteractor(
            sourceTokenInput: transferModel,
            sourceTokenAmountInput: transferModel,
            receiveTokenInput: nil,
            receiveTokenOutput: nil,
            receiveTokenAmountInput: nil,
            receiveTokenAmountOutput: nil,
            validator: CommonSendAmountValidator(input: transferModel),
            amountModifier: nil,
            notificationService: nil,
            saver: CommonSendAmountInteractorSaver(
                sourceTokenAmountInput: transferModel,
                sourceTokenAmountOutput: transferModel,
                receiveTokenInput: nil,
                receiveTokenOutput: nil
            )
        )

        amountField = AmountInputFieldModel(tokenItem: sourceToken.tokenItem, fiatItem: sourceToken.fiatItem)
        state = StateModel(
            header: Self.header(sourceToken.header),
            source: LendingAmountContentView.Source(
                tokenIconInfo: TokenIconInfoBuilder().build(from: sourceToken.tokenItem, isCustom: sourceToken.isCustom),
                title: sourceToken.tokenItem.currencySymbol,
                subtitle: ""
            ),
            fee: .loading,
            canChangeFeeSpeed: false,
            notice: nil,
            // [REDACTED_TODO_COMMENT]
            submitTitle: "Deposit",
            isSubmitEnabled: false
        )

        bind()
    }

    func onAppear() {
        isShown.send(true)

        guard initialFeeEstimate == nil else {
            return
        }

        initialFeeEstimate = sourceToken.availableBalanceProvider.balanceTypePublisher
            .compactMap(\.value)
            .first()
            .receiveOnMain()
            .sink { [transferModel] _ in
                transferModel.updateFees(amountOrBalance: transferModel.sourceAmount.value?.crypto)
            }
    }

    func onDisappear() {
        isShown.send(false)
    }

    func handle(_ action: Action) {
        switch action {
        case .info:
            router?.openHowItWorks()
        case .close:
            router?.closeDeposit()
        case .max:
            analyticsLogger.logMax()
            applyShare(percent: 100)
        case .share(let percent):
            analyticsLogger.logPercent(percent)
            applyShare(percent: percent)
        case .fee:
            router?.openFeeSelector()
        case .retryFee:
            transferModel.updateFees(amountOrBalance: transferModel.sourceAmount.value?.crypto)
        case .deposit:
            router?.openConfirmation()
        }
    }
}

// MARK: - Private

private extension LendingDepositAmountViewModel {
    static func header(_ header: TokenHeader) -> LendingAmountContentView.Header {
        switch header {
        case .account(let name, let icon): .account(name: name, icon: icon)
        case .wallet(let name, _): .wallet(name: name)
        }
    }

    var balance: Decimal {
        sourceToken.availableBalanceProvider.balanceType.value ?? 0
    }

    var amountFeeBalancePublisher: AnyPublisher<AmountFeeBalance, Never> {
        Publishers.CombineLatest3(
            transferModel.sourceAmountPublisher.map { $0.value?.crypto },
            transferModel.selectedFeePublisher.compactMap { $0.value.value?.amount.value }.map(Optional.some).prepend(nil),
            sourceToken.availableBalanceProvider.balanceTypePublisher.map(\.value)
        )
        .map(AmountFeeBalance.init(amount:fee:balance:))
        .eraseToAnyPublisher()
    }

    func bind() {
        amountField.onValueChanged = { [weak self] value in
            guard let self else { return }

            pendingSharePercent = nil
            let amount = try? interactor.update(sourceAmount: value)
            amountField.updateAlternativeUI(amount: amount)
        }

        amountField.$amountType
            .dropFirst()
            .removeDuplicates()
            .receiveOnMain()
            .sink { [weak self] amountType in
                guard let self else { return }

                analyticsLogger.logCurrencyToggled(to: amountType)
                let amount = try? interactor.update(sourceType: amountType)
                amountField.updateAmountsUI(amount: amount)
            }
            .store(in: &bag)

        Publishers.CombineLatest(interactor.sourceFieldInfoPublisher, amountFeeBalancePublisher)
            .map { [currencySymbol = sourceToken.tokenItem.currencySymbol] info, input in
                Self.bottomInfo(interactorInfo: info, amount: input.amount, fee: input.fee, balance: input.balance, currencySymbol: currencySymbol)
            }
            .removeDuplicates()
            .receiveOnMain()
            .sink { [weak self] info in
                self?.amountField.bottomInfoText = info
            }
            .store(in: &bag)

        Publishers.CombineLatest(
            amountFeeBalancePublisher
                .scan((previous: AmountFeeBalance?.none, current: AmountFeeBalance?.none)) { inputs, input in
                    (previous: inputs.current, current: Optional(input))
                }
                .map { inputs -> LendingAnalyticsLogger.Notice? in
                    guard let current = inputs.current, !Self.isAmountAboutToBeCapped(previous: inputs.previous, current: current) else {
                        return nil
                    }

                    return LendingAnalyticsLogger.Notice.deposit(amount: current.amount, fee: current.fee, balance: current.balance)
                },
            isShown
        )
        .map { notice, isShown in isShown ? notice : nil }
        .removeDuplicates()
        .compactMap { $0 }
        .sink { [analyticsLogger] notice in
            analyticsLogger.logNotice(notice)
        }
        .store(in: &bag)

        sourceToken.availableBalanceProvider.formattedBalanceTypePublisher
            .receiveOnMain()
            .sink { [weak self] balance in
                self?.state.source.subtitle = Localization.commonBalance(balance.value)
            }
            .store(in: &bag)

        transferModel.selectedFeePublisher
            .receiveOnMain()
            .sink { [weak self] tokenFee in
                self?.feeDidChange(tokenFee)
            }
            .store(in: &bag)

        transferModel.supportFeeSelectionPublisher
            .receiveOnMain()
            .sink { [weak self] canChangeFeeSpeed in
                self?.state.canChangeFeeSpeed = canChangeFeeSpeed
            }
            .store(in: &bag)

        Publishers.CombineLatest4(
            transferModel.isReadyToSendPublisher,
            isFeeOutdated,
            interactor.isValidPublisher,
            amountFeeBalancePublisher.map { Self.fitsBalance(amount: $0.amount, fee: $0.fee, balance: $0.balance) }
        )
        .map { isReadyToSend, isFeeOutdated, isAmountValid, fitsBalance in
            isReadyToSend && !isFeeOutdated && isAmountValid && fitsBalance
        }
        .removeDuplicates()
        .receiveOnMain()
        .sink { [weak self] isDepositEnabled in
            self?.state.isSubmitEnabled = isDepositEnabled
        }
        .store(in: &bag)

        transferModel.sourceAmountPublisher
            .map { $0.value?.crypto }
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                self?.isFeeOutdated.send(true)
            }
            .store(in: &bag)

        transferModel.sourceAmountPublisher
            .map { $0.value?.crypto }
            .removeDuplicates()
            .dropFirst()
            .debounce(for: Constants.feeUpdateDelay, scheduler: DispatchQueue.main)
            .sink { [weak self] amount in
                self?.refreshFee(amount: amount)
            }
            .store(in: &bag)
    }

    func refreshFee(amount: Decimal?) {
        transferModel.updateFees(amountOrBalance: amount)

        feeRefresh?.cancel()
        feeRefresh = Task { @MainActor [weak self, feeUpdate = transferModel.feeUpdateTask] in
            await feeUpdate?.value

            guard let self, !Task.isCancelled, transferModel.sourceAmount.value?.crypto == amount else {
                return
            }

            isFeeOutdated.send(false)
        }
    }

    func feeDidChange(_ tokenFee: TokenFee) {
        state.fee = LendingFee(tokenFee)

        guard case .success(let fee) = tokenFee.value else {
            return
        }

        if let lastLoadedFee {
            capAmountIfNewFeeNoLongerFits(previousFee: lastLoadedFee, fee: fee.amount.value)
        }

        lastLoadedFee = fee.amount.value

        if let pendingSharePercent {
            self.pendingSharePercent = nil
            setShare(percent: pendingSharePercent)
        }
    }

    func capAmountIfNewFeeNoLongerFits(previousFee: Decimal, fee: Decimal) {
        guard let amount = transferModel.sourceAmount.value?.crypto,
              Self.newFeeNoLongerFits(amount: amount, previousFee: previousFee, fee: fee, balance: balance) else {
            return
        }

        setShare(percent: 100)
    }

    static func newFeeNoLongerFits(amount: Decimal, previousFee: Decimal, fee: Decimal, balance: Decimal) -> Bool {
        amount + previousFee <= balance && amount + fee > balance
    }

    static func isAmountAboutToBeCapped(previous: AmountFeeBalance?, current: AmountFeeBalance) -> Bool {
        guard let previous,
              previous.amount == current.amount,
              let amount = current.amount,
              let previousFee = previous.fee,
              let fee = current.fee,
              let balance = current.balance else {
            return false
        }

        return newFeeNoLongerFits(amount: amount, previousFee: previousFee, fee: fee, balance: balance)
    }

    static func bottomInfo(
        interactorInfo: SendAmountViewModel.BottomInfoTextType?,
        amount: Decimal?,
        fee: Decimal?,
        balance: Decimal?,
        currencySymbol: String
    ) -> SendAmountViewModel.BottomInfoTextType? {
        guard !fitsBalance(amount: amount, fee: fee, balance: balance) else {
            return interactorInfo
        }

        // [REDACTED_TODO_COMMENT]
        return .error("Not enough \(currencySymbol)")
    }

    static func fitsBalance(amount: Decimal?, fee: Decimal?, balance: Decimal?) -> Bool {
        guard let balance else {
            return true
        }

        return (amount ?? 0) + (fee ?? 0) <= balance
    }

    func applyShare(percent: Int) {
        guard hasFeeEstimate else {
            pendingSharePercent = percent
            return
        }

        setShare(percent: percent)
    }

    var hasFeeEstimate: Bool {
        lastLoadedFee != nil || transferModel.selectedFee?.value.value != nil
    }

    func setShare(percent: Int) {
        let fee = transferModel.selectedFee?.value.value?.amount.value ?? lastLoadedFee ?? 0
        let share = (max(balance - fee, 0) * Decimal(percent) / 100)
            .rounded(scale: sourceToken.tokenItem.decimalCount, roundingMode: .down)

        let amount = try? interactor.update(sourceCryptoAmount: share)
        amountField.updateAmountsUI(amount: amount)
    }
}

// MARK: - AmountFeeBalance

extension LendingDepositAmountViewModel {
    struct AmountFeeBalance {
        let amount: Decimal?
        let fee: Decimal?
        let balance: Decimal?
    }
}

// MARK: - Constants

private extension LendingDepositAmountViewModel {
    enum Constants {
        static let feeUpdateDelay: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(300)
    }
}
