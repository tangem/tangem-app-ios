//
//  NewsDeeplinkContainerView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import SafariServices

struct NewsDeeplinkContainerView: View {
    @StateObject private var coordinator: DeeplinkCoordinator

    init(newsId: Int) {
        _coordinator = StateObject(wrappedValue: DeeplinkCoordinator(newsId: newsId))
    }

    var body: some View {
        NewsPagerView(viewModel: coordinator.viewModel, isDeeplinkMode: true)
    }
}

// MARK: - Standalone Coordinator for Deeplink

extension NewsDeeplinkContainerView {
    @MainActor
    final class DeeplinkCoordinator: ObservableObject, NewsDetailsRoutable {
        let viewModel: NewsPagerViewModel

        var hasMoreNews: Bool { false }

        init(newsId: Int) {
            viewModel = NewsPagerViewModel(
                newsIds: [newsId],
                initialIndex: 0,
                dateFormatter: NewsDateFormatter(),
                coordinator: nil
            )
            viewModel.setCoordinator(self)
        }

        func dismissNewsDetails() {
            UIApplication.dismissTop()
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
            // Not supported in deeplink mode - would need full navigation stack
        }

        func loadMoreNews() async -> [Int] {
            []
        }
    }
}
