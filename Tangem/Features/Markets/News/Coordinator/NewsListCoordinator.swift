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
import struct TangemUIUtils.AlertBinder

final class NewsListCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Navigation Path

    @Published var path: [Destination] = []

    // MARK: - Root ViewModels

    @Published var rootViewModel: NewsListViewModel?
    @Published var error: AlertBinder?

    // MARK: - Private Properties

    private var dataProvider: NewsDataProvider?
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
                coordinator: self
            )
        }
    }
}

// MARK: - Destination

extension NewsListCoordinator {
    enum Destination: Hashable {
        case pager(NewsPagerViewModel)
        case tokenDetails(MarketsTokenDetailsCoordinator)

        var isPager: Bool {
            if case .pager = self { return true }
            return false
        }

        var isTokenDetails: Bool {
            if case .tokenDetails = self { return true }
            return false
        }

        var pagerValue: NewsPagerViewModel? {
            if case .pager(let viewModel) = self { return viewModel }
            return nil
        }

        var tokenDetailsValue: MarketsTokenDetailsCoordinator? {
            if case .tokenDetails(let coordinator) = self { return coordinator }
            return nil
        }

        static func == (lhs: Destination, rhs: Destination) -> Bool {
            switch (lhs, rhs) {
            case (.pager(let lhsVM), .pager(let rhsVM)):
                return lhsVM === rhsVM
            case (.tokenDetails(let lhsCoord), .tokenDetails(let rhsCoord)):
                return lhsCoord === rhsCoord
            default:
                return false
            }
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case .pager(let viewModel):
                hasher.combine(ObjectIdentifier(viewModel))
            case .tokenDetails(let coordinator):
                hasher.combine(ObjectIdentifier(coordinator))
            }
        }
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
    func openNewsDetails(newsIds: [Int], selectedIndex: Int, hasMoreNews: Bool? = nil) {
        let dataSource: NewsPagerDataSource?
        if hasMoreNews != nil {
            dataSource = SingleNewsDataSource()
        } else if let dataProvider {
            dataSource = NewsDataProviderPagerDataSource(provider: dataProvider)
        } else {
            dataSource = nil
        }

        let viewModel = NewsPagerViewModel(
            newsIds: newsIds,
            initialIndex: selectedIndex,
            dataSource: dataSource,
            analyticsSource: .newsSourceNewsList,
            coordinator: self
        )
        path.append(.pager(viewModel))
    }
}

// MARK: - NewsDetailsRoutable

extension NewsListCoordinator: NewsDetailsRoutable {
    func dismissNewsDetails() {
        guard let lastPagerIndex = path.lastIndex(where: \.isPager) else {
            return
        }

        path.remove(at: lastPagerIndex)
    }

    func share(url: String) {
        guard let url = URL(string: url) else { return }
        AppPresenter.shared.show(UIActivityViewController(activityItems: [url], applicationActivities: nil))
    }

    func openURL(_ url: URL) {
        safariManager.openURL(url)
    }

    func openTokenDetails(_ token: MarketsTokenModel) {
        weak var weakCoordinator: MarketsTokenDetailsCoordinator?

        let coordinator = MarketsTokenDetailsCoordinator(
            dismissAction: { [weak self] _ in
                guard let coordinator = weakCoordinator else { return }
                self?.path.removeAll { $0 == .tokenDetails(coordinator) }
            },
            popToRootAction: popToRootAction
        )

        weakCoordinator = coordinator
        coordinator.start(with: .init(info: token, style: .marketsSheet))
        path.append(.tokenDetails(coordinator))
    }
}
