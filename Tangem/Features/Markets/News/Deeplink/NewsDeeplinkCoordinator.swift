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

    @Published var path: [Destination] = []

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
        weak var weakCoordinator: MarketsTokenDetailsCoordinator?

        let coordinator = MarketsTokenDetailsCoordinator(
            dismissAction: { [weak self] in
                guard let coordinator = weakCoordinator else { return }
                self?.dismissTokenDetails(coordinator)
            }
        )

        weakCoordinator = coordinator
        coordinator.start(with: .init(info: token, style: .marketsSheet))
        path.append(.tokenDetails(coordinator))
    }

    // MARK: - Private Methods

    private func dismissTokenDetails(_ coordinator: MarketsTokenDetailsCoordinator) {
        path.removeAll { $0 == .tokenDetails(coordinator) }
    }
}

// MARK: - Destination

extension NewsDeeplinkCoordinator {
    enum Destination: Hashable {
        case tokenDetails(MarketsTokenDetailsCoordinator)

        var isTokenDetails: Bool {
            if case .tokenDetails = self { return true }
            return false
        }

        var tokenDetailsValue: MarketsTokenDetailsCoordinator? {
            if case .tokenDetails(let coordinator) = self { return coordinator }
            return nil
        }

        static func == (lhs: Destination, rhs: Destination) -> Bool {
            switch (lhs, rhs) {
            case (.tokenDetails(let lhsCoord), .tokenDetails(let rhsCoord)):
                return lhsCoord === rhsCoord
            }
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case .tokenDetails(let coordinator):
                hasher.combine(ObjectIdentifier(coordinator))
            }
        }
    }
}
