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
        coordinator?.openAllNews()
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
