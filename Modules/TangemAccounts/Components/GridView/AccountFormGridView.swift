//
//  AccountFormGridView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import TangemFoundation

public struct AccountFormGridView<Item: Identifiable & Equatable, Content: View>: View {
    @Binding var selectedItem: Item

    private let items: [Item]
    private let content: (Item, Bool) -> Content

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 16),
        count: 6
    )

    public init(
        selectedItem: Binding<Item>,
        items: [Item],
        content: @escaping (Item, Bool) -> Content
    ) {
        _selectedItem = selectedItem
        self.items = items
        self.content = content
    }

    public var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(items) { item in
                let isSelected = item == selectedItem
                content(item, isSelected)
                    .onTapGesture {
                        selectedItem = item
                    }
                    .animation(.linear(duration: 0.1), value: selectedItem)
            }
        }
        .roundedBackground(
            with: AccountFormGridViewConstants.backgroundColor,
            verticalPadding: 16,
            horizontalPadding: 20,
            radius: 14
        )
    }
}

public enum AccountFormGridViewConstants {
    public static let backgroundColor: Color = Colors.Background.action
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    @Previewable @State var selectedColor = GridItemColor(
        id: Colors.Accounts.caribbeanBlue.description,
        color: Colors.Accounts.caribbeanBlue
    )
    @Previewable @State var selectedImage = GridItemImage(
        id: Assets.Accounts.airplane.hashValue,
        kind: .image(Assets.Accounts.airplane)
    )

    let colors = [
        Colors.Accounts.azureBlue,
        Colors.Accounts.candyGrapeFizz,
        Colors.Accounts.caribbeanBlue,
        Colors.Accounts.dullLavender,
        Colors.Accounts.fuchsiaNebula,
        Colors.Accounts.mexicanPink,
        Colors.Accounts.palatinateBlue,
        Colors.Accounts.pattypan,
        Colors.Accounts.pelati,
        Colors.Accounts.sweetDesire,
        Colors.Accounts.ufoGreen,
        Colors.Accounts.vitalGreen,
    ].map { GridItemColor(id: $0.description, color: $0) }

    let images = [
        Assets.Accounts.letter,
        Assets.Accounts.airplane,
        Assets.Accounts.beach,
        Assets.Accounts.bookmark,
        Assets.Accounts.clock,
        Assets.Accounts.family,
        Assets.Accounts.favorite,
        Assets.Accounts.gift,
        Assets.Accounts.home,
        Assets.Accounts.money,
        Assets.Accounts.package,
        Assets.Accounts.safe,
        Assets.Accounts.shirt,
        Assets.Accounts.shoppingBasket,
        Assets.Accounts.starAccounts,
        Assets.Accounts.startUp,
        Assets.Accounts.user,
        Assets.Accounts.walletAccounts,
    ].map {
        let kind: GridItemImageKind = $0 == Assets.Accounts.letter
            ? .letter(visualImageRepresentation: $0)
            : .image($0)
        return GridItemImage(id: $0.hashValue, kind: kind)
    }

    ZStack {
        Color.gray
        VStack {
            AccountFormGridView(
                selectedItem: $selectedColor,
                items: colors,
                content: { colorItem, isSelected in
                    Circle()
                        .fill(colorItem.color)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white, lineWidth: isSelected ? 4 : 0)
                                .overlay(
                                    Circle()
                                        .strokeBorder(colorItem.color, lineWidth: isSelected ? 2 : 0)
                                )
                        )
                }
            )

            AccountFormGridView(
                selectedItem: $selectedImage,
                items: images,
                content: { imageItem, isSelected in
                    let imageSelectedColor = switch imageItem.kind {
                    case .image: Colors.Text.secondary
                    case .letter: Colors.Text.accent
                    }

                    let imageNotSelectedColor = switch imageItem.kind {
                    case .image: Colors.Text.tertiary
                    case .letter: Colors.Text.accent
                    }

                    let backgroundColor = switch imageItem.kind {
                    case .image: Colors.Field.focused
                    case .letter: Colors.Text.accent.opacity(0.1)
                    }

                    let strokeColor = switch imageItem.kind {
                    case .image: Colors.Text.secondary
                    case .letter: Colors.Icon.accent
                    }

                    return Circle()
                        .fill(backgroundColor)
                        .overlay(
                            imageItem.kind.imageType.image
                                .renderingMode(.template)
                                .resizable()
                                .padding(8)
                                .foregroundStyle(isSelected ? imageSelectedColor : imageNotSelectedColor)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white, lineWidth: isSelected ? 4 : 0)
                                .overlay(
                                    Circle()
                                        .strokeBorder(strokeColor, lineWidth: isSelected ? 2 : 0)
                                )
                        )
                }
            )
        }
        .padding(.horizontal, 16)
    }
}
#endif
