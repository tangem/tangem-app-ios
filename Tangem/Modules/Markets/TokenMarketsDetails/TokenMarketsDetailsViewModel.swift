//
//  TokenMarketsDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit // [REDACTED_TODO_COMMENT]

class TokenMarketsDetailsViewModel: ObservableObject {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    @Published private(set) var price: String?
    @Published private(set) var priceChangeState: TokenPriceChangeView.State?
    @Published var priceChangeAnimation: ForegroundBlinkAnimationModifier.Change = .neutral
    @Published var selectedPriceChangeIntervalType: MarketsPriceIntervalType
    @Published var isLoading = true
    @Published var alert: AlertBinder?
    @Published var state: ViewState = .loading

    // MARK: Blocks

    @Published var insightsViewModel: MarketsTokenDetailsInsightsViewModel?
    @Published var metricsViewModel: MarketsTokenDetailsMetricsViewModel?
    @Published var pricePerformanceViewModel: MarketsTokenDetailsPricePerformanceViewModel?
    @Published var linksSections: [TokenMarketsDetailsLinkSection] = []
    @Published var portfolioViewModel: MarketsPortfolioContainerViewModel?
    @Published private(set) var historyChartViewModel: MarketsHistoryChartViewModel? // [REDACTED_TODO_COMMENT]

    @Published var descriptionBottomSheetInfo: DescriptionBottomSheetInfo?

    @Published private var selectedDate: Date?
    @Published private var loadedPriceChangeInfo: [String: Decimal] = [:]

    var tokenName: String {
        tokenInfo.name
    }

    var priceDate: String {
        guard let selectedDate else {
            // [REDACTED_TODO_COMMENT]
            return selectedPriceChangeIntervalType == .all ? Localization.commonAll : Localization.commonToday
        }

        return "\(dateFormatter.string(from: selectedDate)) – \(Localization.commonNow)"
    }

    var iconURL: URL {
        let iconBuilder = IconURLBuilder()
        return iconBuilder.tokenIconURL(id: tokenInfo.id, size: .large)
    }

    var priceChangeIntervalOptions: [MarketsPriceIntervalType] {
        return MarketsPriceIntervalType.allCases
    }

    var allDataLoadFailed: Bool {
        state == .failedToLoadAllData
    }

    private weak var coordinator: TokenMarketsDetailsRoutable?

    private let balanceFormatter = BalanceFormatter()

    // The date when this VM was initialized (i.e. the screen was opened)
    private let initialDate = Date()

    // [REDACTED_TODO_COMMENT]
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM, HH:mm"
        return dateFormatter
    }()

    private let fiatBalanceFormattingOptions: BalanceFormattingOptions = .init(
        minFractionDigits: 2,
        maxFractionDigits: 8,
        formatEpsilonAsLowestRepresentableValue: false,
        roundingType: .defaultFiat(roundingMode: .bankers)
    )
    private let currentPriceSubject: CurrentValueSubject<Decimal, Never>
    private let quotesUpdateTimeInterval: TimeInterval = 60.0

    private let tokenInfo: MarketsTokenModel
    private let dataProvider: MarketsTokenDetailsDataProvider
    private let walletDataProvider = MarketsWalletDataProvider()

    private var loadedInfo: TokenMarketsDetailsModel?
    private var loadingTask: AnyCancellable?
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(tokenInfo: MarketsTokenModel, dataProvider: MarketsTokenDetailsDataProvider, coordinator: TokenMarketsDetailsRoutable?) {
        currentPriceSubject = .init(tokenInfo.currentPrice ?? 0.0)
        self.tokenInfo = tokenInfo
        self.dataProvider = dataProvider
        self.coordinator = coordinator
        selectedPriceChangeIntervalType = .day
        loadedPriceChangeInfo = tokenInfo.priceChangePercentage

        updatePriceInfo(externallySelectedPrice: nil, selectedPriceChangeIntervalType: selectedPriceChangeIntervalType)
        bind()
        loadDetailedInfo()
        makePreloadBlocksViewModels()
        makeHistoryChartViewModel()
        bindToHistoryChartViewModel()
    }

    deinit {
        print("TokenMarketsDetailsViewModel deinit")
        loadingTask?.cancel()
        loadingTask = nil
    }

    // MARK: - Actions

    func reloadAllData() {
        loadDetailedInfo()
        historyChartViewModel?.reload()
    }

    func loadDetailedInfo() {
        isLoading = true
        loadingTask?.cancel()
        loadingTask = runTask(in: self) { viewModel in
            do {
                let currencyId = viewModel.tokenInfo.id
                viewModel.log("Attempt to load token markets data for token with id: \(currencyId)")
                let result = try await viewModel.dataProvider.loadTokenMarketsDetails(for: currencyId)
                await viewModel.handleLoadDetailedInfo(.success(result))
            } catch {
                await viewModel.handleLoadDetailedInfo(.failure(error))
            }
            viewModel.loadingTask = nil
        }.eraseToAnyCancellable()
    }

    func openLinkAction(_ link: String) {
        guard let url = URL(string: link) else {
            log("Failed to create link from: \(link)")
            return
        }

        coordinator?.openURL(url)
    }

    func openFullDescription() {
        guard let fullDescription = loadedInfo?.fullDescription else {
            return
        }

        openInfoBottomSheet(title: Localization.marketsTokenDetailsAboutTokenTitle(tokenInfo.name), message: fullDescription)
    }
}

// MARK: - Details response processing

private extension TokenMarketsDetailsViewModel {
    func handleLoadDetailedInfo(_ result: Result<TokenMarketsDetailsModel, Error>) async {
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }

        do {
            let detailsModel = try result.get()
            await setupUI(using: detailsModel)
        } catch {
            if error.isCancellationError {
                return
            }

            await setupFailedState()
            log("Failed to load detailed info. Reason: \(error)")
        }
    }

    @MainActor
    func setupUI(using model: TokenMarketsDetailsModel) {
        loadedPriceChangeInfo = model.priceChangePercentage
        loadedInfo = model
        state = .loaded(model: model)

        makeBlocksViewModels(using: model)
    }

    @MainActor
    func setupFailedState() {
        if case .failed = historyChartViewModel?.viewState {
            state = .failedToLoadAllData
        } else if state != .failedToLoadAllData {
            state = .failedToLoadDetails
        }
    }
}

// MARK: - Private functions

private extension TokenMarketsDetailsViewModel {
    func bind() {
        quotesRepository.quotesPublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .compactMap { viewModel, quotes in
                quotes[viewModel.tokenInfo.id]?.price
            }
            .assign(to: \.value, on: currentPriceSubject, ownership: .weak)
            .store(in: &bag)

        currentPriceSubject
            .receive(on: DispatchQueue.main)
            .withPrevious()
            .withWeakCaptureOf(self)
            .sink { elements in
                let (viewModel, (previousValue, newValue)) = elements
                viewModel.price = viewModel.balanceFormatter.formatFiatBalance(
                    newValue,
                    formattingOptions: viewModel.fiatBalanceFormattingOptions
                )
                viewModel.priceChangeAnimation = .calculateChange(from: previousValue, to: newValue)
            }
            .store(in: &bag)

        $isLoading
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, isLoading in
                viewModel.portfolioViewModel?.isLoading = isLoading
            }
            .store(in: &bag)

        $selectedPriceChangeIntervalType
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, intervalType in
                // The order of calling these two methods matters, do not change
                viewModel.updatePriceInfo(externallySelectedPrice: nil, selectedPriceChangeIntervalType: intervalType)
                viewModel.updateSelectedDate(externallySelectedDate: nil, selectedPriceChangeIntervalType: intervalType)
            }
            .store(in: &bag)
    }

    func bindToHistoryChartViewModel() {
        historyChartViewModel?.$viewState
            .receive(on: DispatchQueue.main)
            .withPrevious()
            .withWeakCaptureOf(self)
            .sink(receiveValue: { elements in
                let (viewModel, (previousChartState, newChartState)) = elements

                switch (previousChartState, newChartState) {
                case (.failed, .failed):
                    // We need to process this cases before other so that view state remains unchanged.
                    return
                case (.failed, .loading):
                    if case .failedToLoadAllData = viewModel.state {
                        viewModel.isLoading = true
                    }
                case (_, .failed):
                    if case .failedToLoadDetails = viewModel.state {
                        viewModel.state = .failedToLoadAllData
                    }
                case (.loading, .loaded), (.failed, .loaded):
                    if case .failedToLoadAllData = viewModel.state {
                        viewModel.state = .failedToLoadDetails
                    }

                    if viewModel.loadingTask == nil {
                        viewModel.isLoading = false
                    }
                default:
                    break
                }
            })
            .store(in: &bag)

        historyChartViewModel?
            .selectedChartValuePublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, selectedChartValue in
                let intervalType = viewModel.selectedPriceChangeIntervalType
                // The order of calling these two methods matters, do not change
                viewModel.updatePriceInfo(
                    externallySelectedPrice: selectedChartValue?.price,
                    selectedPriceChangeIntervalType: intervalType
                )
                viewModel.updateSelectedDate(
                    externallySelectedDate: selectedChartValue?.date,
                    selectedPriceChangeIntervalType: intervalType
                )
            }
            .store(in: &bag)
    }

    func makePreloadBlocksViewModels() {
        portfolioViewModel = .init(
            userWalletModels: walletDataProvider.userWalletModels,
            coinId: tokenInfo.id,
            coordinator: coordinator,
            addTokenTapAction: { [weak self] in
                guard let self, let coinModel = loadedInfo?.coinModel, !coinModel.items.isEmpty else {
                    return
                }

                coordinator?.openTokenSelector(with: coinModel, with: walletDataProvider)
            }
        )
    }

    func makeHistoryChartViewModel() {
        let historyChartProvider = CommonMarketsHistoryChartProvider(
            tokenId: tokenInfo.id,
            yAxisLabelCount: Constants.historyChartYAxisLabelCount
        )
        historyChartViewModel = MarketsHistoryChartViewModel(
            historyChartProvider: historyChartProvider,
            selectedPriceInterval: selectedPriceChangeIntervalType,
            selectedPriceIntervalPublisher: $selectedPriceChangeIntervalType
        )
    }

    func makeBlocksViewModels(using model: TokenMarketsDetailsModel) {
        if let insights = model.insights {
            insightsViewModel = .init(insights: insights, infoRouter: self)
        }

        if let metrics = model.metrics {
            metricsViewModel = .init(metrics: metrics, infoRouter: self)
        }

        pricePerformanceViewModel = .init(
            pricePerformanceData: model.pricePerformance,
            currentPricePublisher: currentPriceSubject.eraseToAnyPublisher()
        )

        linksSections = MarketsTokenDetailsLinksMapper(
            openLinkAction: weakify(self, forFunction: TokenMarketsDetailsViewModel.openLinkAction(_:))
        ).mapToSections(model.links)
    }

    func updatePriceInfo(externallySelectedPrice: Decimal?, selectedPriceChangeIntervalType: MarketsPriceIntervalType) {
        let priceHelper = TokenMarketsDetailsPriceInfoHelper(
            tokenInfo: tokenInfo,
            priceChangeInfo: loadedPriceChangeInfo,
            fiatBalanceFormattingOptions: fiatBalanceFormattingOptions
        )
        let priceInfo = priceHelper.makePriceInfo(
            selectedPrice: externallySelectedPrice,
            selectedPriceChangeIntervalType: selectedPriceChangeIntervalType
        )
        price = priceInfo.price
        priceChangeState = priceInfo.priceChangeState
    }

    func updateSelectedDate(externallySelectedDate: Date?, selectedPriceChangeIntervalType: MarketsPriceIntervalType) {
        let dateHelper = TokenMarketsDetailsDateHelper(initialDate: initialDate)
        selectedDate = dateHelper.makeDate(
            selectedDate: externallySelectedDate,
            selectedPriceChangeIntervalType: selectedPriceChangeIntervalType
        )
    }
}

// MARK: - Logging

private extension TokenMarketsDetailsViewModel {
    func log(_ message: @autoclosure () -> String) {
        AppLog.shared.debug("[TokenMarketsDetailsViewModel] - \(message())")
    }
}

// MARK: - Navigation

extension TokenMarketsDetailsViewModel: MarketsTokenDetailsBottomSheetRouter {
    func openInfoBottomSheet(title: String, message: String) {
        descriptionBottomSheetInfo = .init(title: title, description: message)
    }
}

// MARK: - Constants

private extension TokenMarketsDetailsViewModel {
    private enum Constants {
        static let historyChartYAxisLabelCount = 3
    }
}

extension TokenMarketsDetailsViewModel {
    enum ViewState: Equatable {
        case loading
        case failedToLoadDetails
        case failedToLoadAllData
        case loaded(model: TokenMarketsDetailsModel)
    }
}
