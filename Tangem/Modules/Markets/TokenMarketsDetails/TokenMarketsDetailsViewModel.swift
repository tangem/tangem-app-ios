//
//  TokenMarketsDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class TokenMarketsDetailsViewModel: ObservableObject {
    @Published var price: String
    @Published var shortDescription: String?
    @Published var fullDescription: String?
    @Published var selectedPriceChangeIntervalType = MarketsPriceIntervalType.day
    @Published var isLoading = true
    @Published var alert: AlertBinder?

    let priceChangeIntervalOptions = MarketsPriceIntervalType.allCases

    var priceChangeState: TokenPriceChangeView.State {
        guard let pickedDate else {
            let changePercent = loadedPriceChangeInfo[selectedPriceChangeIntervalType.rawValue]
            return priceChangeUtility.convertToPriceChangeState(changePercent: changePercent)
        }

        // [REDACTED_TODO_COMMENT]
        print("Price change state for picked date: \(pickedDate)")
        return .noData
    }

    var tokenName: String {
        tokenInfo.name
    }

    var priceDate: String {
        guard let pickedDate else {
            return Localization.commonToday
        }

        return "\(dateFormatter.string(from: pickedDate)) – \(Localization.commonNow)"
    }

    var pickedDate: Date? {
        guard let pickedTimeInterval else {
            return nil
        }

        return Date(timeIntervalSince1970: pickedTimeInterval)
    }

    var iconURL: URL {
        let iconBuilder = IconURLBuilder()
        return iconBuilder.tokenIconURL(id: tokenInfo.id, size: .large)
    }

    @Published private var pickedTimeInterval: TimeInterval?
    @Published private var loadedHistoryInfo: [TimeInterval: Decimal] = [:]
    @Published private var loadedPriceChangeInfo: [String: Decimal] = [:]

    private weak var coordinator: TokenMarketsDetailsRoutable?

    private var dataSource = MarketsDataSource()

    private let balanceFormatter = BalanceFormatter()
    private let priceChangeUtility = PriceChangeUtility()
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM, HH:MM"
        return dateFormatter
    }()

    private let fiatBalanceFormattingOptions: BalanceFormattingOptions = .init(
        minFractionDigits: 2,
        maxFractionDigits: 8,
        formatEpsilonAsLowestRepresentableValue: false,
        roundingType: .defaultFiat(roundingMode: .bankers)
    )

    private let tokenInfo: MarketsTokenModel
    private let dataProvider: TokenMarketsDetailsDataProvider
    private var loadedInfo: TokenMarketsDetailsModel?

    init(tokenInfo: MarketsTokenModel, dataProvider: TokenMarketsDetailsDataProvider, coordinator: TokenMarketsDetailsRoutable?) {
        self.tokenInfo = tokenInfo
        self.dataProvider = dataProvider
        self.coordinator = coordinator

        price = balanceFormatter.formatFiatBalance(
            tokenInfo.currentPrice,
            formattingOptions: fiatBalanceFormattingOptions
        )

        loadedHistoryInfo = [Date().timeIntervalSince1970: tokenInfo.priceChangePercentage[MarketsPriceIntervalType.day.marketsListId] ?? 0]
        loadedPriceChangeInfo = tokenInfo.priceChangePercentage
        loadDetailedInfo()
    }

    private func loadDetailedInfo() {
        runTask(in: self) { viewModel in
            do {
                viewModel.log("Attempt to load token markets data for token with id: \(viewModel.tokenInfo.id)")
                let result = try await viewModel.dataProvider.loadTokenMarketsDetails(for: viewModel.tokenInfo.id)

                await runOnMain {
                    viewModel.setupUI(using: result)
                    viewModel.isLoading = false
                }
            } catch {
                await runOnMain { viewModel.alert = error.alertBinder }
                viewModel.log("Failed to load detailed info. Reason: \(error)")
            }
        }
    }

    private func setupUI(using model: TokenMarketsDetailsModel) {
        price = balanceFormatter.formatFiatBalance(model.currentPrice, formattingOptions: fiatBalanceFormattingOptions)
        loadedPriceChangeInfo = model.priceChangePercentage
        loadedInfo = model
        shortDescription = model.shortDescription
        fullDescription = model.fullDescription
    }

    private func log(_ message: @autoclosure () -> String) {
        AppLog.shared.debug("[TokenMarketsDetailsViewModel] - \(message())")
    }

    // MARK: - Actions

    func onAddToPortfolioTapAction() {
        guard let tokenItems = loadedInfo?.tokenItems, !tokenItems.isEmpty else {
            assertionFailure("TokenItem list is empty")
            return
        }

        coordinator?.openTokenSelector(dataSource: dataSource, coinId: tokenInfo.id, tokenItems: tokenItems)
    }
}

extension TokenMarketsDetailsViewModel {
    func openFullDescription() {
        print("Open full description tapped")
    }
}
