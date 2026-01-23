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

    @Published private(set) var resultState: LoadingResult<ResultState, Error> = .loading

    let widgetType: MarketsWidgetType

    // MARK: - Properties

    private let widgetsUpdateHandler: MarketsMainWidgetsUpdateHandler

    private let mapper = NewsModelMapper()
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
                // When the main widgets container reports `.allWidgetsWithError`,
                // the global error UI is handled at a higher level. We intentionally
                // skip updating this widget's local view state here to avoid
                // overriding the shared error representation or causing UI flicker.
                if case .allWidgetsWithError = state {
                    return
                }

                viewModel.updateViewState()
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
        switch newsProvider.newsResult {
        case .success:
            resultState = .success(viewStateForLoadedItems())
        case .failure(let error):
            resultState = .failure(error)
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
}

extension NewsWidgetViewModel {
    struct ResultState {
        let trendingCardNewsItem: TrendingCardNewsItem?
        let carouselNewsItems: [CarouselNewsItem]
    }
}
