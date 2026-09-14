//
//  StatusScreenShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct StatusScreenShowcase: View {
    @State private var appearance: StatusScreenAppearance = .success
    @State private var showsDescription = true
    @State private var showsBadge = false
    @State private var assetSlotKind: AssetSlotKind = .defaultIcon
    @State private var detailsKind: DetailsKind = .rows
    @State private var isPresented = false

    public init() {}

    enum AssetSlotKind: CaseIterable {
        case defaultIcon
        case custom

        var title: String {
            switch self {
            case .defaultIcon: "Default icon"
            case .custom: "Custom"
            }
        }
    }

    enum DetailsKind: CaseIterable {
        case none
        case rows
        case subtitledRows
        case custom
        case customAndRows

        var title: String {
            switch self {
            case .none: "None"
            case .rows: "Rows"
            case .subtitledRows: "Subtitled"
            case .custom: "Custom"
            case .customAndRows: "Both"
            }
        }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                configurationSection
                iconGallerySection
            }
            .padding(24)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .fullScreenCover(isPresented: $isPresented) { statusScreen }
    }
}

private extension StatusScreenShowcase {
    // MARK: - Sections

    var configurationSection: some View {
        section(title: "Configuration") {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Appearance", selection: $appearance) {
                    ForEach(StatusScreenAppearance.allCases, id: \.self) { appearance in
                        Text(title(for: appearance)).tag(appearance)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("Description", isOn: $showsDescription)
                Toggle("Header accessory badge", isOn: $showsBadge)

                labeledPicker("Asset slot", selection: $assetSlotKind, options: AssetSlotKind.allCases, title: \.title)
                labeledPicker("Details", selection: $detailsKind, options: DetailsKind.allCases, title: \.title)

                Button(label: "Present status screen", accessibilityLabel: nil) {
                    isPresented = true
                }
                .size(.x9)
                .styleType(.brand)
                .frame(maxWidth: .infinity)

                Text("Each presentation replays the entrance choreography: icon draw-on, texts, background tint, details, and footer.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var iconGallerySection: some View {
        section(title: "Status icons") {
            HStack(spacing: 24) {
                ForEach(StatusIcon.Glyph.allCases, id: \.self) { glyph in
                    StatusIcon(glyph)
                }

                StatusIcon(.checkmark)
                    .tint(DesignSystem.Color.iconPrimary)
                    .size(28)
                    .glow(false)
            }
        }
    }

    // MARK: - Composed screen

    @ViewBuilder
    var statusScreen: some View {
        switch assetSlotKind {
        case .defaultIcon:
            composed(baseScreen)
        case .custom:
            composed(baseScreen.assetSlot { customAssetSlot })
        }
    }

    var baseScreen: StatusScreen<EmptyView, EmptyView, EmptyView> {
        StatusScreen(
            title: "Your heart is broken",
            description: showsDescription ? "Aug 12, 13:24. We are not sorry for that." : nil,
            actionTitle: "Label",
            action: { isPresented = false }
        )
        .appearance(appearance)
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
                .fill(DesignSystem.Color.bgOpaquePrimary)
                .frame(width: 40, height: 40)
        }
    }

    var detailsRows: some View {
        VStack(spacing: 0) {
            Row(title: "Title", value: "Value")
                .showDivider()
            Row(title: "Title", value: "Value")
                .showDivider()
            Row(title: "Title", value: "Value")
        }
    }

    var subtitledDetailsRows: some View {
        VStack(spacing: 0) {
            Row(title: "Title", subtitle: "Subtitle", value: "Value", subvalue: "Subvalue")
                .showDivider()
            Row(title: "Title", subtitle: "Subtitle", value: "Value", subvalue: "Subvalue")
                .showDivider()
            Row(title: "Title", value: "Value")
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
                    .fill(DesignSystem.Color.bgOpaquePrimary)
                    .frame(width: 40, height: 40)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(DesignSystem.Color.bgOpaquePrimary)
            )
        }
    }

    // MARK: - Helpers

    func title(for appearance: StatusScreenAppearance) -> String {
        String(describing: appearance).capitalized
    }

    func labeledPicker<Kind: Hashable>(
        _ label: String,
        selection: Binding<Kind>,
        options: [Kind],
        title: KeyPath<Kind, String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Picker(label, selection: selection) {
                ForEach(options, id: \.self) { kind in
                    Text(kind[keyPath: title]).tag(kind)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }
}
