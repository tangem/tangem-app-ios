//
//  ExploreButton.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ExploreButton:  View {
    let url: URL?
    var urlBinding: Binding<URL?>

    var body: some View {
        TangemButton(title: "wallet_address_button_explore",
                     systemImage: "chevron.right",
                     iconPosition: .trailing) { urlBinding.wrappedValue = url }
            .buttonStyle(TangemButtonStyle(colorStyle: .transparentWhite,
                                           layout: .flexible,
                                           font: Font.system(size: 14.0, weight: .bold, design: .default),
                                           paddings: 0,
                                           cornerRadius: 0,
                                           isDisabled: url == nil))
    }
}


struct ExploreButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ExploreButton(url: nil, urlBinding: .constant(nil))
        }
        .environment(\.locale, .init(identifier: "fr"))
    }
}
