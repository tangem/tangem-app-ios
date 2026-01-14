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
    @Injected(\.newsReadStatusProvider) private var readStatusProvider: NewsReadStatusProvider

    // MARK: - Published Properties

    @Published private(set) var resultState: LoadingResult<ResultState, Error> = .loading

    let widgetType: MarketsWidgetType

    // MARK: - Properties

    private let widgetsUpdateHandler: MarketsMainWidgetsUpdateHandler

    private lazy var mapper = NewsModelMapper(readStatusProvider: readStatusProvider)
    private let newsProvider = CommonMarketsWidgetNewsService()

    private weak var coordinator: NewsWidgetRoutable?

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        widgetType: MarketsWidgetType,
        widgetsUpdateHandler: MarketsMainWidgetsUpdateHandler,
        coordinator: NewsWidgetRoutable?
    ) {
        self.widgetType = widgetType
        self.widgetsUpdateHandler = widgetsUpdateHandler
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
        coordinator?.openSeeAllNewsWidget()
    }

    @MainActor
    private func handleTap(newsId: String) {
        guard let newsIdInt = Int(newsId) else { return }

        let visibleNewsIds = getVisibleNewsIds()
        guard let selectedIndex = visibleNewsIds.firstIndex(of: newsIdInt) else { return }

        coordinator?.openNewsDetails(newsIds: visibleNewsIds, selectedIndex: selectedIndex)
    }

    // MARK: - Private Helpers

    /// Returns only the news IDs that are visible in the widget (1 trending + up to 5 carousel)
    private func getVisibleNewsIds() -> [Int] {
        let items = sortItems(newsProvider.newsResult.value ?? [])
        var result: [Int] = []

        // Add trending (last one in sorted list, matching viewStateForLoadedItems behavior)
        if let trending = items.last(where: { $0.isTrending }), let id = Int(trending.id) {
            result.append(id)
        }

        // Add up to 5 non-trending (carousel items)
        let carouselItems = items.filter { !$0.isTrending }.prefix(5)
        result.append(contentsOf: carouselItems.compactMap { Int($0.id) })

        return result
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
            .sink { viewModel, event in
                if case .readyForDisplay = event {
                    viewModel.updateViewState()
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
                    viewModel.resultState = .loading
                    widgetLoadingState = .loading
                case .success:
                    widgetLoadingState = .loaded
                case .failure(let error):
                    widgetLoadingState = .error
                    viewModel.resultState = .failure(error)
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
                    onTap: weakify(self, forFunction: NewsWidgetViewModel.handleTap)
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
        if resultState.error == nil {
            resultState = .success(viewStateForLoadedItems())
        }
    }

    func sortItems(_ items: [TrendingNewsModel]) -> [TrendingNewsModel] {
        items.sorted {
            if $0.isRead != $1.isRead {
                return !$0.isRead
            } else {
                return $0.createdAt > $1.createdAt
            }
        }
    }
}

extension NewsWidgetViewModel {
    struct ResultState {
        let trendingCardNewsItem: TrendingCardNewsItem?
        let carouselNewsItems: [CarouselNewsItem]
    }
}
