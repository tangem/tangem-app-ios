//
//  WCCustomAllowanceViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BigInt

final class WCCustomAllowanceViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var amountText: String = ""
    @Published var isUnlimited: Bool = false
    @Published private(set) var isValidAmount: Bool = false
    @Published private(set) var canSubmit: Bool = false

    // MARK: - Dependencies

    private let input: WCCustomAllowanceInput
    private let amountConverter: WCCustomAllowanceAmountConverter

    private var bag: Set<AnyCancellable> = []

    // MARK: - Computed Properties

    var tokenSymbol: String {
        input.tokenInfo.symbol
    }

    var tokenIconURL: URL? {
        input.asset.logoURL
    }

    var asset: BlockaidChainScanResult.Asset {
        input.asset
    }

    // MARK: - Initialization

    init(input: WCCustomAllowanceInput) {
        self.input = input
        amountConverter = WCCustomAllowanceAmountConverter(tokenInfo: input.tokenInfo)

        setupInitialValues()
        bind()
    }

    // MARK: - View Actions

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .back:
            input.backAction()
        case .done:
            handleDoneAction()
        case .unlimitedToggled(let isUnlimited):
            handleUnlimitedToggle(isUnlimited)
        }
    }

    // MARK: - Private Methods

    private func setupInitialValues() {
        isUnlimited = input.approvalInfo.isUnlimited

        if !isUnlimited, let formattedAmount = amountConverter.formatBigUIntForInput(input.approvalInfo.amount) {
            amountText = formattedAmount
        } else {
            amountText = "∞"
        }
    }

    private func bind() {
        $amountText
            .combineLatest($isUnlimited)
            .map { [weak self] amountText, isUnlimited in
                self?.validateAmount(amountText: amountText, isUnlimited: isUnlimited) ?? false
            }
            .assign(to: \.isValidAmount, on: self)
            .store(in: &bag)

        $isValidAmount
            .assign(to: \.canSubmit, on: self)
            .store(in: &bag)
    }

    private func validateAmount(amountText: String, isUnlimited: Bool) -> Bool {
        if isUnlimited {
            return true
        }

        guard !amountText.isEmpty else {
            return false
        }

        guard let parsedAmount = amountConverter.parseInputToBigUInt(amountText) else {
            return false
        }

        return parsedAmount > 0
    }

    private func handleUnlimitedToggle(_ newValue: Bool) {
        isUnlimited = newValue

        amountText = isUnlimited ? "∞" : ""
    }

    private func handleDoneAction() {
        let finalAmount: BigUInt

        if isUnlimited {
            finalAmount = BigUInt.maxUInt256
        } else {
            guard let amount = amountConverter.parseInputToBigUInt(amountText) else {
                return
            }
            finalAmount = amount
        }

        input.updateAction(finalAmount)
    }
}

// MARK: - ViewAction

extension WCCustomAllowanceViewModel {
    enum ViewAction {
        case back
        case done
        case unlimitedToggled(Bool)
    }
}
