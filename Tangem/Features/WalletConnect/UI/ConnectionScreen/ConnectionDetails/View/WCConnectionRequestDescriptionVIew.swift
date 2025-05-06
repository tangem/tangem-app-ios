//
//  WCConnectionRequestDescriptionVIew.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct WCConnectionRequestDescriptionView: View {
    let isLoading: Bool

    @State private var connectingRotationAngle: Angle = .degrees(0)
    @State private var connectionRequestChevronAngle: Angle = .degrees(0)
    @State private var isConnectionRequestDescriptionVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            connectionRequestHeader
                .clipShape(Rectangle())
                .padding(.horizontal, 16)
                .onTapGesture {
                    showDescription()

                    connectionRequestChevronAngle = .degrees(isConnectionRequestDescriptionVisible ? 90 : 0)
                }
                .animation(makeDefaultAnimationCurve(duration: 0.4), value: isLoading)

            connectionRequestDescription
        }
    }

    private func showDescription() {
        let animation: Animation = if isConnectionRequestDescriptionVisible {
            .timingCurve(0.65, 0, 0.35, 1, duration: 0.3)
        } else {
            .timingCurve(0.76, 0, 0.24, 1, duration: 0.5)
        }

        withAnimation(animation) {
            isConnectionRequestDescriptionVisible.toggle()
        }
    }
}

// MARK: - Header

private extension WCConnectionRequestDescriptionView {
    @ViewBuilder
    var connectionRequestHeader: some View {
        if isLoading {
            connectionRequestHeaderStub
        } else {
            HStack(alignment: .center, spacing: 8) {
                Assets.connectNew.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.accent)

                Text("Connection request")
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Assets.WalletConnect.chevronRight.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.informative)
                    .rotationEffect(connectionRequestChevronAngle)
                    .animation(makeDefaultAnimationCurve(duration: 0.3), value: connectionRequestChevronAngle)
            }
        }
    }

    var connectionRequestHeaderStub: some View {
        HStack(alignment: .center, spacing: 8) {
            Assets.WalletConnect.load.image
                .renderingMode(.template)
                .resizable()
                .frame(size: .init(bothDimensions: 24))
                .foregroundStyle(Colors.Icon.accent)
                .rotationEffect(connectingRotationAngle)
                .animation(connectingAnimationCurve, value: connectingRotationAngle)
                .onAppear {
                    connectingRotationAngle = .degrees(360)
                }

            Text("Connecting")
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Description

private extension WCConnectionRequestDescriptionView {
    enum ActionPermission {
        case allowed
        case denied
    }

    func connectionRequestRow(type: ActionPermission, text: String) -> some View {
        let foregroundStyle: Color = switch type {
        case .allowed: Colors.Icon.accent
        case .denied: Colors.Icon.warning
        }

        let image: Image = switch type {
        case .allowed: Assets.WalletConnect.miniCheck.image
        case .denied: Assets.cross.image
        }

        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .foregroundStyle(foregroundStyle.opacity(0.1))
                    .frame(size: .init(bothDimensions: 24))
                image
                    .renderingMode(.template)
                    .foregroundStyle(foregroundStyle)
            }

            Text(text)
                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
        }
    }

    @ViewBuilder
    var connectionRequestDescription: some View {
        if isConnectionRequestDescriptionVisible {
            VStack(alignment: .leading, spacing: 0) {
                Text("Would like to")
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .padding(.bottom, 8)

                connectionRequestRow(type: .allowed, text: "View your wallet balance and activity")
                    .padding(.bottom, 12)

                connectionRequestRow(type: .allowed, text: "Request approval for transactions")

                Divider()
                    .padding(.vertical, 12)

                Text("Will not be able to")
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .padding(.bottom, 8)

                connectionRequestRow(type: .denied, text: "Sign transactions without your notice")
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .transition(requestDescriptionTransition)
        }
    }
}

// MARK: - UI Helpers

private extension WCConnectionRequestDescriptionView {
    var requestDescriptionTransition: AnyTransition {
        .asymmetric(
            insertion:
            .move(edge: .bottom)
                .animation(.timingCurve(0.76, 0, 0.24, 1, duration: 0.5))
                .combined(
                    with: .opacity.animation(makeDefaultAnimationCurve(duration: 0.3).delay(0.2))
                ),
            removal:
            .move(edge: .bottom)
                .animation(makeDefaultAnimationCurve(duration: 0.5))
                .combined(
                    with: .opacity.animation(makeDefaultAnimationCurve(duration: 0.3))
                )
        )
    }

    var connectingAnimationCurve: Animation {
        .timingCurve(0.45, 0.19, 0.67, 0.86, duration: 1).repeatForever(autoreverses: false)
    }

    func makeDefaultAnimationCurve(duration: TimeInterval) -> Animation {
        .timingCurve(0.65, 0, 0.35, 1, duration: duration)
    }
}
