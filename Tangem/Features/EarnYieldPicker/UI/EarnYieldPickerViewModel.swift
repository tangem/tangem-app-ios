//
//  EarnYieldPickerViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemLocalization

@MainActor
final class EarnYieldPickerViewModel: ObservableObject {
    @Published private(set) var selectedProduct: EarnYieldPickerProduct
    @Published private(set) var calculator: EarnCalculatorViewModel
    @Published private(set) var primaryAction: PrimaryAction

    let products: [EarnYieldPickerProduct]
    let video: LoopingVideoBackgroundViewModel

    var sections: [EarnYieldPickerSection] {
        EarnYieldPickerSection.allCases.filter { section in
            section != .benefits || selectedProduct.details.benefits.isNotEmpty
        }
    }

    var incentiveBadgeText: String? {
        selectedProduct.incentiveApy.map { apy in
            Localization.yieldModulePromoScreenIncentivisedChip(percentFormatter.format(apy, option: .yieldPromo))
        }
    }

    private let currencyCode: String
    private let percentFormatter: PercentFormatter
    private weak var coordinator: EarnYieldPickerRoutable?

    init?(
        products: [EarnYieldPickerProduct],
        selectedProductID: EarnYieldPickerProduct.ID,
        balanceProvider: TokenBalanceProvider,
        currencyCode: String,
        percentFormatter: PercentFormatter = PercentFormatter(),
        videoProvider: LoopingVideoBackgroundProvider = EarnYieldPickerVideoProvider(),
        coordinator: EarnYieldPickerRoutable?
    ) {
        guard let selectedProduct = products.first(where: { $0.id == selectedProductID }) ?? products.first else {
            return nil
        }

        self.products = products
        self.selectedProduct = selectedProduct
        primaryAction = PrimaryAction(isFunded: balanceProvider.isFunded)
        video = LoopingVideoBackgroundViewModel(provider: videoProvider)
        self.currencyCode = currencyCode
        self.percentFormatter = percentFormatter
        self.coordinator = coordinator
        calculator = Self.makeCalculator(for: selectedProduct, input: .default, currencyCode: currencyCode)

        balanceProvider.balanceTypePublisher
            .map { _ in PrimaryAction(isFunded: balanceProvider.isFunded) }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$primaryAction)
    }

    // [REDACTED_TODO_COMMENT]
    func rate(of product: EarnYieldPickerProduct) -> String {
        "\(percentFormatter.format(product.apy, option: .yieldPickerRate)) APY"
    }

    func select(_ product: EarnYieldPickerProduct) {
        guard product.id != selectedProduct.id else {
            return
        }

        selectedProduct = product
        calculator = Self.makeCalculator(for: product, input: calculator.input, currencyCode: currencyCode)
    }

    func onPrimaryActionTap() {
        switch primaryAction {
        case .startEarning:
            coordinator?.openStartEarning(for: selectedProduct)
        case .addFunds:
            coordinator?.openAddFunds()
        }
    }

    func onIncentiveInfoTap() {
        coordinator?.openIncentiveInfo(for: selectedProduct)
    }

    func onLinkTap(_ url: URL) {
        coordinator?.openURL(url)
    }

    func onClose() {
        coordinator?.dismissYieldPicker()
    }
}

// MARK: - PrimaryAction

extension EarnYieldPickerViewModel {
    enum PrimaryAction {
        case startEarning
        case addFunds

        init(isFunded: Bool) {
            self = isFunded ? .startEarning : .addFunds
        }
    }
}

// MARK: - Private

private extension EarnYieldPickerViewModel {
    static func makeCalculator(
        for product: EarnYieldPickerProduct,
        input: EarnCalculatorInput,
        currencyCode: String
    ) -> EarnCalculatorViewModel {
        EarnCalculatorViewModel(
            input: input,
            incentiveApy: product.incentiveApy,
            projector: CompoundingEarnCalculatorProjector(apy: product.apy, performanceFee: product.performanceFee),
            currencyCode: currencyCode
        )
    }
}
