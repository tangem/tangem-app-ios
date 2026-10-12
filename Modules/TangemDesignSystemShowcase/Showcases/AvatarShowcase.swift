//
//  AvatarShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import UIKit
import TangemAssets
import TangemUI

struct AvatarShowcase: View {
    @State private var kind: Kind = .user
    @State private var size: Avatar.Size = .size40
    @State private var appearance: Avatar.IconAppearance = .neutral
    @State private var transactionKind: Avatar.TransactionKind = .send
    @State private var status: Avatar.TransactionStatus = .progress
    @State private var initial = "M"
    @State private var isFallback = false
    @State private var fill: Fill = .palatinateBlue
    @State private var hasIdenticon = true
    @State private var asset: Asset = .flag
    @State private var isShimmer = false

    var body: some View {
        DSShowcase("Avatar") { controls in
            controls.picker("Variant", $kind)
            controls.picker("Size", $size, options: Self.figmaSizes)
            controls.toggle("Shimmer", $isShimmer)

            switch kind {
            case .icon:
                controls.picker("Appearance", $appearance)
            case .transaction:
                controls.picker("Type", $transactionKind)
                controls.picker("Status", $status)
            case .user:
                controls.toggle("Fallback", $isFallback)
                if !isFallback {
                    controls.text("Initial", $initial)
                    controls.picker("Fill", $fill)
                }
            case .address:
                controls.toggle("Identicon", $hasIdenticon)
            case .asset:
                controls.picker("Image", $asset)
            case .account:
                controls.picker("Fill", $fill)
            }
        } stage: {
            Avatar(content(for: kind), size: size)
                .environment(\.isShimmerActive, isShimmer)
        } matrix: {
            DSShowcaseGroup("Variant × size") {
                variantMatrix
            }

            DSShowcaseGroup("Shimmer") {
                variantMatrix
                    .environment(\.isShimmerActive, true)
            }

            DSShowcaseGroup("Icon appearance") {
                DSShowcaseMatrix(rows: Avatar.IconAppearance.allCases, columns: Self.figmaSizes) { appearance, size in
                    Avatar(.icon(Self.iconSample, appearance: appearance), size: size)
                }
            }

            DSShowcaseGroup("Transaction · size \(DSShowcaseLabel.text(size))") {
                DSShowcaseMatrix(rows: Avatar.TransactionKind.allCases, columns: Avatar.TransactionStatus.allCases) { kind, status in
                    Avatar(.transaction(kind, status: status), size: size)
                }
            }

            DSShowcaseGroup("User state") {
                DSShowcaseMatrix(rows: UserState.allCases, columns: Self.figmaSizes) { state, size in
                    Avatar(.user(state.user), size: size)
                }
            }

            DSShowcaseGroup("Account fill") {
                DSShowcaseMatrix(rows: Fill.allCases) { fill in
                    HStack(spacing: 8) {
                        Avatar(.account(Self.accountIcon, fill: fill.color), size: .size40)
                        Avatar(.user(.initial("M", fill: fill.color)), size: .size40)
                    }
                }
            }
        }
    }

    private var variantMatrix: some View {
        DSShowcaseMatrix(rows: Kind.allCases, columns: Self.figmaSizes) { kind, size in
            Avatar(sampleContent(for: kind), size: size)
        }
    }

    private func content(for kind: Kind) -> Avatar.Content {
        switch kind {
        case .icon: .icon(Self.iconSample, appearance: appearance)
        case .transaction: .transaction(transactionKind, status: status)
        case .user: .user(isFallback ? .fallback : .initial(String(initial.prefix(1)).uppercased(), fill: fill.color))
        case .address: .address(hasIdenticon ? Self.identicon : nil)
        case .asset: .asset(asset.image)
        case .account: .account(Self.accountIcon, fill: fill.color)
        }
    }

    private func sampleContent(for kind: Kind) -> Avatar.Content {
        switch kind {
        case .icon: .icon(Self.iconSample)
        case .transaction: .transaction(.send, status: .progress)
        case .user: .user(.initial("M", fill: Fill.palatinateBlue.color))
        case .address: .address(Self.identicon)
        case .asset: .asset(Asset.flag.image)
        case .account: .account(Self.accountIcon, fill: Fill.palatinateBlue.color)
        }
    }

    private static var figmaSizes: [Avatar.Size] {
        Avatar.Size.allCases.reversed()
    }

    private static var iconSample: ImageType {
        DesignSystem.Icons.Clock.regular20
    }

    private static var accountIcon: ImageType {
        Assets.Accounts.airplane
    }

    fileprivate static let identicon: Image = {
        let palette: [UIColor] = [
            UIColor(red: 0.93, green: 0.42, blue: 0.13, alpha: 1),
            UIColor(red: 0.55, green: 0.33, blue: 0.75, alpha: 1),
            UIColor(red: 0.42, green: 0.62, blue: 0.27, alpha: 1),
        ]
        let seed: UInt64 = 0x71C7656EC7AB88B0
        let cells = 8
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: cells, height: cells))

        let uiImage = renderer.image { context in
            for row in 0 ..< cells {
                for column in 0 ..< cells / 2 {
                    let bits = seed >> UInt64((row * cells / 2 + column) % 63)
                    palette[Int(bits % 3)].setFill()
                    context.fill(CGRect(x: column, y: row, width: 1, height: 1))
                    context.fill(CGRect(x: cells - 1 - column, y: row, width: 1, height: 1))
                }
            }
        }

        return Image(uiImage: uiImage).interpolation(.none)
    }()

    fileprivate static let flag: Image = {
        let stripes: [UIColor] = [
            UIColor(red: 0.0, green: 0.2, blue: 0.62, alpha: 1),
            UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1),
            UIColor(red: 0.82, green: 0.06, blue: 0.2, alpha: 1),
        ]
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: stripes.count, height: 1))

        let uiImage = renderer.image { context in
            for (index, color) in stripes.enumerated() {
                color.setFill()
                context.fill(CGRect(x: index, y: 0, width: 1, height: 1))
            }
        }

        return Image(uiImage: uiImage).interpolation(.none)
    }()
}

private extension AvatarShowcase {
    enum Kind: CaseIterable, Hashable {
        case icon
        case transaction
        case user
        case address
        case asset
        case account
    }

    enum UserState: CaseIterable, Hashable {
        case initial
        case fallback

        var user: Avatar.User {
            switch self {
            case .initial: .initial("M", fill: Fill.palatinateBlue.color)
            case .fallback: .fallback
            }
        }
    }

    enum Asset: CaseIterable, Hashable {
        case flag
        case identicon

        @MainActor
        var image: Image {
            switch self {
            case .flag: AvatarShowcase.flag
            case .identicon: AvatarShowcase.identicon
            }
        }
    }

    enum Fill: CaseIterable, Hashable {
        case palatinateBlue
        case azureBlue
        case caribbeanBlue
        case dullLavender
        case candyGrapeFizz
        case fuchsiaNebula
        case mexicanPink
        case sweetDesire
        case pelati
        case pattypan
        case ufoGreen
        case vitalGreen

        var color: Color {
            switch self {
            case .palatinateBlue: Colors.Accounts.palatinateBlue
            case .azureBlue: Colors.Accounts.azureBlue
            case .caribbeanBlue: Colors.Accounts.caribbeanBlue
            case .dullLavender: Colors.Accounts.dullLavender
            case .candyGrapeFizz: Colors.Accounts.candyGrapeFizz
            case .fuchsiaNebula: Colors.Accounts.fuchsiaNebula
            case .mexicanPink: Colors.Accounts.mexicanPink
            case .sweetDesire: Colors.Accounts.sweetDesire
            case .pelati: Colors.Accounts.pelati
            case .pattypan: Colors.Accounts.pattypan
            case .ufoGreen: Colors.Accounts.ufoGreen
            case .vitalGreen: Colors.Accounts.vitalGreen
            }
        }
    }
}
#endif
