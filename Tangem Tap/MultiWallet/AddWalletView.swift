//
//  AddWalletView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct AddWalletView: View {
    var action: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            Button(action: {
                action()
            }, label: {
                Text("+ \("wallet_add_tokens".localized)")
                    .frame(width: geo.size.width, height: 56)
            })
            .foregroundColor(.black)
            .frame(width: geo.size.width, height: 56)
        }
        .frame(height: 56)
        .background(Color.white)
        .cornerRadius(6)
    }
}

struct AddWalletView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.tangemTapGrayLight5
            AddWalletView(action: {})
                .padding()
        }
    }
}
