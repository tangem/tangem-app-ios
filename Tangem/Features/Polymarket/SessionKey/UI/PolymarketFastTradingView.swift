//
//  PolymarketFastTradingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemPolymarket
import TangemUI
import TangemUIUtils

struct PolymarketFastTradingView: View {
    @ObservedObject var viewModel: PolymarketFastTradingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.itemSpacing) {
                if !viewModel.foreignSigners.isEmpty {
                    foreignSignersSection
                }

                thisDeviceSection

                if !viewModel.otherDevices.isEmpty {
                    otherDevicesSection
                }
            }
            .padding(Constants.contentPadding)
        }
        .refreshable { await viewModel.refresh() }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .topNavigation(
            title: PolymarketFastTradingStrings.settingsTitle,
            leading: .custom(.back(action: { viewModel.handleViewAction(.close) }))
        )
        .bindAlert($viewModel.alert)
        .onAppear { viewModel.handleViewAction(.onAppear) }
        .modalStatus(item: $viewModel.revocation) { revocation in
            revocationConfirmation(revocation)
        }
        .modal(
            isPresented: $viewModel.isFAQPresented,
            size: .full,
            navigation: .title(PolymarketFastTradingStrings.title),
            content: { PolymarketFastTradingFAQView() }
        )
        .fullScreenCover(item: $viewModel.activation) { activation in
            PolymarketFastTradingActivationView(viewModel: activation)
        }
    }

    // MARK: - This device

    private var thisDeviceSection: some View {
        VStack(alignment: .leading, spacing: Constants.itemSpacing) {
            HStack(spacing: Constants.headerSpacing) {
                sectionTitle(PolymarketFastTradingStrings.thisDevice)

                Spacer(minLength: 0)

                faqLink
            }

            switch viewModel.thisDevice {
            case .device(let device):
                deviceRow(device)
            case .activationOffer(let authorization):
                activationCard(authorization)
            case .notice(let notice):
                MessageBanner(title: notice)
            case .loading:
                card(Row(.shimmer(subtitle: true)))
            case .failed:
                MessageBanner(title: Localization.commonUnknownError)
                    .variant(.error)
            case .exchangeUnreadable:
                MessageBanner(title: PolymarketFastTradingStrings.exchangeUnreadable)
                    .variant(.error)
                    .primaryButton(MessageBannerButton(title: Localization.commonRetry, action: { viewModel.handleViewAction(.retry) }))
            }
        }
    }

    private var faqLink: some View {
        SwiftUI.Button(action: { viewModel.handleViewAction(.openFAQ) }) {
            HStack(spacing: Constants.faqLinkSpacing) {
                Text(PolymarketFastTradingStrings.whatIsFastTrading)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)

                DesignSystem.Icons.Info.regular16.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
                    .accessibilityHidden(true)
            }
            .expandingHitArea(by: Constants.faqLinkHitAreaInset)
        }
        .buttonStyle(.plain)
    }

    private func activationCard(_ authorization: PolymarketFastTradingAuthorization) -> some View {
        MessageBanner(
            title: PolymarketFastTradingStrings.activationBannerTitle,
            description: PolymarketFastTradingStrings.activationBannerDescription
        )
        .glowRing(.magic)
        .primaryButton(MessageBannerButton(title: authorization.title, action: { viewModel.handleViewAction(.openActivation) }))
    }

    // MARK: - Other devices

    private var otherDevicesSection: some View {
        VStack(alignment: .leading, spacing: Constants.itemSpacing) {
            sectionTitle(PolymarketFastTradingStrings.otherDevices)

            ForEach(viewModel.otherDevices) { device in
                deviceRow(device)
            }
        }
    }

    // MARK: - Devices

    private func deviceRow(_ device: PolymarketFastTradingDevice) -> some View {
        card(
            Row(title: device.name, subtitle: device.subtitle)
                .lineOrder(.secondaryFirst)
                .titleAccessory {
                    if let expiryBadge = device.expiryBadge {
                        Badge(label: expiryBadge, accessibilityLabel: nil)
                            .size(.x4)
                            .appearance(.warning)
                    }
                }
                .start { PolymarketFastTradingDeviceAvatar(icon: device.icon) }
                .end { trailing(for: device) }
        )
    }

    @ViewBuilder
    private func trailing(for device: PolymarketFastTradingDevice) -> some View {
        switch device.trailing {
        case .hidden:
            EmptyView()
        case .button(let action):
            actionButton(title: action.title) {
                viewModel.handleViewAction(.device(action, device))
            }
        case .menu(let actions):
            Menu(
                content: {
                    Section {
                        menuButtons(actions.filter { !$0.isDestructive }, of: device)
                    }

                    Section {
                        menuButtons(actions.filter(\.isDestructive), of: device)
                    }
                },
                label: {
                    TangemUI.Button(
                        icon: DesignSystem.Icons.DotsHorizontal.regular20,
                        accessibilityLabel: Localization.commonMore,
                        action: {}
                    )
                    .styleType(.ghost)
                    .size(.x9)
                    .allowsHitTesting(false)
                }
            )
            .menuStyle(.button)
            .buttonStyle(.plain)
            .accessibilityLabel(Localization.commonMore)
            .disabled(viewModel.isProcessing)
        }
    }

    private func menuButtons(_ actions: [PolymarketFastTradingDevice.Action], of device: PolymarketFastTradingDevice) -> some View {
        ForEach(actions, id: \.self) { action in
            SwiftUI.Button(action.title, role: action.isDestructive ? .destructive : nil) {
                viewModel.handleViewAction(.device(action, device))
            }
        }
    }

    // MARK: - Foreign signers

    private var foreignSignersSection: some View {
        VStack(alignment: .leading, spacing: Constants.itemSpacing) {
            if viewModel.hasUnknownForeignSigners {
                MessageBanner(
                    title: PolymarketFastTradingStrings.foreignBannerTitle,
                    description: PolymarketFastTradingStrings.foreignDescription
                )
                .variant(.warning)
            }

            ForEach(viewModel.foreignSigners) { signer in
                card(foreignSignerRow(signer))
            }
        }
    }

    @ViewBuilder
    private func foreignSignerRow(_ signer: PolymarketFastTradingViewModel.ForeignSigner) -> some View {
        if signer.isBeingRevoked {
            Row(title: signer.title, subtitle: PolymarketFastTradingStrings.signerBeingRevoked)
                .lineOrder(.secondaryFirst)
                .start { PolymarketFastTradingDeviceAvatar(icon: .spinner) }
        } else {
            Row(title: signer.title, subtitle: PolymarketFastTradingStrings.foreignSigner)
                .lineOrder(.secondaryFirst)
                .start { PolymarketFastTradingDeviceAvatar(icon: .glyph(DesignSystem.Icons.Warning.regular20, .warning)) }
                .end {
                    actionButton(title: PolymarketFastTradingStrings.revoke) {
                        viewModel.handleViewAction(.revokeForeignSigner(signer))
                    }
                }
        }
    }

    // MARK: - Revocation

    private func revocationConfirmation(_ revocation: PolymarketFastTradingViewModel.Revocation) -> some View {
        ModalStatus(
            .warning,
            title: PolymarketFastTradingStrings.revocationTitle,
            description: revocation.message
        )
        .footer {
            Footer(.signingButton(SigningActionButtonView(
                type: viewModel.signingButtonType,
                title: PolymarketFastTradingStrings.revoke,
                isLoading: viewModel.isProcessing,
                isDisabled: false,
                action: { viewModel.handleViewAction(.confirmRevocation) }
            )))
        }
        .bindAlert($viewModel.alert)
    }

    // MARK: - Helpers

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
            .padding(.vertical, Constants.sectionTitleVerticalPadding)
            .accessibilityAddTraits(.isHeader)
    }

    private func actionButton(title: String, action: @escaping () -> Void) -> some View {
        TangemUI.Button(label: title, accessibilityLabel: nil, action: action)
            .styleType(.primary)
            .size(.x9)
            .disabled(viewModel.isProcessing)
    }

    private func card(_ content: some View) -> some View {
        content
            .roundedBackground(with: DesignSystem.Color.bgSecondary, padding: 0, radius: Constants.cardCornerRadius)
    }
}

// MARK: - Avatar

private struct PolymarketFastTradingDeviceAvatar: View {
    let icon: PolymarketFastTradingDevice.Icon

    var body: some View {
        switch icon {
        case .glyph(let image, let appearance):
            Avatar(.icon(image, appearance: appearance))
        case .spinner:
            Avatar(.icon(DesignSystem.Icons.LoadingSpinner.regular12, appearance: .info))
                .hidden()
                .overlay {
                    Circle()
                        .fill(DesignSystem.Color.bgStatusInfoSubtle)
                        .overlay {
                            Loader()
                                .loaderSize(.size20)
                                .loaderColor(DesignSystem.Color.iconBrand)
                        }
                }
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Constants

private extension PolymarketFastTradingView {
    enum Constants {
        static let contentPadding: CGFloat = 16
        static let itemSpacing: CGFloat = 8
        static let sectionTitleVerticalPadding: CGFloat = 8
        static let headerSpacing: CGFloat = 12
        static let faqLinkSpacing: CGFloat = 4
        static let faqLinkHitAreaInset: CGFloat = 14
        static let cardCornerRadius: CGFloat = 24
    }
}

// MARK: - Previews

#if DEBUG
private extension PolymarketFastTradingViewModel {
    static func preview(
        sessionKeys: [PolymarketSessionKey],
        localKeyAddress: String? = nil,
        signers: [PolymarketSessionSigner]? = nil
    ) -> PolymarketFastTradingViewModel {
        PolymarketFastTradingViewModel(
            service: PolymarketFastTradingPreviewService(sessionKeys: sessionKeys, localKeyAddress: localKeyAddress, signers: signers),
            signingButtonType: .requiredNFCInteraction,
            thisDeviceName: "iPhone 16 Air",
            onClose: {}
        )
    }
}

private typealias PreviewKey = PolymarketFastTradingPreviewService

#Preview("New device, another one expires soon") {
    PolymarketFastTradingView(viewModel: .preview(sessionKeys: [
        PreviewKey.sessionKey(address: "0x1", deviceName: "iPhone XR", status: .active, validUntil: Date().addingTimeInterval(29 * 24 * 60 * 60)),
    ]))
}

#Preview("This device: active") {
    PolymarketFastTradingView(viewModel: .preview(
        sessionKeys: [
            PreviewKey.sessionKey(address: "0x1", deviceName: "iPhone 16 Air", deviceId: PreviewKey.thisDeviceId, status: .active),
            PreviewKey.sessionKey(address: "0x2", deviceName: "iPhone XR", status: .active),
        ],
        localKeyAddress: "0x1"
    ))
}

#Preview("This device: paused") {
    PolymarketFastTradingView(viewModel: .preview(
        sessionKeys: [PreviewKey.sessionKey(address: "0x1", deviceName: "iPhone 16e", deviceId: PreviewKey.thisDeviceId, status: .active, isEnabled: false)],
        localKeyAddress: "0x1"
    ))
}

#Preview("This device: activating") {
    PolymarketFastTradingView(viewModel: .preview(
        sessionKeys: [PreviewKey.sessionKey(address: "0x1", deviceName: "iPhone 16 Air", deviceId: PreviewKey.thisDeviceId, status: .pending)],
        localKeyAddress: "0x1"
    ))
}

#Preview("This device: activation failed") {
    PolymarketFastTradingView(viewModel: .preview(
        sessionKeys: [PreviewKey.sessionKey(address: "0x1", deviceName: "iPhone 16 Air", deviceId: PreviewKey.thisDeviceId, status: .failed)],
        localKeyAddress: "0x1"
    ))
}

#Preview("This device: expired") {
    PolymarketFastTradingView(viewModel: .preview(
        sessionKeys: [PreviewKey.sessionKey(
            address: "0x1",
            deviceName: "iPhone 16 Air",
            deviceId: PreviewKey.thisDeviceId,
            status: .expired,
            validUntil: Date().addingTimeInterval(-24 * 60 * 60)
        )],
        localKeyAddress: "0x1"
    ))
}

#Preview("This device: reconnect needed") {
    PolymarketFastTradingView(viewModel: .preview(
        sessionKeys: [PreviewKey.sessionKey(address: "0x1", deviceName: "iPhone Air", deviceId: PreviewKey.thisDeviceId, status: .active)],
        localKeyAddress: "0x1",
        signers: []
    ))
}

#Preview("This device: revoking") {
    PolymarketFastTradingView(viewModel: .preview(
        sessionKeys: [PreviewKey.sessionKey(address: "0x1", deviceName: "iPhone 16 Air", deviceId: PreviewKey.thisDeviceId, status: .revoking)],
        localKeyAddress: "0x1"
    ))
}

#Preview("Other devices: every state") {
    PolymarketFastTradingView(viewModel: .preview(sessionKeys: [
        PreviewKey.sessionKey(address: "0x1", deviceName: "iPhone XR", status: .active),
        PreviewKey.sessionKey(address: "0x2", deviceName: "iPhone 16e", status: .active, isEnabled: false),
        PreviewKey.sessionKey(address: "0x3", deviceName: "iPhone 16 Air", status: .pending),
        PreviewKey.sessionKey(address: "0x4", deviceName: "iPhone 16 Air", status: .revoking),
        PreviewKey.sessionKey(address: "0x5", deviceName: "iPhone 16 Air", status: .failed),
        PreviewKey.sessionKey(address: "0x6", deviceName: "iPhone 16 Air", status: .expired, validUntil: Date().addingTimeInterval(-24 * 60 * 60)),
        PreviewKey.sessionKey(address: "0x7", deviceName: "iPhone 16 Air", status: .unknown("BROKEN")),
    ]))
}

#Preview("Unknown signers") {
    PolymarketFastTradingView(viewModel: .preview(
        sessionKeys: [],
        signers: [PolymarketSessionSigner(address: "0x8f3a1c9e2b7d4f6a0c5e8b1d3f7a9c2e4b6d8f0a", scopes: [], validUntil: nil)]
    ))
}
#endif
