//
//  SwapStoryPageView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemStories

struct SwapStoryPageView: View {
    private static let iOS18Available: Bool = if #available(iOS 18.0, *) { true } else { false }
    @Injected(\.storyKingfisherImageCache) private var storyKingfisherImageCache: ImageCache
    @State private var startPoint = UnitPoint(x: -1, y: -1)
    @State private var endPoint = UnitPoint(x: 0.0, y: 0.0)

    let page: TangemStory.SwapStoryData.Page

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: .zero) {
                Spacer()
                    .frame(height: proxy.size.height * 0.68)

                VStack(spacing: 16) {
                    Text(page.title)
                        .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                        .lineLimit(2)

                    Text(page.subtitle)
                        .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                }
                .transaction { transaction in
                    transaction.animation = nil
                }

                Spacer(minLength: .zero)
            }
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                backgroundImage(proxy)
            }
        }
        .multilineTextAlignment(.center)
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                startPoint = UnitPoint(x: 1, y: 1)
                endPoint = UnitPoint(x: 3.0, y: 1.2)
            }
        }
        .allowsHitTesting(Self.iOS18Available)
    }

    private func backgroundImage(_ proxy: GeometryProxy) -> some View {
        ZStack {
            fallbackBackgroundGradient

            if let imageURL = page.image?.url {
                KFImage(imageURL)
                    .targetCache(storyKingfisherImageCache)
                    .cancelOnDisappear(true)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width)
                    .clipped()
            }
        }
    }

    private var fallbackBackgroundGradient: some View {
        LinearGradient(
            stops: [
                Gradient.Stop(color: Color(white: 0.010), location: 0.00),
                Gradient.Stop(color: Color(white: 0.015), location: 0.05),
                Gradient.Stop(color: Color(white: 0.020), location: 0.10),
                Gradient.Stop(color: Color(white: 0.025), location: 0.15),
                Gradient.Stop(color: Color(white: 0.030), location: 0.20),
                Gradient.Stop(color: Color(white: 0.035), location: 0.25),
                Gradient.Stop(color: Color(white: 0.040), location: 0.30),
                Gradient.Stop(color: Color(white: 0.045), location: 0.50),
                Gradient.Stop(color: Color(white: 0.040), location: 0.70),
                Gradient.Stop(color: Color(white: 0.035), location: 0.75),
                Gradient.Stop(color: Color(white: 0.030), location: 0.80),
                Gradient.Stop(color: Color(white: 0.025), location: 0.85),
                Gradient.Stop(color: Color(white: 0.020), location: 0.90),
                Gradient.Stop(color: Color(white: 0.015), location: 0.95),
                Gradient.Stop(color: Color(white: 0.010), location: 1.00),
            ],
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}

#Preview {
    struct Preview: View {
        @StateObject var viewModel = StoryViewModel(pagesCount: 1)

        let view = SwapStoryPageView(
            page: .init(
                title: "Impenetrable Defense",
                subtitle: "No fumbles, no turnovers, no blind spots—your transaction is always protected"
            )
        )

        var body: some View {
            StoryView(viewModel: viewModel, pageViews: [StoryPageView(content: view)])
        }
    }

    return Preview()
        .ignoresSafeArea(edges: .bottom)
        .background(.black)
}
