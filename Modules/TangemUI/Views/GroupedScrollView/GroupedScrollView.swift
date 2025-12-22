//
//  GroupedScrollView.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct GroupedScrollView<Content: View>: View {
    private let contentType: ContentType
    private let content: () -> Content

    private var interContentPadding: CGFloat = 0

    public init(contentType: ContentType = .lazy(alignment: .center, spacing: .zero), @ViewBuilder content: @escaping () -> Content) {
        self.contentType = contentType
        self.content = content
    }

    public var body: some View {
        ScrollView {
            contentView
                .padding(.horizontal, 16)
                .padding(.vertical, interContentPadding)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch contentType {
        case .plain(let alignment, let spacing):
            VStack(alignment: alignment, spacing: spacing, content: content)
        case .lazy(let alignment, let spacing):
            LazyVStack(alignment: alignment, spacing: spacing, content: content)
        }
    }
}

public extension GroupedScrollView {
    enum ContentType {
        case plain(alignment: HorizontalAlignment = .center, spacing: CGFloat = .zero)
        case lazy(alignment: HorizontalAlignment = .center, spacing: CGFloat = .zero)
    }
}

// MARK: - Setupable

extension GroupedScrollView: Setupable {
    public func interContentPadding(_ padding: CGFloat) -> Self {
        map { $0.interContentPadding = padding }
    }
}

#if DEBUG
struct SettingsViewGroupedScrollView_Previews: PreviewProvider {
    struct ViewModel: Identifiable {
        let id = UUID()
        let text: String
    }

    static var previews: some View {
        GroupedScrollView {
            let models = [
                ViewModel(text: "Text1"),
                ViewModel(text: "Text2"),
            ]

            GroupedSection(models) {
                Text($0.text)
            } footer: {
                Text("I am footer")
                    .frame(maxWidth: .infinity)
                    .background(Colors.Background.action)
            }
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }
}
#endif
