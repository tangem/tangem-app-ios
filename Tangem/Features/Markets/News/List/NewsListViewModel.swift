//
//  NewsListViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

@MainActor
final class NewsListViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var newsItems: [NewsItemViewModel] = []
    @Published private(set) var categories: [NewsDTO.Categories.Item] = []
    @Published var selectedCategoryId: Int?
    @Published private(set) var loadingState: LoadingState = .idle

    // MARK: - Private Properties

    private let dataProvider: NewsDataProvider
    private let dateFormatter: NewsDateFormatter
    private weak var coordinator: NewsListRoutable?

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        dataProvider: NewsDataProvider,
        dateFormatter: NewsDateFormatter = NewsDateFormatter(),
        coordinator: NewsListRoutable? = nil
    ) {
        self.dataProvider = dataProvider
        self.dateFormatter = dateFormatter
        self.coordinator = coordinator

        bind()
    }

    // MARK: - Private Methods

    private func bind() {
        dataProvider.categoriesPublisher
            .sink { [weak self] categories in
                self?.categories = categories
            }
            .store(in: &bag)

        dataProvider.eventPublisher
            .sink { [weak self] event in
                self?.handleEvent(event)
            }
            .store(in: &bag)

        $selectedCategoryId
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] categoryId in
                self?.onCategorySelected(categoryId)
            }
            .store(in: &bag)
    }

    private func handleEvent(_ event: NewsDataProvider.Event) {
        switch event {
        case .loading:
            loadingState = newsItems.isEmpty ? .loading : .paginationLoading
        case .idle:
            loadingState = .idle
        case .failedToFetchData:
            loadingState = newsItems.isEmpty ? .error : .paginationError
        case .appendedItems(let items, let lastPage):
            let newViewModels = items.map { NewsItemViewModel(from: $0, dateFormatter: dateFormatter) }
            newsItems.append(contentsOf: newViewModels)

            if newsItems.isEmpty {
                loadingState = .noResults
            } else {
                loadingState = lastPage ? .allDataLoaded : .loaded
            }
        case .startInitialFetch:
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
        case .onAppear:
            dataProvider.fetchCategories()
            dataProvider.fetch(categoryIds: nil)
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
        dataProvider.fetch(categoryIds: categoryId.map { [$0] })
    }

    enum ViewAction {
        case back
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

protocol NewsListRoutable: AnyObject {
    func dismiss()
    @MainActor
    func openNewsDetails(newsIds: [Int], selectedIndex: Int)
}
