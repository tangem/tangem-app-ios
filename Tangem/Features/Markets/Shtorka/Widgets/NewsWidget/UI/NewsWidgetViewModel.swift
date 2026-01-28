//
//  NewsWidgetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import CombineExt
import TangemFoundation

final class NewsWidgetViewModel: ObservableObject {
    @Injected(\.newsReadStatusProvider) private var readStatusProvider: NewsReadStatusProvider

    // MARK: - Published Properties

    @Published private(set) var isFirstLoading: Bool = true
    @Published private(set) var resultState: LoadingResult<ResultState, Error> = .loading

    let widgetType: MarketsWidgetType

    // MARK: - Properties

    private let widgetsUpdateHandler: MarketsMainWidgetsUpdateHandler
    private let analyticsService: NewsWidgetAnalyticsProvider

    private lazy var mapper = NewsModelMapper(readStatusProvider: readStatusProvider)
    private let newsProvider = CommonMarketsWidgetNewsService()

    private weak var coordinator: NewsWidgetRoutable?

    private var bag = Set<AnyCancellable>()

    // MARK: - Analytics Session Flags

    private var hasLoggedCarouselScrolled = false
    private var hasLoggedCarouselEndReached = false
    private var hasLoggedCarouselAllNewsButton = false
    private var hasLoggedTrendingClicked = false

    // MARK: - Init

    init(
        widgetType: MarketsWidgetType,
        widgetsUpdateHandler: MarketsMainWidgetsUpdateHandler,
        analyticsService: NewsWidgetAnalyticsProvider,
        coordinator: NewsWidgetRoutable?
    ) {
        self.widgetType = widgetType
        self.widgetsUpdateHandler = widgetsUpdateHandler
        self.analyticsService = analyticsService
        self.coordinator = coordinator

        bind()
        update()
    }

    deinit {
        AppLogger.debug("NewsWidgetViewModel deinit")
    }

    // MARK: - Public Implementation

    func tryLoadAgain() {
        update()
    }

    @MainActor
    func handleAllNewsTap() {
        analyticsService.logNewsListOpened()
        coordinator?.openSeeAllNewsWidget()
    }

    @MainActor
    func handleCarouselAllNewsTap() {
        if !hasLoggedCarouselAllNewsButton {
            hasLoggedCarouselAllNewsButton = true
            analyticsService.logCarouselAllNewsButton()
        }

        handleAllNewsTap()
    }

    @MainActor
    func handleCarouselItemAppear(at index: Int) {
        guard let carouselItems = resultState.value?.carouselNewsItems else { return }

        // Track when user scrolls to 4th news item or beyond (index 3, 0-based)
        if index >= 3, !hasLoggedCarouselScrolled {
            hasLoggedCarouselScrolled = true
            analyticsService.logCarouselScrolled()
        }

        // Track when user reaches the end (last item before "See All" card)
        if index >= carouselItems.count - 1, !hasLoggedCarouselEndReached {
            hasLoggedCarouselEndReached = true
            analyticsService.logCarouselEndReached()
        }
    }

    @MainActor
    func handleTrendingNewsTap(newsId: String) {
        if !hasLoggedTrendingClicked {
            hasLoggedTrendingClicked = true
            analyticsService.logTrendingClicked(newsId: newsId)
        }

        handleTap(newsId: newsId)
    }

    @MainActor
    private func handleTap(newsId: String) {
        guard let newsIdInt = Int(newsId) else { return }

        let visibleNewsIds = getVisibleNewsIds()
        guard let selectedIndex = visibleNewsIds.firstIndex(of: newsIdInt) else { return }

        Analytics.log(event: .marketsNewsCarouselTrendingClicked, params: [.newsId: newsId])
        coordinator?.openNewsDetails(newsIds: visibleNewsIds, selectedIndex: selectedIndex)
    }

    // MARK: - Private Helpers

    /// Returns only the news IDs that are visible in the widget (1 trending + up to 5 carousel)
    private func getVisibleNewsIds() -> [Int] {
        let items = sortItems(newsProvider.newsResult.value ?? [])
        var result: [NewsId] = []

        if let trending = items.last(where: { $0.isTrending }) {
            result.append(trending.id)
        }

        let carouselItems = items.filter { !$0.isTrending }
        result.append(contentsOf: carouselItems.compactMap { $0.id })

        return result.compactMap { Int($0) }
    }
}

// MARK: - Private Implementation

private extension NewsWidgetViewModel {
    func update() {
        newsProvider.fetch()
    }

    func bind() {
        widgetsUpdateHandler
            .widgetsUpdateStateEventPublisher
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, state in
                switch state {
                case .loaded:
                    viewModel.updateViewState()
                    viewModel.clearIsFirstLoadingFlag()
                case .initialLoading:
                    viewModel.resultState = .loading
                case .reloading(let widgetTypes):
                    if widgetTypes.contains(viewModel.widgetType) {
                        viewModel.resultState = .loading
                    }
                case .allFailed:
                    // Global error UI is handled at a higher level
                    return
                }
            }
            .store(in: &bag)

        newsProvider
            .newsResultPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, result in
                let widgetLoadingState: WidgetLoadingState

                switch result {
                case .loading:
                    widgetLoadingState = .loading
                case .success:
                    widgetLoadingState = .loaded
                    Analytics.log(event: .marketsNewsListOpened, params: [.source: Analytics.ParameterValue.markets.rawValue])
                case .failure(let error):
                    widgetLoadingState = .error
                    viewModel.resultState = .failure(error)
                    Analytics.log(
                        event: .marketsNewsLoadError,
                        params: error.marketsAnalyticsParams
                    )
                }

                viewModel.widgetsUpdateHandler.performUpdateLoading(state: widgetLoadingState, for: viewModel.widgetType)
            }
            .store(in: &bag)

        readStatusProvider
            .readStatusChangedPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.updateReadState()
            }
            .store(in: &bag)
    }

    func viewStateForLoadedItems() -> ResultState {
        var trendingCardNewsItem: TrendingCardNewsItem?
        var carouselNewsItems: [CarouselNewsItem] = []
        var processedNewsIds = Set<String>()

        sortItems(newsProvider.newsResult.value ?? []).forEach { item in
            // Deduplication by ID
            guard !processedNewsIds.contains(item.id) else {
                return
            }
            processedNewsIds.insert(item.id)

            if item.isTrending, trendingCardNewsItem == nil {
                trendingCardNewsItem = mapper.toTrendingCardNewsItem(
                    from: item,
                    onTap: weakify(self, forFunction: NewsWidgetViewModel.handleTrendingNewsTap)
                )
            } else {
                let carouselItem = mapper.toCarouselNewsItem(
                    from: item,
                    onTap: weakify(self, forFunction: NewsWidgetViewModel.handleTap)
                )

                carouselNewsItems.append(carouselItem)
            }
        }

        return ResultState(
            trendingCardNewsItem: trendingCardNewsItem,
            carouselNewsItems: carouselNewsItems
        )
    }

    func updateReadState() {
        if resultState.isSuccess {
            resultState = .success(viewStateForLoadedItems())
        }
    }

    func updateViewState() {
        switch newsProvider.newsResult {
        case .success:
            resultState = .success(viewStateForLoadedItems())
        case .failure(let error):
            resultState = .failure(error)
            analyticsService.logNewsLoadError(error)
        case .loading:
            resultState = .loading
        }
    }

    func sortItems(_ items: [TrendingNewsModel]) -> [TrendingNewsModel] {
        items
            .enumerated()
            .sorted { lhs, rhs in
                let lhsIsRead = readStatusProvider.isRead(for: lhs.element.id)
                let rhsIsRead = readStatusProvider.isRead(for: rhs.element.id)

                if lhsIsRead != rhsIsRead {
                    return !lhsIsRead
                }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    func clearIsFirstLoadingFlag() {
        if isFirstLoading {
            isFirstLoading = false
        }
    }
}

extension NewsWidgetViewModel {
    struct ResultState {
        let trendingCardNewsItem: TrendingCardNewsItem?
        let carouselNewsItems: [CarouselNewsItem]
    }
}
