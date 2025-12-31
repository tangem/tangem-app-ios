//
//  NewsDeeplinkCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

final class NewsDeeplinkCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root ViewModel

    @Published var rootViewModel: NewsDetailsViewModel?
    @Published var tokenDetailsCoordinator: MarketsTokenDetailsCoordinator?

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
            rootViewModel = NewsDetailsViewModel(
                newsId: options.newsId,
                dateFormatter: NewsDateFormatter(),
                coordinator: self
            )
        }
    }
}

// MARK: - Options

extension NewsDeeplinkCoordinator {
    struct Options {
        let newsId: Int
    }
}

// MARK: - NewsDetailsRoutable

extension NewsDeeplinkCoordinator: NewsDetailsRoutable {
    var hasMoreNews: Bool { false }

    func dismissNewsDetails() {
        dismissAction(())
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
        UIApplication.shared.open(url)
    }

    func openTokenDetails(_ token: MarketsTokenModel) {
        let coordinator = MarketsTokenDetailsCoordinator(
            dismissAction: { [weak self] in
                self?.tokenDetailsCoordinator = nil
            }
        )
        coordinator.start(with: .init(info: token, style: .marketsSheet))
        tokenDetailsCoordinator = coordinator
    }

    func loadMoreNews() async -> [Int] {
        []
    }
}
