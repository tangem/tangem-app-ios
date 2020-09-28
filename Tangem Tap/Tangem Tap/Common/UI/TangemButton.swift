//
//  TangemButton.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct TangemButton: View {
    let isLoading: Bool    
    let title: LocalizedStringKey
    let image: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            self.action()
        }, label:  {
            if isLoading {
                ActivityIndicatorView()
            } else {
                HStack(alignment: .center) {
                    Text(title)
                    Spacer()
                    Image(image)
                }
                .padding(.horizontal)
            }
        })
    }
}
