//
//  MainBottomSheetFooterView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import TangemUI
import TangemLocalization

struct MainBottomSheetFooterView: View {
    @ObservedObject var viewModel: MainBottomSheetFooterViewModel

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        redesignBody
    }

    var redesignBody: some View {
        VStack(spacing: .unit(.half)) {
            GrabberView(style: .redesigned)

            TangemSearchField(text: .constant(""))
                .placeholder(text: Localization.marketsSearchTitlePlaceholder)
                .cornerStyle(.capsule)
                .frame(height: MainBottomSheetHeaderView.Constants.searchFieldHeight)
                .padding(edgeInsets)
                .background(backgroundColor)
                .overlay(alignment: .top) {
                    snapshotOverlay
                }
                .cornerRadius(cornerRadius, corners: .topEdge)
                .background(alignment: .top) {
                    MainBottomSheetFooterShadowView(colorScheme: colorScheme, shadowColor: .black)
                }
        }
    }

    @ViewBuilder
    private var snapshotOverlay: some View {
        if let snapshotImage {
            Image(uiImage: snapshotImage)
        }
    }

    private var snapshotImage: UIImage? {
        switch colorScheme {
        case .light:
            return viewModel.footerSnapshot?.lightAppearance
        case .dark:
            return viewModel.footerSnapshot?.darkAppearance
        @unknown default:
            assertionFailure("Unknown color scheme '\(String(describing: colorScheme))' received")
            return viewModel.footerSnapshot?.lightAppearance
        }
    }

    private var backgroundColor: Color {
        Color.Tangem.Surface.level3
    }

    private var edgeInsets: EdgeInsets {
        let inset = MainBottomSheetHeaderView.Constants.searchFieldInsets.bottom
        let bottomInset = UIDevice.current.hasHomeScreenIndicator ? UIApplication.safeAreaInsets.bottom : inset
        return EdgeInsets(
            top: inset,
            leading: inset,
            bottom: bottomInset,
            trailing: inset
        )
    }

    private var cornerRadius: CGFloat {
        UIDevice.current.hasHomeScreenIndicator
            ? RootViewControllerFactory.Constants.notchDevicesOverlayCornerRadius
            : RootViewControllerFactory.Constants.notchlessDevicesOverlayCornerRadius
    }
}
