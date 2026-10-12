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

            GroupedScrollView(contentType: .plain(alignment: .leading)) {
                // Text a little bit above image
                FixedSpacer(height: max(0, imageSize.height - 80))

                content
            }
            .horizontalPadding(Constants.contentHorizontalPadding)
        }
        .ignoresSafeArea()
        .toolbar {
            NavigationToolbarButton
                .close(placement: .topBarTrailing, action: viewModel.onCloseTap)
        }
        .translucentNavigationBar()
        .safeAreaInset(edge: .bottom) { footer }
        .ignoresSafeArea(.keyboard)
    }

    /// The artwork carries the avatars alone, on transparency: the backdrop it sits on is a plain gradient, and
    /// drawing it here rather than baking it into the asset keeps the asset small and the fade smooth at any width.
    private var previewImage: some View {
        LinearGradient(
            colors: [Constants.backdropColor, .clear],
            startPoint: .top,
            endPoint: .bottom
        )
        .aspectRatio(Constants.backdropAspectRatio, contentMode: .fit)
        .overlay(alignment: .topLeading) {
            GeometryReader { proxy in
                Assets.jointAccountsOnboardingPreviewImage.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: proxy.size.width * Constants.artworkWidthFraction)
                    .offset(
                        x: proxy.size.width * Constants.artworkLeadingFraction,
                        y: proxy.size.height * Constants.artworkTopFraction
                    )
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Constants.titleToPointsSpacing) {
            JointAccountHeaderTitle(
                title: Localization.commonJointAccount,
                subtitle: Localization.jointAccountOnboardingSubtitle
            )

            points
        }
    }

    private var points: some View {
        VStack(alignment: .leading, spacing: Constants.pointsSpacing) {
            ForEach(viewModel.points) { point in
                pointView(point)
            }
        }
    }

    private func pointView(_ point: JointAccountOnboardingViewModel.Point) -> some View {
        HStack(alignment: .top, spacing: Constants.pointIconSpacing) {
            point.icon.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconSecondary)
                .frame(size: Constants.pointIconSize)

            Text(attributedText(of: point))
                .font(token: DesignSystem.Font.subheadingMediumToken)
                .infinityFrame(axis: .horizontal, alignment: .leading)
        }
    }

    /// The lead is what the point is about and the description explains it, so the two run as one sentence and are
    /// told apart by colour alone.
    private func attributedText(of point: JointAccountOnboardingViewModel.Point) -> AttributedString {
        var lead = AttributedString(point.lead)
        lead.foregroundColor = DesignSystem.Color.textPrimary

        var description = AttributedString(" " + point.description)
        description.foregroundColor = DesignSystem.Color.textSecondary

        return lead + description
    }

    private var footer: some View {
        TangemUI.Button(
            label: Localization.commonContinue,
            accessibilityLabel: nil
        ) {
            viewModel.onContinueTap()
        }
        .styleType(.primary)
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

// MARK: - Constants

private extension JointAccountOnboardingView {
    enum Constants {
        /// The design lays the screen out on a 402×592 backdrop, and the artwork takes 296×222 of it at (45, 157).
        /// Kept as fractions so the placement holds on any screen width.
        static let backdropAspectRatio: CGFloat = 402.0 / 592.0
        static let artworkWidthFraction: CGFloat = 296.0 / 402.0
        static let artworkLeadingFraction: CGFloat = 45.0 / 402.0
        static let artworkTopFraction: CGFloat = 157.0 / 592.0
        /// Only ever this one shade, on any theme — it is part of the illustration rather than a surface.
        static let backdropColor = Color(red: 119.0 / 255.0, green: 196.0 / 255.0, blue: 255.0 / 255.0)

        static let contentHorizontalPadding: CGFloat = 24
        static let titleToPointsSpacing: CGFloat = 12
        static let pointsSpacing: CGFloat = 16
        static let pointIconSpacing: CGFloat = 12
        static let pointIconSize = CGSize(bothDimensions: 20)
    }
}

// MARK: - Previews

#Preview {
    JointAccountOnboardingView(
        viewModel: JointAccountOnboardingViewModel(
            creationHelper: JointAccountCreationHelper(userWalletModel: FakeUserWalletModel.wallet3Cards),
            coordinator: nil
        )
    )
}
