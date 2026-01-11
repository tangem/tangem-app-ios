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

    var hasMoreNews: Bool { false }

    // MARK: - Private Properties

    private var tokenDetailsCoordinators: [UUID: MarketsTokenDetailsCoordinator] = [:]

    // MARK: - Init

    init(newsId: Int) {
        viewModel = NewsPagerViewModel(
            newsIds: [newsId],
            initialIndex: 0,
            dateFormatter: NewsDateFormatter(),
            coordinator: nil
        )
        viewModel.setCoordinator(self)
    }

    // MARK: - Public Methods

    func tokenDetailsCoordinator(for id: UUID) -> MarketsTokenDetailsCoordinator? {
        tokenDetailsCoordinators[id]
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

    func loadMoreNews() async -> [Int] { [] }

    // MARK: - Private Methods

    private func dismissTokenDetails(id: UUID) {
        tokenDetailsCoordinators.removeValue(forKey: id)
        path.removeAll { $0 == .tokenDetails(id: id) }
    }
}

// MARK: - Destination

extension NewsDeeplinkCoordinator {
    enum Destination: Equatable {
        case tokenDetails(id: UUID)
    }
}
