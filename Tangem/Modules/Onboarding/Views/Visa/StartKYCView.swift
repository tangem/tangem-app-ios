//
//  StartKYCView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct StartKYCView: View {
    var body: some View {
        VStack {
            Spacer()

            Image(name: "passport")
                .padding(.bottom, 36)
        }
    }
}

struct StartKYCScreen_Previews: PreviewProvider {
    static var previews: some View {
        StartKYCView()
    }
}
