//
//  AvatarSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemSnapshotTestSupport
import TangemUI
import UIKit

enum AvatarSnapshotScenario: String, SnapshotScenario {
    case variants
    case variantsShimmer
    case variantsLargeText
    case assets
    case appearances
    case transactionKinds
    case accounts
    case accountIndicatorRTL

    var layoutDirection: LayoutDirection {
        self == .accountIndicatorRTL ? .rightToLeft : .leftToRight
    }

    var dynamicTypeSize: DynamicTypeSize {
        self == .variantsLargeText ? .accessibility2 : .large
    }

    @MainActor
    @ViewBuilder
    var body: some View {
        switch self {
        case .variants:
            samples(Sample.allCases)
        case .variantsShimmer:
            samples([.icon, .iconRoundedSquare, .accountWithIndicator])
                .environment(\.isShimmerActive, true)
                .environment(\.isShimmerAnimationPaused, true)
        case .variantsLargeText:
            samples([.icon, .transaction, .userInitial, .accountWithIndicator])
        case .assets:
            grid(Avatar.Shape.allCases) { shape, size in
                Avatar(.asset(flag, shape: shape), size: size)
            }
        case .appearances:
            VStack(alignment: .leading, spacing: 16) {
                grid(Avatar.IconAppearance.allCases, columns: Avatar.Shape.allCases) { appearance, shape in
                    Avatar(.icon(glyph(for: .size40), appearance: appearance, shape: shape))
                }

                HStack(spacing: 16) {
                    ForEach(Avatar.TransactionStatus.allCases, id: \.self) { status in
                        Avatar(.transaction(.send, status: status))
                    }
                }
            }
        case .transactionKinds:
            grid(Avatar.TransactionKind.allCases) { kind, size in
                Avatar(.transaction(kind, status: .finished), size: size)
            }
        case .accounts:
            grid(accounts) { account, size in
                Avatar(.account(account), size: size)
            }
        case .accountIndicatorRTL:
            samples([.accountWithIndicator])
        }
    }
}

@MainActor
private extension AvatarSnapshotScenario {
    enum Sample: CaseIterable {
        case icon
        case iconRoundedSquare
        case transaction
        case userInitial
        case userFallback
        case address
        case addressEmpty
        case asset
        case accountWithIndicator
    }

    var sizes: [Avatar.Size] {
        [.size72, .size44, .size40, .size16]
    }

    var fill: Color {
        DesignSystem.Colors.accountPalatinateBlue
    }

    var accountIcon: ImageType {
        DesignSystem.Icons.accountAirplane
    }

    var accounts: [Avatar.Account] {
        [
            .icon(accountIcon, fill: fill),
            .letter("M", fill: fill),
            .prediction,
            .gacha,
            .visa,
            .money,
        ]
    }

    func glyph(for size: Avatar.Size) -> ImageType {
        switch size {
        case .size72: DesignSystem.Icons.Clock.regular28
        case .size44, .size40: DesignSystem.Icons.Clock.regular20
        case .size16: DesignSystem.Icons.Clock.regular12
        }
    }

    func content(_ sample: Sample, size: Avatar.Size) -> Avatar.Content {
        switch sample {
        case .icon: .icon(glyph(for: size))
        case .iconRoundedSquare: .icon(glyph(for: size), shape: .roundedSquare)
        case .transaction: .transaction(.send, status: .progress)
        case .userInitial: .user(.initial("M", fill: fill))
        case .userFallback: .user(.fallback)
        case .address: .address(identicon)
        case .addressEmpty: .address(nil)
        case .asset: .asset(flag)
        case .accountWithIndicator: .account(.icon(accountIcon, fill: fill), hasIndicator: true)
        }
    }

    func samples(_ samples: [Sample]) -> some View {
        grid(samples) { sample, size in
            Avatar(content(sample, size: size), size: size)
        }
    }

    func grid<Row, Cell: View>(
        _ rows: [Row],
        @ViewBuilder cell: @escaping (Row, Avatar.Size) -> Cell
    ) -> some View {
        grid(rows, columns: sizes, cell: cell)
    }

    func grid<Row, Column, Cell: View>(
        _ rows: [Row],
        columns: [Column],
        @ViewBuilder cell: @escaping (Row, Column) -> Cell
    ) -> some View {
        let cells = rows.flatMap { row in
            columns.map { (row: row, column: $0) }
        }

        return SnapshotGrid(cells, columns: columns.count) { item in
            cell(item.row, item.column)
        }
    }

    var flag: Image {
        pixelImage(
            rows: [
                [0, 1, 2],
                [0, 1, 2],
                [0, 1, 2],
            ],
            palette: [
                UIColor(red: 0.0, green: 0.2, blue: 0.62, alpha: 1),
                UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1),
                UIColor(red: 0.82, green: 0.06, blue: 0.2, alpha: 1),
            ]
        )
    }

    var identicon: Image {
        pixelImage(
            rows: [
                [0, 1, 1, 0],
                [1, 2, 2, 1],
                [2, 0, 0, 2],
                [1, 2, 2, 1],
            ],
            palette: [
                UIColor(red: 0.93, green: 0.42, blue: 0.13, alpha: 1),
                UIColor(red: 0.55, green: 0.33, blue: 0.75, alpha: 1),
                UIColor(red: 0.42, green: 0.62, blue: 0.27, alpha: 1),
            ]
        )
    }

    func pixelImage(rows: [[Int]], palette: [UIColor]) -> Image {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        let size = CGSize(width: rows[0].count, height: rows.count)
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            for (y, row) in rows.enumerated() {
                for (x, colorIndex) in row.enumerated() {
                    palette[colorIndex].setFill()
                    context.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }

        return Image(uiImage: image).interpolation(.none)
    }
}
