//
//  Typography.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

final class TypographyDemoCoordinator: CoordinatorObject {
    let dismissAction: Action<DismissOptions?>
    let popToRootAction: Action<PopToRootOptions>

    @Published private(set) var rootViewModel: TypographyDemoViewModel?

    required init(
        dismissAction: @escaping Action<DismissOptions?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Void) {
        rootViewModel = .init()
    }
}

extension TypographyDemoCoordinator {
    struct Options {}
    typealias DismissOptions = Void
}

final class TypographyDemoViewModel: ObservableObject {
    let regularItems: [FontPreviewItem] = [
        .init(title: "largeTitle regular lorem ipsum", font: Fonts.Regular.largeTitle),
        .init(title: "title1 semibold lorem ipsum", font: Fonts.Regular.title1),
        .init(title: "title2 regular lorem ipsum", font: Fonts.Regular.title2),
        .init(title: "title3 regular lorem ipsum", font: Fonts.Regular.title3),
        .init(title: "headline regular lorem ipsum", font: Fonts.Regular.headline),
        .init(title: "body regular lorem ipsum", font: Fonts.Regular.body),
        .init(title: "callout regular lorem ipsum", font: Fonts.Regular.callout),
        .init(title: "subheadline regular lorem ipsum", font: Fonts.Regular.subheadline),
        .init(title: "footnote regular lorem ipsum", font: Fonts.Regular.footnote),
        .init(title: "caption1 regular lorem ipsum", font: Fonts.Regular.caption1),
        .init(title: "caption2 regular lorem ipsum", font: Fonts.Regular.caption2),
    ]

    let boldItems: [FontPreviewItem] = [
        .init(title: "largeTitle bold lorem ipsum", font: Fonts.Bold.largeTitle),
        .init(title: "title1 bold lorem ipsum", font: Fonts.Bold.title1),
        .init(title: "title2 bold lorem ipsum", font: Fonts.Bold.title2),
        .init(title: "title3 bold lorem ipsum", font: Fonts.Bold.title3),
        .init(title: "headline regular lorem ipsum", font: Fonts.Bold.headline),
        .init(title: "body semibold lorem ipsum", font: Fonts.Bold.body),
        .init(title: "callout medium lorem ipsum", font: Fonts.Bold.callout),
        .init(title: "subheadline medium lorem ipsum", font: Fonts.Bold.subheadline),
        .init(title: "footnote semibold lorem ipsum", font: Fonts.Bold.footnote),
        .init(title: "caption1 medium lorem ipsum", font: Fonts.Bold.caption1),
        .init(title: "caption2 semibold lorem ipsum", font: Fonts.Bold.caption2),
    ]

    let regularStaticItems: [FontPreviewItem] = [
        .init(title: "largeTitle 34 regular lorem ipsum", font: Fonts.RegularStatic.largeTitle),
        .init(title: "title1 28 semibold lorem ipsum", font: Fonts.RegularStatic.title1),
        .init(title: "title2 22 regular lorem ipsum", font: Fonts.RegularStatic.title2),
        .init(title: "title3 20 regular lorem ipsum", font: Fonts.RegularStatic.title3),
        .init(title: "headline 17 semibold lorem ipsum", font: Fonts.RegularStatic.headline),
        .init(title: "body 17 regular lorem ipsum", font: Fonts.RegularStatic.body),
        .init(title: "callout 16 regular lorem ipsum", font: Fonts.RegularStatic.callout),
        .init(title: "subheadline 15 regular lorem ipsum", font: Fonts.RegularStatic.subheadline),
        .init(title: "footnote 13 regular lorem ipsum", font: Fonts.RegularStatic.footnote),
        .init(title: "caption1 12 regular lorem ipsum", font: Fonts.RegularStatic.caption1),
        .init(title: "caption2 11 regular lorem ipsum", font: Fonts.RegularStatic.caption2),
    ]

    let boldStaticItems: [FontPreviewItem] = [
        .init(title: "largeTitle 34 bold lorem ipsum", font: Fonts.BoldStatic.largeTitle),
        .init(title: "title1 28 bold lorem ipsum", font: Fonts.BoldStatic.title1),
        .init(title: "title2 22 bold lorem ipsum", font: Fonts.BoldStatic.title2),
        .init(title: "title3 20 semibold lorem ipsum", font: Fonts.BoldStatic.title3),
        .init(title: "headline 17 semibold lorem ipsum", font: Fonts.BoldStatic.headline),
        .init(title: "body 17 semibold lorem ipsum", font: Fonts.BoldStatic.body),
        .init(title: "callout 16 medium lorem ipsum", font: Fonts.BoldStatic.callout),
        .init(title: "subheadline 15 medium lorem ipsum", font: Fonts.BoldStatic.subheadline),
        .init(title: "footnote 13 semibold lorem ipsum", font: Fonts.BoldStatic.footnote),
        .init(title: "caption1 12 medium lorem ipsum", font: Fonts.BoldStatic.caption1),
        .init(title: "caption2 11 semibold lorem ipsum", font: Fonts.BoldStatic.caption2),
    ]
}

struct TypographyDemoCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: TypographyDemoCoordinator
    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                TypographyDemoView(viewModel: rootViewModel)
            }
        }
    }
}

struct TypographyDemoView: View {
    @ObservedObject var viewModel: TypographyDemoViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                FontFamilySection(title: "Regular", items: viewModel.regularItems)

                FontFamilySection(title: "Bold", items: viewModel.boldItems)

                FontFamilySection(title: "RegularStatic", items: viewModel.regularStaticItems)

                FontFamilySection(title: "BoldStatic", items: viewModel.boldStaticItems)
            }
        }
        .padding(12)
    }
}

struct FontPreviewItem: Identifiable {
    let title: String
    let font: Font

    var id: String {
        String(describing: self)
    }
}

struct FontPreviewRow: View {
    let item: FontPreviewItem

    var body: some View {
        Text(item.title)
            .style(
                item.font,
                color: Colors.Text.primary1
            )
            .background(Color.red.opacity(0.25))
            .frame(maxWidth: .infinity)
    }
}

struct FontFamilySection: View {
    let title: String
    let items: [FontPreviewItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .style(
                    Fonts.Bold.title2,
                    color: Colors.Text.primary1
                )

            ForEach(items) { item in
                FontPreviewRow(item: item)
            }
        }
        .padding(.vertical, 16)
    }
}
