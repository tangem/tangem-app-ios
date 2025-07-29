//
//  AccountFormGridView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

struct AccountFormGridView<Item: SelectableGridItem, Content: View>: View {
    @Binding
    var selectedItem: Item
    let items: [Item]
    let content: (Item, Bool) -> Content

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 18) {
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
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    @Previewable @State var selectedColor = GridItemColor(Colors.Accounts.brightBlue)
    @Previewable @State var selectedImage = GridItemImage(Assets.Accounts.airplane)

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
        Assets.Accounts.airplane,
        Assets.Accounts.beach,
        Assets.Accounts.bookmark,
        Assets.Accounts.clock,
        Assets.Accounts.family,
        Assets.Accounts.favorite,
        Assets.Accounts.gift,
        Assets.Accounts.home,
        Assets.Accounts.letter,
        Assets.Accounts.money,
        Assets.Accounts.package,
        Assets.Accounts.safe,
        Assets.Accounts.shirt,
        Assets.Accounts.shoppingBasket,
        Assets.Accounts.star,
        Assets.Accounts.startUp,
        Assets.Accounts.user,
        Assets.Accounts.wallet,
    ].map(GridItemImage.init)

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
                        .frame(width: 40, height: 40)
                }
            )

            AccountFormGridView(
                selectedItem: $selectedImage,
                items: images,
                content: { imageItem, isSelected in
                    imageItem.imageType.image
                        .renderingMode(.template)
                        .foregroundStyle(isSelected ? Colors.Text.secondary : Colors.Text.tertiary)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Colors.Field.focused)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white, lineWidth: isSelected ? 4 : 0)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Colors.Text.secondary, lineWidth: isSelected ? 2 : 0)
                                )
                        )
                        .frame(width: 40, height: 40)
                }
            )
        }
        .padding(.horizontal, 16)
    }
}
#endif
