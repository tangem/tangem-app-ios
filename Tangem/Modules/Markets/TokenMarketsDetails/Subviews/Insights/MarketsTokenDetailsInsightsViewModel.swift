//
//  MarketsTokenDetailsInsightsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol MarketsTokenDetailsBottomSheetRouter: AnyObject {
    func openInfoBottomSheet(title: String, message: String)
}

protocol MarketsTokenDetailsInfoDescriptionProvider {
    var title: String { get }
    var infoDescription: String { get }
}

class MarketsTokenDetailsInsightsViewModel: ObservableObject {
    @Published var selectedInterval: MarketsPriceIntervalType = .day

    let availableIntervals: [MarketsPriceIntervalType] = [.day, .week, .month]

    var records: [MarketsTokenDetailsInsightsView.RecordInfo] {
        intervalInsights[selectedInterval] ?? []
    }

    private var bag = Set<AnyCancellable>()

    private let fiatAmountFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        BalanceFormatter().prepareFiatFormatter(for: AppSettings.shared.selectedCurrencyCode, formatter: numberFormatter)

        return numberFormatter
    }()

    private let nonCurrencyFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = .current
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.currencySymbol = ""
        return numberFormatter
    }()

    private let notationFormatter: DefaultAmountNotationFormatter

    private weak var infoRouter: MarketsTokenDetailsBottomSheetRouter?
    private var intervalInsights: [MarketsPriceIntervalType: [MarketsTokenDetailsInsightsView.RecordInfo]] = [:]

    init(
        insights: TokenMarketsDetailsInsights,
        notationFormatter: DefaultAmountNotationFormatter,
        infoRouter: MarketsTokenDetailsBottomSheetRouter?
    ) {
        self.notationFormatter = notationFormatter
        self.infoRouter = infoRouter

        setupInsights(using: insights)
    }

    func showInfoBottomSheet(for infoProvider: MarketsTokenDetailsInfoDescriptionProvider) {
        infoRouter?.openInfoBottomSheet(title: infoProvider.title, message: infoProvider.infoDescription)
    }

    private func setupInsights(using insights: TokenMarketsDetailsInsights) {
        let amountNotationFormatter = AmountNotationSuffixFormatter(divisorsList: AmountNotationSuffixFormatter.Divisor.withHundredThousands)

        intervalInsights = availableIntervals.reduce(into: [:]) { partialResult, interval in
            let buyers = notationFormatter.format(
                insights.experiencedBuyers[interval],
                notationFormatter: amountNotationFormatter,
                numberFormatter: nonCurrencyFormatter,
                addingSignPrefix: true
            )
            let holders = notationFormatter.format(
                insights.holders[interval],
                notationFormatter: amountNotationFormatter,
                numberFormatter: nonCurrencyFormatter,
                addingSignPrefix: true
            )

            let liquidity = notationFormatter.format(
                insights.liquidity[interval],
                notationFormatter: amountNotationFormatter,
                numberFormatter: fiatAmountFormatter,
                addingSignPrefix: true
            )
            let buyPressure = notationFormatter.format(
                insights.buyPressure[interval],
                notationFormatter: amountNotationFormatter,
                numberFormatter: fiatAmountFormatter,
                addingSignPrefix: true
            )

            partialResult[interval] = [
                .init(type: .buyers, recordData: buyers),
                .init(type: .buyPressure, recordData: buyPressure),
                .init(type: .holdersChange, recordData: holders),
                .init(type: .liquidity, recordData: liquidity),
            ]
        }
    }

    private func bind() {
        $selectedInterval
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { value in
                let weakSelf = value.0
                let interval = value.1

                Analytics.log(
                    event: .marketsButtonPeriod,
                    params: [
                        .period: interval.rawValue,
                        .source: Analytics.MarketsIntervalTypeSourceType.insights.rawValue,
                    ]
                )
            })
            .store(in: &bag)
    }
}
