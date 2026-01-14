//
//  NewsListCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemUIUtils.AlertBinder

final class NewsListCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root ViewModels

    @Published var rootViewModel: NewsListViewModel?
    @Published var error: AlertBinder?

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
            rootViewModel = NewsListViewModel(
                dataProvider: NewsDataProvider(),
                coordinator: self
            )
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

    func openNewsDetails(newsId: Int) {
        // Will be implemented in future iteration
    }
}
