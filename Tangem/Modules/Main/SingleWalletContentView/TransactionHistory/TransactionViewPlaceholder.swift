//
//  TransactionPlaceholderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TransactionViewPlaceholder: View {
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Color.clear
                .skeletonable(
                    isShown: true,
                    size: .init(width: 40, height: 40),
                    radius: 20
                )
            
            VStack(alignment: .leading, spacing: 6.5) {
                Color.clear
                    .skeletonable(
                        isShown: true,
                        size: .init(width: 70, height: 12),
                        radius: 3
                    )
                
                Color.clear
                    .skeletonable(
                        isShown: true,
                        size: .init(width: 52, height: 12),
                        radius: 3
                    )
            }
            
            Spacer()
            
            Color.clear
                .skeletonable(
                    isShown: true,
                    size: .init(width: 40, height: 12),
                    radius: 3
                )
        }
    }
}

struct TransactionViewPlaceholder_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TransactionViewPlaceholder()
            TransactionViewPlaceholder()
            TransactionViewPlaceholder()
        }
        .padding(.horizontal, 8)
    }
}
