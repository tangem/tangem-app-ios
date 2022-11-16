//
//  ProgressViewCompat.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ProgressViewCompat: View {
    let color: Color

    var body: some View {
        if #available(iOS 14.0, *) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: color))
        } else {
            ActivityIndicatorView(color: color.uiColor())
        }
    }
}

struct ProgressViewCompat_Previews: PreviewProvider {
    static var previews: some View {
        ProgressViewCompat(color: Colors.Icon.informative)
    }
}
