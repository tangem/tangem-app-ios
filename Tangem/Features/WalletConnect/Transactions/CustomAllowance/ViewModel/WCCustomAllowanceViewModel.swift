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

final class WCCustomAllowanceViewModel: ObservableObject, Identifiable {
    let id = UUID()

    @Published var amountText: String = ""
    @Published var isUnlimited: Bool = false
    @Published private(set) var isValidAmount: Bool = false
    @Published private(set) var canSubmit: Bool = false

    private let input: WCCustomAllowanceInput
    private let amountConverter: WCCustomAllowanceAmountConverter

    private var bag: Set<AnyCancellable> = []

    var tokenSymbol: String {
        input.tokenInfo.symbol
    }

    var tokenIconURL: URL? {
        input.asset.logoURL
    }

    var asset: BlockaidChainScanResult.Asset {
        input.asset
    }

    init(input: WCCustomAllowanceInput) {
        self.input = input
        amountConverter = WCCustomAllowanceAmountConverter(tokenInfo: input.tokenInfo)

        setupInitialValues()
        bind()
    }

    @MainActor
    func handleViewAction(_ action: ViewAction) async {
        switch action {
        case .done:
            await handleDoneAction()
        case .unlimitedToggled(let isUnlimited):
            handleUnlimitedToggle(isUnlimited)
        }
    }

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
            .assign(to: \.isValidAmount, on: self, ownership: .weak)
            .store(in: &bag)

        $isValidAmount
            .assign(to: \.canSubmit, on: self, ownership: .weak)
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

    @MainActor
    private func handleDoneAction() async {
        let finalAmount: BigUInt

        if isUnlimited {
            finalAmount = BigUInt.maxUInt256
        } else {
            guard let amount = amountConverter.parseInputToBigUInt(amountText) else {
                return
            }
            finalAmount = amount
        }

        await input.updateAction(finalAmount)
    }
}

extension WCCustomAllowanceViewModel {
    enum ViewAction {
        case done
        case unlimitedToggled(Bool)
    }
}
