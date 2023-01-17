//
//  GroupedScrollView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import UIKit

struct GroupedScrollView<Content: View>: View {
    private let alignment: HorizontalAlignment
    private let spacing: CGFloat
    private let content: () -> Content

    private var horizontalPadding: CGFloat = 16

    init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat = 0,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        ScrollView {
            stackContent
                .padding(.horizontal, horizontalPadding)
        }
    }

    @ViewBuilder
    private var stackContent: some View {
        if #available(iOS 14.0, *) {
            LazyVStack(alignment: alignment, spacing: spacing, content: content)
        } else {
            VStack(alignment: alignment, spacing: spacing, content: content)
        }
    }
}

// MARK: - Setupable

extension GroupedScrollView: Setupable {
    func horizontalPadding(_ padding: CGFloat) -> Self {
        map { $0.horizontalPadding = padding }
    }
}

struct GroupedScrollView_Previews: PreviewProvider {
    static var previews: some View {
        GroupedScrollView {
            let viewModels = [
                DefaultRowViewModel(title: Localization.detailsChat, action: {}),
                DefaultRowViewModel(title: Localization.detailsRowTitleSendFeedback, action: {}),
            ]

            GroupedSection(viewModels) {
                DefaultRowView(viewModel: $0)
            } footer: {
                DefaultFooterView("Colors.Background.secondary.edgesIgnoringSafeArea(.all)")
            }
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }
}
