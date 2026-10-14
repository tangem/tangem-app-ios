//
//  StatusScreenShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct StatusScreenShowcase: View {
    @State private var appearance: StatusScreenAppearance = .success
    @State private var showsDescription = true
    @State private var showsBadge = false
    @State private var assetSlotKind: AssetSlotKind = .defaultIcon
    @State private var detailsKind: DetailsKind = .rows
    @State private var showsSecondaryAction = false
    @State private var showsFooterCaption = false
    @State private var showsActionIcon = false
    @State private var actionSigning: ActionSigningKind = .none
    @State private var isActionLoading = false
    @State private var isActionDisabled = false
    @State private var footerAxis: StatusScreenFooterAxis = .vertical
    @State private var isFooterHidden = false
    @State private var entranceID = 0
    @State private var actionTaps = 0
    @State private var isPresented = false

    var body: some View {
        DSShowcase("StatusScreen", layout: .fill) { controls in
            controls.picker("Appearance", $appearance)
            controls.toggle("Description", $showsDescription)
            controls.toggle("Header accessory badge", $showsBadge)
            controls.picker("Asset slot", $assetSlotKind)
            controls.picker("Details", $detailsKind)
            controls.toggle("Footer hidden", $isFooterHidden)

            if !isFooterHidden {
                controls.toggle("Secondary action", $showsSecondaryAction)
                controls.picker("Footer axis", $footerAxis, options: [.vertical, .horizontal])
                controls.toggle("Footer caption", $showsFooterCaption)
                controls.toggle("Action icon", $showsActionIcon)
                controls.picker("Action signing", $actionSigning)
                controls.toggle("Action loading", $isActionLoading)
                controls.toggle("Action disabled", $isActionDisabled)
                controls.readout("Action taps", "\(actionTaps)")
            }

            controls.action("Replay entrance") { entranceID += 1 }
            controls.action("Present full screen") { isPresented = true }
            controls.note("Each appearance replays the entrance choreography: icon draw-on, texts, background tint, details, and footer.")
        } stage: {
            statusScreen(appearance: appearance, onAction: { actionTaps += 1 })
                .id(entranceID)
                .fullScreenCover(isPresented: $isPresented) {
                    statusScreen(appearance: appearance, onAction: { isPresented = false })
                }
        } matrix: {
            DSShowcaseGroup("Appearance") {
                DSShowcaseMatrix(rows: StatusScreenAppearance.allCases) { appearance in
                    StatusScreen(
                        title: Sample(appearance).title,
                        description: Sample(appearance).description,
                        actionTitle: Sample(appearance).actionTitle,
                        action: {}
                    )
                    .appearance(appearance)
                    .frame(width: 260, height: 480)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
            }

            DSShowcaseGroup("Status icon") {
                DSShowcaseMatrix(rows: StatusIcon.Glyph.allCases, columns: IconStyle.allCases) { glyph, style in
                    statusIcon(glyph, style: style)
                }
            }
        }
        .onChange(of: appearance) { _ in
            entranceID += 1
        }
    }
}

private extension StatusScreenShowcase {
    // MARK: - Composed screen

    @ViewBuilder
    func statusScreen(appearance: StatusScreenAppearance, onAction: @escaping () -> Void) -> some View {
        let screen = baseScreen(appearance: appearance, onAction: onAction)

        switch assetSlotKind {
        case .defaultIcon:
            composed(screen)
        case .custom:
            composed(screen.assetSlot { customAssetSlot })
        }
    }

    func baseScreen(appearance: StatusScreenAppearance, onAction: @escaping () -> Void) -> StatusScreen<EmptyView, EmptyView, EmptyView> {
        let sample = Sample(appearance)

        var screen = StatusScreen(
            title: sample.title,
            description: showsDescription ? sample.description : nil,
            actionTitle: sample.actionTitle,
            action: onAction
        )
        .appearance(appearance)
        .footerAxis(footerAxis)
        .footerCaption(showsFooterCaption ? "Network fee $0.42 · arrives in about 30 seconds" : nil)
        .actionIcon(showsActionIcon ? DesignSystem.Icons.ShareIos.regular20 : nil)
        .actionSigning(actionSigning.type)
        .actionLoading(isActionLoading)
        .actionDisabled(isActionDisabled)
        .footerHidden(isFooterHidden)

        if showsSecondaryAction {
            screen = screen.secondaryAction(title: "View in explorer") {}
        }

        return screen
    }

    func composed<AssetSlot: View>(_ screen: StatusScreen<AssetSlot, EmptyView, EmptyView>) -> some View {
        screen
            .headerAccessory {
                if showsBadge {
                    Badge(label: "Current 5.5% net APY", accessibilityLabel: nil)
                        .appearance(.success)
                        .slotStart {
                            Circle()
                                .fill(DesignSystem.Color.iconStatusSuccess)
                                .frame(width: 6, height: 6)
                                .padding(.leading, 4)
                        }
                }
            }
            .details {
                switch detailsKind {
                case .none:
                    EmptyView()
                case .rows:
                    detailsRows
                case .subtitledRows:
                    subtitledDetailsRows
                case .custom:
                    customDetails
                case .customAndRows:
                    VStack(spacing: 8) {
                        customDetails

                        summaryRows
                    }
                }
            }
    }

    var customAssetSlot: some View {
        HStack(spacing: -8) {
            Circle()
                .fill(DesignSystem.Color.bgAccentGreen)
                .frame(width: 40, height: 40)

            Circle()
                .fill(DesignSystem.Color.bgTransparentPrimary)
                .frame(width: 40, height: 40)
        }
    }

    var detailsRows: some View {
        VStack(spacing: 0) {
            Row(title: "Amount", value: "0.25 ETH")
                .showDivider()
            Row(title: "Recipient", value: "0x71C7656EC7ab88b098defB751B7401B5f6d8976F")
                .showDivider()
            Row(title: "Network fee", value: "$0.42")
        }
    }

    var subtitledDetailsRows: some View {
        VStack(spacing: 0) {
            Row(title: "You sent", subtitle: "Ethereum", value: "0.25 ETH", subvalue: "$742.18")
                .showDivider()
            Row(title: "You received", subtitle: "Tether on Tron", value: "741.90 USDT", subvalue: "$741.90")
                .showDivider()
            Row(title: "Provider", value: "Changelly")
        }
    }

    var summaryRows: some View {
        VStack(spacing: 0) {
            Row(title: "Tokens bought", value: "500")
                .showDivider()
            Row(title: "Resolution Date", value: "22.03.2026")
                .showDivider()
            Row(title: "Fee", value: "$0.02")
        }
    }

    var customDetails: some View {
        VStack(spacing: 8) {
            MessageBanner(
                title: "Partially filled",
                description: "The order was filled partially. We'll certainly do our best, but there's still a chance it won't fill completely."
            )
            .variant(.warning)
            .slotStart {
                DesignSystem.Icons.Warning.regular24.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(DesignSystem.Color.iconStatusWarning)
            }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Will Uzbekistan win the 2026 FIFA World Cup?")
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                    Text("You vote No 85¢")
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Circle()
                    .fill(DesignSystem.Color.bgTransparentPrimary)
                    .frame(width: 40, height: 40)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(DesignSystem.Color.bgTransparentPrimary)
            )
        }
    }

    @ViewBuilder
    func statusIcon(_ glyph: StatusIcon.Glyph, style: IconStyle) -> some View {
        switch style {
        case .standard:
            StatusIcon(glyph)
        case .noGlow:
            StatusIcon(glyph)
                .glow(false)
        case .tinted:
            StatusIcon(glyph)
                .tint(DesignSystem.Color.iconPrimary)
                .size(28)
                .glow(false)
        }
    }
}

private extension StatusScreenShowcase {
    enum AssetSlotKind: CaseIterable {
        case defaultIcon
        case custom
    }

    enum ActionSigningKind: CaseIterable {
        case none
        case cardTap
        case holdToConfirm

        var type: SigningActionButtonViewType? {
            switch self {
            case .none: nil
            case .cardTap: .cardTap
            case .holdToConfirm: .holdToConfirm
            }
        }
    }

    enum DetailsKind: CaseIterable {
        case none
        case rows
        case subtitledRows
        case custom
        case customAndRows
    }

    enum IconStyle: CaseIterable {
        case standard
        case noGlow
        case tinted
    }

    struct Sample {
        let title: String
        let description: String
        let actionTitle: String

        init(_ appearance: StatusScreenAppearance) {
            switch appearance {
            case .neutral:
                title = "Request submitted"
                description = "We'll let you know as soon as the exchange provider confirms your order."
                actionTitle = "Got it"
            case .success:
                title = "0.25 ETH sent"
                description = "Sep 28, 14:02. The transaction is on its way to 0x71C7…976F."
                actionTitle = "Done"
            case .error:
                title = "Transaction failed"
                description = "The network rejected the transaction. Your funds haven't left the wallet."
                actionTitle = "Try again"
            case .warning:
                title = "Order partially filled"
                description = "Only 312.40 of 500 USDT were exchanged. The rest stays in your wallet."
                actionTitle = "Close"
            case .info:
                title = "Staking starts in 2 days"
                description = "Rewards for 32 SOL begin accruing once the validator activates your stake."
                actionTitle = "Continue"
            }
        }
    }
}
#endif
