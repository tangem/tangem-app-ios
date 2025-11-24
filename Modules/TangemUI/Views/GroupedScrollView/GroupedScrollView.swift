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
    private let contentType: ContentType
    private let showsIndicators: Bool?
    private let content: () -> Content

    private var interContentPadding: CGFloat = 0
    private var horizontalPadding: CGFloat = 16

    @available(iOS, deprecated: 100000.0, message: "Use the init(contentType:_) instead")
    public init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat = 0,
        @ViewBuilder content: @escaping () -> Content
    ) {
        contentType = .lazy(alignment: alignment, spacing: spacing)
        showsIndicators = nil
        self.content = content
    }

    @available(iOS, deprecated: 16.0, message: "Use the scrollIndicators(:_) modifier instead")
    public init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat = 0,
        showsIndicators: Bool,
        @ViewBuilder content: @escaping () -> Content
    ) {
        contentType = .lazy(alignment: alignment, spacing: spacing)
        self.showsIndicators = showsIndicators
        self.content = content
    }

    @available(iOS, deprecated: 16.0, message: "Use the scrollIndicators(:_) modifier instead")
    public init(
        contentType: ContentType,
        showsIndicators: Bool,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.contentType = contentType
        self.showsIndicators = showsIndicators
        self.content = content
    }

    public init(
        contentType: ContentType,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.contentType = contentType
        self.content = content
        showsIndicators = nil
    }

    public var body: some View {
        makeScrollView {
            contentView
                .padding(.horizontal, horizontalPadding)
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

    @ViewBuilder
    private func makeScrollView<ScrollViewContent: View>(content: () -> ScrollViewContent) -> some View {
        if let showsIndicators {
            ScrollView(showsIndicators: showsIndicators, content: content)
        } else {
            ScrollView(content: content)
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
#Preview {
    struct ViewModel: Identifiable {
        let id = UUID()
        let text: String
    }

    return GroupedScrollView {
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
#endif
