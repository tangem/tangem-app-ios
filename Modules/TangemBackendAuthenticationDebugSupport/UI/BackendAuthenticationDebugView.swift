//
//  BackendAuthenticationDebugView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

public struct BackendAuthenticationDebugView: View {
    @ObservedObject var viewModel: BackendAuthenticationDebugViewModel

    public init(viewModel: BackendAuthenticationDebugViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                valueRowsCard(viewModel.infoRows)

                if let registrationRow = viewModel.registrationRow {
                    card {
                        valueRow(title: registrationRow.title, value: registrationRow.value)
                            .end {
                                actionButton("Register", action: .registerDevice)

                                actionButton("Reset", action: .resetDeviceRegistration)
                            }
                    }
                }

                registeredWalletsCard

                valueRowsCard(viewModel.sessionRows)

                accessTokenExpirationCard

                sessionActionButtons
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .scrollIndicators(.hidden)
        .refreshable {
            await viewModel.reload()
        }
        .background(DesignSystem.Color.bgSecondary.ignoresSafeArea())
        .topNavigation(title: "Backend Auth")
        .alert(item: $viewModel.alert) { $0.alert }
    }

    private var registeredWalletsCard: some View {
        card {
            if viewModel.registeredWalletRows.isEmpty {
                valueRow(title: "Registered wallets", value: .text("none"))
            } else {
                ForEach(indexed: viewModel.registeredWalletRows, id: \.1.id) { index, userWalletInfo in
                    valueRow(title: "Registered wallet", value: .text(userWalletInfo.name))
                        .end {
                            actionButton("Unregister", action: .unregisterUserWallet(userWalletInfo.id))
                        }
                        .showDivider(index != viewModel.registeredWalletRows.count - 1)
                }
            }
        }
    }

    private var accessTokenExpirationCard: some View {
        card {
            TangemUI.Row(subtitle: "Custom access token expiry")
                .lineOrder(.secondaryFirst)
                .titleAccessory {
                    DatePicker(
                        "Custom access token expiry",
                        selection: $viewModel.accessTokenExpiration,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                }
                .end {
                    actionButton("Set", action: .setAccessTokenExpiration)
                }
        }
    }

    private var sessionActionButtons: some View {
        VStack(spacing: 8) {
            sessionActionButton(.forceRefresh)

            sessionActionButton(.corruptAccessToken)

            sessionActionButton(.expireAccessToken)

            sessionActionButton(.clearSessionTokens)
        }
    }

    private func card(@ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: .zero) {
            content()
        }
        .background(DesignSystem.Color.bgPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func valueRowsCard(_ rows: [BackendAuthenticationDebugViewModel.ValueRow]) -> some View {
        card {
            ForEach(indexed: rows) { index, row in
                valueRow(title: row.title, value: row.value)
                    .extraBottom {
                        if let subtitle = row.subtitle {
                            Text(subtitle)
                                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)
                        }
                    }
                    .end(icon: row.copyValue == nil ? nil : DesignSystem.Icons.Copy.regular20)
                    .showDivider(index != rows.count - 1)
                    .ifLet(row.copyValue) { view, _ in
                        view
                            .onTap {
                                viewModel.copy(row)
                            }
                            .accessibilityHint(Text("Copies the full value"))
                    }
            }
        }
    }

    private func valueRow(
        title: String,
        value: BackendAuthenticationDebugViewModel.ValueRow.Value
    ) -> TangemUI.Row<some View, EmptyView, EmptyView, EmptyView, EmptyView, EmptyView, EmptyView> {
        TangemUI.Row(subtitle: title)
            .lineOrder(.secondaryFirst)
            .titleAccessory {
                valueView(value)
            }
    }

    @ViewBuilder
    private func valueView(_ value: BackendAuthenticationDebugViewModel.ValueRow.Value) -> some View {
        switch value {
        case .text(let text):
            Text(text)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
        case .flag(true):
            flagIcon(DesignSystem.Icons.Success.filled20, color: DesignSystem.Color.iconStatusSuccess, accessibilityLabel: "Yes")
        case .flag(false):
            flagIcon(DesignSystem.Icons.Error.filled20, color: DesignSystem.Color.iconStatusError, accessibilityLabel: "No")
        }
    }

    private func flagIcon(_ icon: ImageType, color: Color, accessibilityLabel: String) -> some View {
        icon.image
            .renderingMode(.template)
            .foregroundStyle(color)
            .accessibilityLabel(accessibilityLabel)
    }

    private func actionButton(_ label: String, action: BackendAuthenticationDebugViewModel.Action) -> some View {
        TangemUI.Button(label: label, accessibilityLabel: action.title) {
            viewModel.perform(action)
        }
        .styleType(.secondary(.default))
        .size(.x8)
        .loading(.spinner(if: viewModel.runningAction == action))
        .enabled(isEnabled(action))
    }

    private func sessionActionButton(_ action: BackendAuthenticationDebugViewModel.Action) -> some View {
        TangemUI.Button(label: action.title, accessibilityLabel: nil) {
            viewModel.perform(action)
        }
        .styleType(.secondary(.default))
        .size(.x12)
        .horizontalLayout(.infinity)
        .loading(.spinner(if: viewModel.runningAction == action))
        .enabled(isEnabled(action))
    }

    private func isEnabled(_ action: BackendAuthenticationDebugViewModel.Action) -> Bool {
        guard let runningAction = viewModel.runningAction else {
            return true
        }

        return runningAction == action
    }
}
