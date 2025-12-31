//
//  NewsListCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine
import SafariServices
import struct TangemUIUtils.AlertBinder

final class NewsListCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Navigation Path

    @Published var path: [Destination] = []

    // MARK: - Root ViewModels

    @Published var rootViewModel: NewsListViewModel?
    @Published var error: AlertBinder?

    // MARK: - Child ViewModels & Coordinators

    private var pagerViewModels: [UUID: NewsPagerViewModel] = [:]
    private var tokenDetailsCoordinators: [UUID: MarketsTokenDetailsCoordinator] = [:]

    // MARK: - Private Properties

    private var dataProvider: NewsDataProvider?
    private var fixedNewsHasMore: Bool?
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in }
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        Task { @MainActor in
            let provider = NewsDataProvider()
            dataProvider = provider

            rootViewModel = NewsListViewModel(
                dataProvider: provider,
                dateFormatter: NewsDateFormatter(),
                coordinator: self
            )
        }
    }

    // MARK: - Path Accessors

    func pagerViewModel(for id: UUID) -> NewsPagerViewModel? {
        pagerViewModels[id]
    }

    func tokenDetailsCoordinator(for id: UUID) -> MarketsTokenDetailsCoordinator? {
        tokenDetailsCoordinators[id]
    }
}

// MARK: - Destination

extension NewsListCoordinator {
    enum Destination: Hashable {
        case pager(id: UUID)
        case tokenDetails(id: UUID)
    }
}

// MARK: - Options

extension NewsListCoordinator {
    struct Options {}
}

// MARK: - NewsListRoutable

extension NewsListCoordinator: NewsListRoutable {
    func dismiss() {
        dismissAction(())
    }

    @MainActor
    func openNewsDetails(newsIds: [Int], selectedIndex: Int) {
        fixedNewsHasMore = nil
        let id = UUID()
        let viewModel = NewsPagerViewModel(
            newsIds: newsIds,
            initialIndex: selectedIndex,
            dateFormatter: NewsDateFormatter(),
            coordinator: self
        )
        pagerViewModels[id] = viewModel
        path.append(.pager(id: id))
    }

    /// Opens news details with a fixed list (from widget) - no additional loading
    @MainActor
    func openNewsDetails(newsIds: [Int], selectedIndex: Int, hasMoreNews: Bool) {
        fixedNewsHasMore = hasMoreNews
        let id = UUID()
        let viewModel = NewsPagerViewModel(
            newsIds: newsIds,
            initialIndex: selectedIndex,
            dateFormatter: NewsDateFormatter(),
            coordinator: self
        )
        pagerViewModels[id] = viewModel
        path.append(.pager(id: id))
    }
}

// MARK: - NewsDetailsRoutable

extension NewsListCoordinator: NewsDetailsRoutable {
    var hasMoreNews: Bool {
        if let fixedNewsHasMore {
            return fixedNewsHasMore
        }
        return dataProvider?.canFetchMore ?? false
    }

    func dismissNewsDetails() {
        guard let lastIndex = path.lastIndex(where: {
            if case .pager = $0 { return true }
            return false
        }) else { return }

        if case .pager(let id) = path[lastIndex] {
            pagerViewModels.removeValue(forKey: id)
        }
        path.remove(at: lastIndex)
    }

    func share(url: String) {
        guard let url = URL(string: url) else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            var topController = rootVC
            while let presented = topController.presentedViewController {
                topController = presented
            }
            topController.present(activityVC, animated: true)
        }
    }

    func openURL(_ url: URL) {
        let safariVC = SFSafariViewController(url: url)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            var topController = rootVC
            while let presented = topController.presentedViewController {
                topController = presented
            }
            topController.present(safariVC, animated: true)
        }
    }

    func openTokenDetails(_ token: MarketsTokenModel) {
        let id = UUID()
        let coordinator = MarketsTokenDetailsCoordinator(
            dismissAction: { [weak self] in
                self?.dismissTokenDetails(id: id)
            }
        )
        coordinator.start(with: .init(info: token, style: .marketsSheet))
        tokenDetailsCoordinators[id] = coordinator
        path.append(.tokenDetails(id: id))
    }

    private func dismissTokenDetails(id: UUID) {
        tokenDetailsCoordinators.removeValue(forKey: id)
        path.removeAll { $0 == .tokenDetails(id: id) }
    }

    @MainActor
    func loadMoreNews() async -> [Int] {
        // Fixed list from widget - no additional loading
        if fixedNewsHasMore != nil {
            return []
        }

        guard let dataProvider, dataProvider.canFetchMore else {
            return []
        }

        return await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?

            cancellable = dataProvider.eventPublisher
                .compactMap { event -> [Int]? in
                    switch event {
                    case .appendedItems(let items, _):
                        return items.map(\.id)
                    case .failedToFetchData:
                        return []
                    default:
                        return nil
                    }
                }
                .first()
                .sink { newIds in
                    cancellable?.cancel()
                    continuation.resume(returning: newIds)
                }

            dataProvider.fetchMore()
        }
    }
}
