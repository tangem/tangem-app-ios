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
import TangemLocalization

final class NewsWidgetViewModel: ObservableObject {
    // MARK: - Injected & Published Properties

    @Published private(set) var isFirstLoading: Bool = true
    @Published private(set) var resultState: LoadingResult<ResultState, Error> = .loading

    let widgetType: MarketsWidgetType

    // MARK: - Properties

    private let widgetsUpdateHandler: MarketsMainWidgetsUpdateHandler
    private let analyticsService: MarketsWidgetAnalyticsProvider

    private let mapper = NewsModelMapper()
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
        analyticsService: MarketsWidgetAnalyticsProvider,
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
        Analytics.log(
            event: .marketsNewsListOpened,
            params: [
                .source: Analytics.ParameterValue.markets.rawValue,
            ]
        )

        coordinator?.openSeeAllNewsWidget()
    }

    @MainActor
    func handleCarouselAllNewsTap() {
        if !hasLoggedCarouselAllNewsButton {
            hasLoggedCarouselAllNewsButton = true
            Analytics.log(.marketsNewsCarouselAllNewsButton)
        }

        handleAllNewsTap()
    }

    @MainActor
    func handleCarouselItemAppear(at index: Int) {
        guard let carouselItems = resultState.value?.carouselNewsItems else { return }

        // Track when user scrolls to 4th news item or beyond (index 3, 0-based)
        if index >= 3, !hasLoggedCarouselScrolled {
            hasLoggedCarouselScrolled = true
            Analytics.log(.marketsNewsCarouselScrolled)
        }

        // Track when user reaches the end (last item before "See All" card)
        if index >= carouselItems.count - 1, !hasLoggedCarouselEndReached {
            hasLoggedCarouselEndReached = true
            Analytics.log(.marketsNewsCarouselEndReached)
        }
    }

    @MainActor
    func handleTrendingNewsTap(newsId: String) {
        if !hasLoggedTrendingClicked {
            hasLoggedTrendingClicked = true
            Analytics.log(
                event: .marketsNewsCarouselTrendingClicked,
                params: [
                    .token: newsId, // News Id
                ]
            )
        }

        handleTap(newsId: newsId)
    }

    @MainActor
    private func handleTap(newsId: String) {
        coordinator?.openNews(by: newsId)
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
                case .failure:
                    widgetLoadingState = .error
                }

                viewModel.widgetsUpdateHandler.performUpdateLoading(state: widgetLoadingState, for: viewModel.widgetType)
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
                if lhs.element.isRead != rhs.element.isRead {
                    return !lhs.element.isRead
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
