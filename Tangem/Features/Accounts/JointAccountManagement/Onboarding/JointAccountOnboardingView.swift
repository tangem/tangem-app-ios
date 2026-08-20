//
//  JointAccountOnboardingView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct JointAccountOnboardingView: View {
    @ObservedObject var viewModel: JointAccountOnboardingViewModel

    @State private var imageSize: CGSize = .zero

    var body: some View {
        ZStack(alignment: .top) {
            DesignSystem.Color.bgPrimary.ignoresSafeArea()

            previewImage
                .readGeometry(\.frame.size, bindTo: $imageSize)

            GroupedScrollView(contentType: .plain()) {
                // Text a little bit above image
                FixedSpacer(height: max(0, imageSize.height - 80))

                content
            }
        }
        .ignoresSafeArea()
        .toolbar {
            NavigationToolbarButton
                .close(placement: .topBarTrailing, action: viewModel.onCloseTap)
        }
        .backportTranslucentNavigationBar()
        .safeAreaInset(edge: .bottom) { footer }
    }

    private var previewImage: some View {
        Assets.jointAccountsOnboardingPreviewImage.image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: DesignSystem.Color.bgPrimary, location: 0.75),
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
    }

    private var content: some View {
        VStack(spacing: 16) {
            JointAccountHeaderTitle(
                title: Localization.commonJointAccount,
                subtitle: Localization.jointAccountOnboardingSubtitle
            )

            Text("[REDACTED_TODO_COMMENT]")
        }
    }

    private var footer: some View {
        TangemUI.Button(
            label: Localization.commonContinue,
            accessibilityLabel: nil
        ) {
            viewModel.onContinueTap()
        }
        .styleType(.default)
        .horizontalLayout(.infinity)
        .size(.x12)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .background {
            Fade(position: .bottom)
                .blurred()
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - Previews

#Preview {
    JointAccountOnboardingView(
        viewModel: JointAccountOnboardingViewModel(coordinator: nil)
    )
}
