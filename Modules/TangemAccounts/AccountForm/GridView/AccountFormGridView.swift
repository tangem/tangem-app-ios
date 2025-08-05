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

struct AccountFormGridView<Item: Identifiable & Equatable, Content: View>: View {
    @Binding var selectedItem: Item

    let items: [Item]
    let content: (Item, Bool) -> Content

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: interitemPadding),
        count: 6
    )

    var body: some View {
        LazyVGrid(columns: columns, spacing: Self.interitemPadding) {
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
            with: Colors.Background.action,
            verticalPadding: 16,
            horizontalPadding: 20,
            radius: 14
        )
    }

    private static var interitemPadding: CGFloat {
        switch IPhoneModel() {
        case .iPhoneSE:
            8
        default:
            16
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    @Previewable @State var selectedColor = GridItemColor(Colors.Accounts.brightBlue)
    @Previewable @State var selectedImage = GridItemImage(.image(Assets.Accounts.airplane))

    let colors = [
        Colors.Accounts.brightBlue,
        Colors.Accounts.coralRed,
        Colors.Accounts.cyan,
        Colors.Accounts.darkGreen,
        Colors.Accounts.deepPurple,
        Colors.Accounts.hotPink,
        Colors.Accounts.lavender,
        Colors.Accounts.magenta,
        Colors.Accounts.mediumGreen,
        Colors.Accounts.purple,
        Colors.Accounts.royalBlue,
        Colors.Accounts.yellow,
    ].map(GridItemColor.init)

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
        Assets.Accounts.star,
        Assets.Accounts.startUp,
        Assets.Accounts.user,
        Assets.Accounts.wallet,
    ].map {
        let kind: GridItemImageKind = $0 == Assets.Accounts.letter ? .letter($0) : .image($0)
        return GridItemImage(kind)
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

                    return  Circle()
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
        .frame(width: 384)
        .padding(.horizontal, 16)
    }
}
#endif
