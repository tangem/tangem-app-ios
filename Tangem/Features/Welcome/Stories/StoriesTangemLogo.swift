//
//  StoriesTangemLogo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct StoriesTangemLogo: View {
    var body: some View {
        HStack {
            Assets.tangemLogo.image
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 19)
            Spacer()
        }
        .padding(.top)
    }
}

#Preview {
    StoriesTangemLogo()
}
