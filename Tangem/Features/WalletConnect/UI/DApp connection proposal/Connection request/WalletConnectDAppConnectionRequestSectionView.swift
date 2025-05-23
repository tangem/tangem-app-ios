//
//  WalletConnectDAppConnectionRequestSectionView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct WalletConnectDAppConnectionRequestSectionView: View {
    let viewModel: WalletConnectDAppConnectionRequestViewState.ConnectionRequestSection
    let tapAction: () -> Void

    @State private var connectionRequestIconIsRotating = false

    var body: some View {
        VStack(spacing: .zero) {
            titleRow

            if case .content(let contentState) = viewModel, contentState.isExpanded {
                expandableContent(contentState)
                    .transition(
                        .move(edge: .bottom).animation(.timingCurve(0.76, 0, 0.24, 1, duration: 0.5))
                        .combined(with: .opacity.animation(.timingCurve(0.65, 0, 0.35, 1, duration: 0.3).delay(0.2)))
                    )
            }
        }
    }

    private var titleRow: some View {
        Button(action: tapAction) {
            HStack(spacing: 8) {
                viewModel.iconAsset.image
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Colors.Icon.accent)
                    .rotationEffect(.degrees(connectionRequestIconIsRotating ? 360 : 0))
                    .id(viewModel.id)
                    .animation(connectionRequestIconAnimation, value: connectionRequestIconIsRotating)
                    .transition(.opacity)

                Text(viewModel.label)
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)
                    .id(viewModel.id)
                    .transition(.opacity)

                Spacer(minLength: 4)

                if case .content(let contentState) = viewModel {
                    contentState.trailingIconAsset.image
                        .resizable()
                        .frame(width: 18, height: 24)
                        .foregroundStyle(Colors.Icon.informative)
                        .rotationEffect(.degrees(contentState.isExpanded ? 90 : 0))
                        .animation(.timingCurve(0.65, 0, 0.35, 1, duration: 0.3).delay(0.2), value: contentState.isExpanded)
                }
            }
            .frame(height: 46)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onAppear {
            connectionRequestIconIsRotating = viewModel.isLoading
        }
        .onChange(of: viewModel.isLoading) { isLoading in
            connectionRequestIconIsRotating = isLoading
        }
    }

    private func expandableContent(
        _ contentState: WalletConnectDAppConnectionRequestViewState.ConnectionRequestSection.ContentState
    ) -> some View {
        VStack(spacing: .zero) {
            connectionRequestBulletGroup(contentState.wouldLikeToGroup)
            Spacer()
                .frame(height: 12)

            Divider()
                .frame(height: 1)
                .overlay(Colors.Stroke.primary)
                .padding(.horizontal, 14)

            Spacer()
                .frame(height: 12)

            connectionRequestBulletGroup(contentState.wouldNotBeAbleToGroup)
        }
        .padding(.top, 8)
        .padding(.bottom, 14)
    }

    private func connectionRequestBulletGroup(
        _ bulletGroup: WalletConnectDAppConnectionRequestViewState.ConnectionRequestSection.BulletGroup
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(bulletGroup.label)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            VStack(spacing: 12) {
                ForEach(bulletGroup.points, id: \.self) { bulletPoint in
                    HStack(spacing: 12) {
                        Image(systemName: bulletPoint.sfSymbol)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(bulletPoint.iconColor)
                            .frame(width: 24, height: 24)
                            .background {
                                Circle()
                                    .fill(bulletPoint.iconColor.opacity(0.1))
                            }

                        Text(bulletPoint.title)
                            .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private var connectionRequestIconAnimation: Animation? {
        connectionRequestIconIsRotating
            ? .linear(duration: 1).repeatForever(autoreverses: false)
            : nil
    }

}
