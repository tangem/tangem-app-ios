//
//  TransferInputViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemPay

@MainActor
final class TransferInputViewModel: ObservableObject {
    let amountFieldViewModel = DecimalNumberTextFieldViewModel(
        maximumFractionDigits: Constants.fractionDigits,
        locale: Locale(identifier: Constants.localeIdentifier)
    )

    @Published private(set) var selectedTokenID: TransferInputTokenItem.ID?
    @Published private(set) var selectedRail: TangemPayBankAccountRail?
    @Published private(set) var amountState: TransferInputAmountState = .empty
    @Published var isTokenModalPresented = false
    @Published var isRailModalPresented = false

    let title: String
    let stepSubtitle: String?
    let tokenItems: [TransferInputTokenItem]
    let railItems: [TransferInputRailItem]

    private let orderBuilder: TangemPayOfframpOrderBuilder
    private let analyticsLogger: any TangemPayOfframpAnalyticsLogger
    private let output: (Output) -> Void

    private var hasAppeared = false
    private var hasLoggedAmountEntered = false
    private var hasLoggedInsufficientFunds = false

    private var bag: Set<AnyCancellable> = []

    init(
        orderBuilder: TangemPayOfframpOrderBuilder,
        optionsStore: TangemPayOfframpOptionsStore,
        title: String,
        stepSubtitle: String?,
        analyticsLogger: any TangemPayOfframpAnalyticsLogger,
        output: @escaping (Output) -> Void
    ) {
        self.orderBuilder = orderBuilder
        self.title = title
        self.stepSubtitle = stepSubtitle
        self.analyticsLogger = analyticsLogger
        self.output = output

        let options = optionsStore.state.options ?? .empty
        tokenItems = options.tokens
        railItems = options.rails

        restore()
        applyDefaultSelection()
        revalidate()
        bind()
    }

    var contentState: TransferInputContentView.State {
        TransferInputContentView.State(
            token: selectedToken,
            rail: selectedRailItem,
            amountErrorMessage: amountState.errorMessage,
            isContinueEnabled: isContinueEnabled
        )
    }

    func handle(_ action: TransferInputContentView.Action) {
        switch action {
        case .tokenTap:
            analyticsLogger.logCoinSelectorClicked()
            analyticsLogger.logCoinSelectionSheetOpened()
            isTokenModalPresented = true
        case .railTap:
            analyticsLogger.logRailSelectorClicked()
            analyticsLogger.logRailSelectionSheetOpened()
            isRailModalPresented = true
        case .maxTap:
            applyMaxAmount()
        case .continueTap:
            submit()
        }
    }

    func onCloseTap() {
        output(.close)
    }

    func onAppear() {
        hasAppeared = true
        logInsufficientFundsIfNeeded()
    }
}

// MARK: - Derived state

private extension TransferInputViewModel {
    var selectedToken: TransferInputTokenItem? {
        tokenItems.first { $0.id == selectedTokenID }
    }

    var selectedRailItem: TransferInputRailItem? {
        railItems.first { $0.rail == selectedRail }
    }

    var isContinueEnabled: Bool {
        amountState.isValid && selectedToken != nil && selectedRail != nil
    }
}

// MARK: - Actions

private extension TransferInputViewModel {
    func applyMaxAmount() {
        guard let selectedToken else { return }
        guard let fee = selectedRailItem?.feeAmount else { return }

        let available = max(.zero, selectedToken.balance - fee)
        let amount = min(available, Constants.maxAmount)
            .rounded(scale: Constants.fractionDigits, roundingMode: .down)

        amountFieldViewModel.update(value: amount)
        revalidate()
    }

    func submit() {
        guard
            isContinueEnabled,
            let amount = amountFieldViewModel.value,
            let selectedToken,
            let selectedRail
        else {
            return
        }

        orderBuilder.set(amount: amount)
        orderBuilder.set(
            token: TangemPayOfframpTokenSelection(
                chainId: selectedToken.chainId,
                tokenContractAddress: selectedToken.contractAddress
            )
        )
        orderBuilder.set(rail: selectedRail)

        analyticsLogger.logAmountContinueClicked()
        output(.continueWizard)
    }
}

// MARK: - Modal bindings

extension TransferInputViewModel {
    var tokenSelectionBinding: Binding<TransferInputTokenItem.ID?> {
        Binding(
            get: { [weak self] in self?.selectedTokenID },
            set: { [weak self] in self?.selectToken(id: $0) }
        )
    }

    var railSelectionBinding: Binding<TangemPayBankAccountRail?> {
        Binding(
            get: { [weak self] in self?.selectedRail },
            set: { [weak self] in self?.selectRail($0) }
        )
    }
}

// MARK: - Selection

private extension TransferInputViewModel {
    func selectToken(id: TransferInputTokenItem.ID?) {
        guard let item = tokenItems.first(where: { $0.id == id }), item.isOfframpAvailable else {
            return
        }

        if item.id != selectedTokenID {
            analyticsLogger.logCoinInSelectionSheetClicked()
        }

        selectedTokenID = item.id
        isTokenModalPresented = false
        revalidate()
    }

    func selectRail(_ rail: TangemPayBankAccountRail?) {
        guard let rail, railItems.contains(where: { $0.rail == rail }) else { return }

        if rail != selectedRail {
            analyticsLogger.logRailInSelectionSheetClicked()
        }

        selectedRail = rail
        isRailModalPresented = false
        revalidate()
    }

    func applyDefaultSelection() {
        let available = tokenItems.filter(\.isOfframpAvailable)

        if selectedTokenID == nil || !available.contains(where: { $0.id == selectedTokenID }) {
            selectedTokenID = available.first?.id
        }

        if selectedRail == nil || !railItems.contains(where: { $0.rail == selectedRail }) {
            selectedRail = railItems.first?.rail
        }
    }
}

// MARK: - Restore

private extension TransferInputViewModel {
    func restore() {
        if let amount = orderBuilder.amount {
            amountFieldViewModel.update(value: amount)
            hasLoggedAmountEntered = true
        }

        selectedRail = orderBuilder.rail

        if let token = orderBuilder.token {
            selectedTokenID = TangemPayOfframpOptionsStore.tokenID(
                chainId: token.chainId,
                contractAddress: token.tokenContractAddress
            )
        }
    }

    func bind() {
        amountFieldViewModel
            .valuePublisher()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.revalidate()
            }
            .store(in: &bag)
    }

    func revalidate() {
        let amount = amountFieldViewModel.value

        amountState = Self.validate(
            amount: amount,
            balance: selectedToken?.balance,
            fee: selectedRailItem?.feeAmount ?? .zero
        )

        logAmountEnteredIfNeeded(amount: amount)
        logInsufficientFundsIfNeeded()
    }

    func logAmountEnteredIfNeeded(amount: Decimal?) {
        guard let amount, amount > 0, !hasLoggedAmountEntered else { return }

        hasLoggedAmountEntered = true
        analyticsLogger.logAmountEntered()
    }

    func logInsufficientFundsIfNeeded() {
        guard amountState == .notEnoughFunds else {
            hasLoggedInsufficientFunds = false
            return
        }

        guard hasAppeared, !hasLoggedInsufficientFunds else { return }

        hasLoggedInsufficientFunds = true
        analyticsLogger.logInsufficientFundsStateShowed()
    }
}

// MARK: - Validation

private extension TransferInputViewModel {
    static func validate(amount: Decimal?, balance: Decimal?, fee: Decimal) -> TransferInputAmountState {
        guard let amount, amount > 0 else {
            return .empty
        }

        guard amount >= Constants.minAmount, amount <= Constants.maxAmount else {
            return .outOfRange(min: Constants.minAmount, max: Constants.maxAmount)
        }

        if let balance, amount + fee > balance {
            return .notEnoughFunds
        }

        return .valid
    }
}

// MARK: - Output

extension TransferInputViewModel {
    enum Output {
        case continueWizard
        case close
    }
}

// MARK: - Constants

extension TransferInputViewModel {
    enum Constants {
        static let minAmount: Decimal = 1
        static let maxAmount: Decimal = 10_000
        static let fractionDigits = 2
        static let localeIdentifier = "en_US"
    }
}
