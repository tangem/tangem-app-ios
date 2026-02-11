//
//  NewsDeeplinkCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

@MainActor
final class NewsDeeplinkCoordinator: ObservableObject, NewsDetailsRoutable {
    // MARK: - Dependencies

    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Published Properties

    @Published var tokenDetailsCoordinator: MarketsTokenDetailsCoordinator?

    // MARK: - Properties

    let viewModel: NewsPagerViewModel

    // MARK: - Init

    init(newsId: Int) {
        viewModel = NewsPagerViewModel(
            newsIds: [newsId],
            initialIndex: 0,
            isDeeplinkMode: true,
            dataSource: SingleNewsDataSource(),
            analyticsSource: .newsSourceNewsLink,
            coordinator: nil
        )
        viewModel.setCoordinator(self)
    }

    // MARK: - NewsDetailsRoutable

    func dismissNewsDetails() {
        UIApplication.dismissTop()
    }

    func share(url: String) {
        guard let url = URL(string: url) else { return }
        AppPresenter.shared.show(UIActivityViewController(activityItems: [url], applicationActivities: nil))
    }

    func openURL(_ url: URL) {
        safariManager.openURL(url)
    }

    func openTokenDetails(_ token: MarketsTokenModel) {
        let coordinator = MarketsTokenDetailsCoordinator(
            dismissAction: { [weak self] _ in
                self?.tokenDetailsCoordinator = nil
            },
            popToRootAction: { _ in }
        )

        coordinator.start(with: .init(info: token, style: .marketsSheet, isDeeplinkMode: true))
        tokenDetailsCoordinator = coordinator
    }
}
