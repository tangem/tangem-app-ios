//
//  GroupedScrollView.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUIUtils

public struct GroupedScrollView<Content: View>: View {
    private let alignment: HorizontalAlignment
    private let spacing: CGFloat
    private let content: () -> Content

    private var interContentPadding: CGFloat = 0
    private var horizontalPadding: CGFloat = 16

    public init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat = 0,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: alignment, spacing: spacing, content: content)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, interContentPadding)
        }
    }
}

extension GroupedScrollView: Setupable {
    public func interContentPadding(_ padding: CGFloat) -> Self {
        map { $0.interContentPadding = padding }
    }
}

// MARK: - Previews

#if DEBUG
struct GroupedScrollView_Previews: PreviewProvider {
    struct ViewModel: Identifiable {
        let id = UUID()
        let title: String
    }

    static var previews: some View {
        GroupedScrollView {
            let viewModels = [
                ViewModel(title: Localization.detailsChat),
                ViewModel(title: Localization.detailsRowTitleContactToSupport),
            ]

            GroupedSection(viewModels) { viewModel in
                Text(viewModel.title)
            } footer: {
                Text("Colors.Background.secondary.edgesIgnoringSafeArea(.all)")
            }
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }
}
#endif // DEBUG
