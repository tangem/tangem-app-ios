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

    // MARK: Blocks

    @Published var insightsViewModel: MarketsTokenDetailsInsightsViewModel?
    @Published var metricsViewModel: MarketsTokenDetailsMetricsViewModel?
    @Published var pricePerformanceViewModel: MarketsTokenDetailsPricePerformanceViewModel?
    @Published var linksSections: [TokenMarketsDetailsLinkSection] = []
    @Published var portfolioViewModel: MarketsPortfolioContainerViewModel?

    @Published var descriptionBottomSheetInfo: DescriptionBottomSheetInfo?

    @Injected(\.safariManager) var safariManager: SafariManager

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
    @Published private var currentPriceSubject: CurrentValueSubject<Decimal, Never>

    private weak var coordinator: TokenMarketsDetailsRoutable?

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
    private let dataProvider: MarketsTokenDetailsDataProvider
    private let walletDataProvider = MarketsWalletDataProvider()
    private var loadedInfo: TokenMarketsDetailsModel?
    private var bag = Set<AnyCancellable>()

    init(tokenInfo: MarketsTokenModel, dataProvider: MarketsTokenDetailsDataProvider, coordinator: TokenMarketsDetailsRoutable?) {
        currentPriceSubject = .init(tokenInfo.currentPrice ?? 0.0)
        self.tokenInfo = tokenInfo
        self.dataProvider = dataProvider
        self.coordinator = coordinator

        price = balanceFormatter.formatFiatBalance(
            tokenInfo.currentPrice,
            formattingOptions: fiatBalanceFormattingOptions
        )

        bind()
        loadedHistoryInfo = [Date().timeIntervalSince1970: tokenInfo.priceChangePercentage[MarketsPriceIntervalType.day.marketsListId] ?? 0]
        loadedPriceChangeInfo = tokenInfo.priceChangePercentage
        loadDetailedInfo()

        makePreloadBlocksViewModels()
    }

    private func bind() {
        currentPriceSubject
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, newPrice in
                viewModel.price = viewModel.balanceFormatter.formatFiatBalance(
                    newPrice,
                    formattingOptions: viewModel.fiatBalanceFormattingOptions
                )
            }
            .store(in: &bag)
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

        makeBlocksViewModels(using: model)
    }

    private func makePreloadBlocksViewModels() {
        portfolioViewModel = .init(
            userWalletModels: walletDataProvider.userWalletModels,
            coinId: tokenInfo.id,
            addTapAction: weakify(self, forFunction: TokenMarketsDetailsViewModel.onAddToPortfolioTapAction)
        )
    }

    private func makeBlocksViewModels(using model: TokenMarketsDetailsModel) {
        if let insights = model.insights {
            insightsViewModel = .init(insights: insights, infoRouter: self)
        }

        if let metrics = model.metrics {
            metricsViewModel = .init(metrics: metrics, infoRouter: self)
        }

        pricePerformanceViewModel = .init(pricePerformanceData: model.pricePerformance, currentPricePublisher: currentPriceSubject.eraseToAnyPublisher())

        linksSections = MarketsTokenDetailsLinksMapper(
            openLinkAction: weakify(self, forFunction: TokenMarketsDetailsViewModel.openLinkAction(_:))
        ).mapToSections(model.links)
    }

    private func log(_ message: @autoclosure () -> String) {
        AppLog.shared.debug("[TokenMarketsDetailsViewModel] - \(message())")
    }

    // MARK: - Actions

    func onAddToPortfolioTapAction() {
        guard let coinModel = loadedInfo?.coinModel, !coinModel.items.isEmpty else {
            assertionFailure("TokenItem list is empty")
            return
        }

        coordinator?.openTokenSelector(with: coinModel, with: walletDataProvider)
    }

    func openLinkAction(_ link: String) {
        guard let url = URL(string: link) else {
            log("Failed to create link from: \(link)")
            return
        }

        coordinator?.openURL(url)
    }
}

extension TokenMarketsDetailsViewModel {
    func openFullDescription() {
        guard let fullDescription else {
            return
        }

        openInfoBottomSheet(title: Localization.marketsTokenDetailsAboutTokenTitle(tokenInfo.name), message: fullDescription)
    }
}

extension TokenMarketsDetailsViewModel: MarketsTokenDetailsBottomSheetRouter {
    func openInfoBottomSheet(title: String, message: String) {
        descriptionBottomSheetInfo = .init(title: title, description: message)
    }
}
