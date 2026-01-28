//
//  NewsListViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

@MainActor
final class NewsListViewModel: MarketsBaseViewModel {
    @Injected(\.newsReadStatusProvider) private var readStatusProvider: NewsReadStatusProvider

    // MARK: - Published Properties

    @Published private(set) var newsItems: [NewsItemViewModel] = []
    @Published private(set) var categories: [NewsDTO.Categories.Item] = []
    @Published var selectedCategoryId: Int?
    @Published private(set) var loadingState: LoadingState = .idle

    // MARK: - Private Properties

    private let dataProvider: NewsDataProvider
    private lazy var mapper = NewsModelMapper(readStatusProvider: readStatusProvider)
    private weak var coordinator: NewsListRoutable?

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        dataProvider: NewsDataProvider,
        coordinator: NewsListRoutable? = nil
    ) {
        self.dataProvider = dataProvider
        self.coordinator = coordinator

        // `OverlayContentStateObserver` doesn't provide an initial progress/state snapshot.
        // When this screen is pushed into a `NavigationStack`, the overlay is typically already expanded,
        // and without a proper initial value the content would stay hidden (opacity == 0).
        super.init(overlayContentProgressInitialValue: 1.0)

        bind()
    }

    // MARK: - Private Methods

    private func bind() {
        dataProvider
            .categoriesPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, categories in
                viewModel.categories = categories
            }
            .store(in: &bag)

        dataProvider
            .eventPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, event in
                viewModel.handleEvent(event)
            }
            .store(in: &bag)

        $selectedCategoryId
            .dropFirst()
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, categoryId in
                viewModel.onCategorySelected(categoryId)
            }
            .store(in: &bag)

        readStatusProvider.readStatusChangedPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, newsId in
                viewModel.updateNewsReadStatus(newsId: newsId)
            }
            .store(in: &bag)
    }

    private func updateNewsReadStatus(newsId: NewsId) {
        guard let newsIdInt = Int(newsId),
              let index = newsItems.firstIndex(where: { $0.id == newsIdInt }) else {
            return
        }

        newsItems[index] = newsItems[index].withIsRead(true)
    }

    private func handleEvent(_ event: NewsDataProvider.Event) {
        AppLogger.debug("📰 [NewsListViewModel] handleEvent: \(event)")

        switch event {
        case .loading:
            // If we already have items, it's pagination loading
            loadingState = newsItems.isEmpty ? .loading : .paginationLoading
        case .idle:
            loadingState = .idle
        case .failedToFetchData(let error):
            // If we already have items, it's pagination error
            loadingState = newsItems.isEmpty ? .error : .paginationError

            // Log analytics only for initial load error (not pagination)
            if newsItems.isEmpty {
                let analyticsParams = error.marketsAnalyticsParams
                Analytics.log(
                    event: .marketsNewsListLoadError,
                    params: [
                        .errorCode: analyticsParams[.errorCode] ?? "",
                        .errorMessage: analyticsParams[.errorMessage] ?? "",
                    ]
                )
            }
        case .appendedItems(let items, let lastPage):
            AppLogger.debug("📰 [NewsListViewModel] appending \(items.count) items, current count: \(newsItems.count)")
            let newViewModels = items.map { mapper.toNewsItemViewModel(from: $0) }
            newsItems.append(contentsOf: newViewModels)
            AppLogger.debug("📰 [NewsListViewModel] new count: \(newsItems.count)")

            if newsItems.isEmpty {
                loadingState = .noResults
            } else {
                loadingState = lastPage ? .allDataLoaded : .loaded
            }
        case .startInitialFetch:
            AppLogger.debug("📰 [NewsListViewModel] startInitialFetch - clearing newsItems")
            newsItems = []
            loadingState = .loading
        case .cleared:
            newsItems = []
            loadingState = .idle
        }
    }
}

// MARK: - View Action

extension NewsListViewModel {
    func handleViewAction(_ viewAction: ViewAction) {
        switch viewAction {
        case .onFirstAppear:
            dataProvider.fetchCategories()
            dataProvider.fetch(categoryIds: nil)
        case .onAppear:
            // No action required on subsequent appears
            break
        case .retry:
            dataProvider.fetch(categoryIds: selectedCategoryId.map { [$0] })
        case .onCategorySelected(let categoryId):
            onCategorySelected(categoryId)
        case .loadMore:
            dataProvider.fetchMore()
        case .onNewsSelected(let newsId):
            let allNewsIds = newsItems.map(\.id)
            guard let selectedIndex = allNewsIds.firstIndex(of: newsId) else { return }
            coordinator?.openNewsDetails(newsIds: allNewsIds, selectedIndex: selectedIndex)
        case .back:
            coordinator?.dismiss()
        }
    }

    private func onCategorySelected(_ categoryId: Int?) {
        // Don't send analytics for "All news" (nil categoryId)
        if let categoryId {
            Analytics.log(
                event: .marketsNewsCategoriesSelected,
                params: [
                    .selectedCategories: String(categoryId),
                ]
            )
        }

        dataProvider.fetch(categoryIds: categoryId.map { [$0] })
    }

    enum ViewAction {
        case back
        case onFirstAppear
        case onAppear
        case retry
        case onCategorySelected(Int?)
        case loadMore
        case onNewsSelected(Int)
    }
}

// MARK: - LoadingState

extension NewsListViewModel {
    enum LoadingState: String, Identifiable, Hashable {
        case idle
        case loading
        case error
        case noResults
        case loaded
        case allDataLoaded
        case paginationLoading
        case paginationError

        var id: String { rawValue }
    }
}

// MARK: - NewsListRoutable

@MainActor
protocol NewsListRoutable: AnyObject {
    func dismiss()
    func openNewsDetails(newsIds: [Int], selectedIndex: Int, hasMoreNews: Bool?)
}

extension NewsListRoutable {
    func openNewsDetails(newsIds: [Int], selectedIndex: Int) {
        openNewsDetails(newsIds: newsIds, selectedIndex: selectedIndex, hasMoreNews: nil)
    }
}
