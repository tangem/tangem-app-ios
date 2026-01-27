//
//  View+AdaptiveSizeSheetModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

struct AdaptiveSizeSheetModifier: ViewModifier {
    @StateObject private var viewModel = AdaptiveSizeSheetViewModel()

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            handler

            scrollableSheetContent(content: content)
        }
    }

    private var handler: some View {
        Color.clear
            .frame(height: viewModel.handleHeight)
            .overlay(alignment: .top) {
                GrabberView()
            }
    }

    private func scrollableSheetContent(content: Content) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            content
                .padding(.bottom, viewModel.defaultBottomPadding)
                .presentationDetents(contentHeight: viewModel.contentHeight, cornerRadius: viewModel.cornerRadius)
                .padding(.bottom, viewModel.scrollableContentBottomPadding)
                .readGeometry(\.size.height) {
                    viewModel.contentHeight = $0
                }
        }
        .scrollDisabled(viewModel.contentHeight <= viewModel.containerHeight)
        .readGeometry(\.size.height) {
            viewModel.containerHeight = $0
        }
    }
}

private extension View {
    func presentationDetents(contentHeight: CGFloat, cornerRadius: CGFloat) -> some View {
        presentationDetents([.height(contentHeight)])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(cornerRadius)
    }
}

extension View {
    func adaptivePresentationDetents() -> some View {
        modifier(AdaptiveSizeSheetModifier())
    }
}
