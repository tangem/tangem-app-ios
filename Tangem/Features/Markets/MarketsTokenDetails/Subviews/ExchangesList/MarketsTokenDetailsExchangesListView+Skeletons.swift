//
//  MarketsTokenDetailsExchangesListView+Skeletons.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

extension MarketsTokenDetailsExchangesListView {
    struct ExchangeLoaderView: View {
        var body: some View {
            HStack(spacing: 12) {
                Shimmer()
                    .variant(.custom(width: 36, height: 36))

                VStack(spacing: 8) {
                    HStack {
                        Shimmer()
                            .variant(.custom(width: 70, height: 12, cornerRadius: 3))

                        Spacer()

                        Shimmer()
                            .variant(.custom(width: 40, height: 12, cornerRadius: 3))
                    }

                    HStack {
                        Shimmer()
                            .variant(.custom(width: 52, height: 12, cornerRadius: 3))

                        Spacer()

                        Shimmer()
                            .variant(.custom(width: 40, height: 12, cornerRadius: 3))
                    }
                }
            }
            .padding(14)
        }
    }
}
