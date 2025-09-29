//
//  ExpandedContentWrapperView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct ExpandedContentWrapperView<Content: View, Header: View>: View {
    @State private var contentHeight: CGFloat = 0
    @State private var shouldShowContent = false

    let header: Header
    let content: Content
    let onTap: () -> Void

    var body: some View {
        ZStack {
            contentWithHeader
                .readGeometry(\.frame.height) { height in
                    withAnimation {
                        contentHeight = height
                    }
                }
                .opacity(0)

            if shouldShowContent {
                contentWithHeader
                    .transition(.expandedViewTransition)
                    .transformEffect(.identity)
            }
        }
        .frame(height: contentHeight)
        .task {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 sec
            withAnimation {
                shouldShowContent = true
            }
        }
    }

    private var contentWithHeader: some View {
        VStack(spacing: 8) {
            header
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        shouldShowContent = false
                    }

                    onTap()
                }

            content
        }
    }
}
