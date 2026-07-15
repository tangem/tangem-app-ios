//
//  TangemPaySelectPlanView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemUI
import TangemUIUtils

struct TangemPaySelectPlanView: View {
    @ObservedObject var viewModel: TangemPaySelectPlanViewModel

    @State private var scrollID: String?

    var body: some View {
        content
            .background { background }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !viewModel.isLoading {
                    footer
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .alert(item: $viewModel.alert) { $0.alert }
            .task { await viewModel.loadTransitions() }
            .modifyView { view in
                if #unavailable(iOS 26.0) {
                    view.backportTranslucentNavigationBar()
                } else {
                    view
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            plansContent
        }
    }

    private var plansContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                carousel
                    .padding(.top, 8)
                    .padding(.bottom, 88)

                TangemPayCardPageIndicatorRedesigned(
                    count: viewModel.plans.count,
                    selectedIndex: viewModel.selectedIndex
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 24)
                .padding(.top, 24)

                VStack(alignment: .leading, spacing: 16) {
                    Text(viewModel.selectedPlan?.name ?? "")
                        .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    pointsList
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
                .animation(.default, value: viewModel.selectedIndex)
            }
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private var carousel: some View {
        if #available(iOS 17.0, *) {
            leadingPeekCarousel
        } else {
            legacyCarousel
        }
    }

    @available(iOS 17.0, *)
    private var leadingPeekCarousel: some View {
        GeometryReader { proxy in
            let trailingInset = max(
                Constants.cardLeadingInset,
                proxy.size.width - Constants.cardLeadingInset - Constants.cardWidth
            )

            ScrollView(.horizontal) {
                HStack(spacing: Constants.cardSpacing) {
                    ForEach(viewModel.plans) { plan in
                        planCard(plan)
                            .id(plan.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrollID, anchor: .leading)
            .scrollClipDisabled()
            .contentMargins(.leading, Constants.cardLeadingInset, for: .scrollContent)
            .contentMargins(.trailing, trailingInset, for: .scrollContent)
            .onChange(of: scrollID) { _, new in
                guard let new, viewModel.selectedPlanID != new else { return }
                viewModel.selectedPlanID = new
            }
            .onChange(of: viewModel.selectedPlanID) { _, new in
                guard scrollID != new else { return }
                scrollID = new
            }
        }
        .frame(height: Constants.cardHeight)
    }

    private var legacyCarousel: some View {
        TabView(selection: $viewModel.selectedPlanID) {
            ForEach(viewModel.plans) { plan in
                planCard(plan)
                    .tag(plan.id as String?)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: Constants.cardHeight)
    }

    private func planCard(_ plan: TangemPaySelectPlanViewModel.Plan) -> some View {
        KFImage(plan.imageURL.flatMap { URL(string: $0) })
            .placeholder {
                Assets.Visa.cardPlatinum.image
                    .resizable()
            }
            .resizable()
            .scaledToFit()
            .frame(width: Constants.cardWidth, height: Constants.cardHeight)
    }

    private var pointsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(viewModel.selectedPlan?.points ?? []) { point in
                HStack(alignment: .top, spacing: 8) {
                    Assets.infoCircle20.image
                        .renderingMode(.template)
                        .foregroundStyle(DesignSystem.Color.iconPrimary)

                    VStack(alignment: .leading, spacing: 0) {
                        Text(point.title)
                            .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)

                        if let subtitle = point.subtitle {
                            Text(subtitle)
                                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(viewModel.navigationTitle)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
        }

        NavigationToolbarButton.close(placement: .topBarTrailing, action: viewModel.close)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            TangemButtonV2(
                label: AttributedString(viewModel.comparePlansButtonTitle),
                accessibilityLabel: viewModel.comparePlansButtonTitle,
                action: viewModel.comparePlans
            )
            .size(.x12)
            .styleType(.secondary)
            .horizontalLayout(.infinity)
            .disabled(viewModel.isPlacingOrder)

            TangemButtonV2(
                label: AttributedString(viewModel.selectButtonTitle),
                accessibilityLabel: viewModel.selectButtonTitle,
                action: viewModel.select
            )
            .size(.x12)
            .styleType(.default)
            .horizontalLayout(.infinity)
            .isLoading(viewModel.isPlacingOrder)
            .disabled(!viewModel.isSelectEnabled)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(alignment: .bottom) {
            BottomFadeWithBlur(backgroundColor: DesignSystem.Color.bgPrimary)
        }
    }

    private var background: some View {
        DesignSystem.Color.bgPrimary
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color.white.opacity(0.06), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 360)
            }
            .ignoresSafeArea()
    }
}

private extension TangemPaySelectPlanView {
    enum Constants {
        static let cardWidth: CGFloat = 266
        static let cardHeight: CGFloat = 172
        static let cardLeadingInset: CGFloat = 24
        static let cardSpacing: CGFloat = 88
    }
}
