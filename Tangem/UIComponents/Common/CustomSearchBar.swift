//
//  CustomSearchBar.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct CustomSearchBar: View {
    @Binding var searchText: String

    var placeholder: String
    var textFieldAllowsHitTesting: Bool

    var body: some View {
        HStack {
            Assets.search.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.informative)
                .frame(size: .init(width: 20, height: 20))

            TextField(placeholder, text: $searchText)
                .allowsTightening(textFieldAllowsHitTesting)
                .foregroundColor(Colors.Text.primary1)
                .font(Fonts.Regular.subheadline)
                .overlay(
                    Assets.clear.image
                        .renderingMode(.template)
                        .padding()
                        .offset(x: 10)
                        .foregroundColor(Colors.Icon.informative)
                        .opacity(searchText.isEmpty ? 0.0 : 1.0)
                        .frame(size: .init(width: 24, height: 24))
                        .onTapGesture {
                            searchText = ""
                        },
                    alignment: .trailing
                )
        }
        .frame(height: 20.0)
        .padding(.vertical, 12.0)
        .padding(.horizontal, 12.0)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Colors.Field.primary)
        )
        .padding(.horizontal, 16.0)
    }
}

struct CustomSearchBar_Previews: PreviewProvider {
    static var previews: some View {
        CustomSearchBar(
            searchText: .constant(""),
            placeholder: Localization.commonSearch,
            textFieldAllowsHitTesting: false
        )
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.light)

        CustomSearchBar(
            searchText: .constant(""),
            placeholder: Localization.commonSearch,
            textFieldAllowsHitTesting: false
        )
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
}
