//
//  FeedTabPagerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct FeedTabPagerView<Tab: Identifiable & Equatable, Content: View>: View {
    @ObservedObject var pager: FeedTabPager<Tab>
    let selection: Tab
    let onPageChange: (Tab) -> Void
    let onSettle: () -> Void
    let content: (FeedTabPage<Tab>) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection

    @State private var contentWidth: CGFloat = 0
    @State private var slideGeneration = 0

    init(
        pager: FeedTabPager<Tab>,
        selection: Tab,
        onPageChange: @escaping (Tab) -> Void = { _ in },
        onSettle: @escaping () -> Void = {},
        @ViewBuilder content: @escaping (FeedTabPage<Tab>) -> Content
    ) {
        self.pager = pager
        self.selection = selection
        self.onPageChange = onPageChange
        self.onSettle = onSettle
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .top) {
            ForEach(pager.pages) { page in
                content(page)
                    .lockedGeometry()
                    .offset(x: page.offset * slideWidth)
                    .opacity(page.isPreparing ? 0 : 1)
                    .allowsHitTesting(!page.isPreparing)
                    .accessibilityHidden(page.isPreparing)
            }
        }
        .onGeometryChange(for: CGFloat.self, of: \.size.width) { contentWidth = $0 }
        .onChange(of: selection, perform: show)
    }
}

// MARK: - Switching

private extension FeedTabPagerView {
    var slideWidth: CGFloat {
        layoutDirection == .leftToRight ? contentWidth : -contentWidth
    }

    func show(_ tab: Tab) {
        guard #available(iOS 17.0, *), !reduceMotion else {
            pager.show(tab)
            onPageChange(tab)
            onSettle()
            return
        }

        pager.startSlide(to: tab)
        onPageChange(tab)
        slideGeneration += 1
        let generation = slideGeneration

        Task { @MainActor in
            try? await ContinuousClock().sleep(for: .milliseconds(Constants.slideDelay))
            guard generation == slideGeneration else { return }

            var preparationTransaction = Transaction()
            preparationTransaction.disablesAnimations = true
            let didPreparePage = withTransaction(preparationTransaction) {
                pager.prepareSlide()
            }
            if didPreparePage {
                try? await ContinuousClock().sleep(for: .milliseconds(Constants.slideDelay))
                guard generation == slideGeneration else { return }
            }

            withAnimation(Constants.slideAnimation) {
                pager.slide()
            } completion: {
                guard generation == slideGeneration else { return }

                pager.settleSlide()
                onSettle()
            }
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let slideDelay = 50
    static let slideAnimation: Animation = .interpolatingSpring(mass: 1, stiffness: 400, damping: 40)
}

// MARK: - Geometry

private extension View {
    @ViewBuilder
    func lockedGeometry() -> some View {
        if #available(iOS 17.0, *) {
            geometryGroup()
        } else {
            self
        }
    }
}
