//
//  CurrencyItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import BlockchainSdk

struct CurrencyItemView: View {
    @ObservedObject var model: CurrencyItemViewModel

    var icon: some View {
        Image(model.selectedPublisher ? model.imageNameSelected : model.imageName)
            .resizable()
            .frame(width: 20, height: 20)
            .padding(.trailing, 5)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            icon
            
            Text(model.networkName.uppercased())
                .font(.system(size: 13, weight: .semibold, design: .default))
                .foregroundColor(networkNameForegroundColor)
                .lineLimit(1)
                .fixedSize()
            
            model.contractName.map {
                Text($0)
                    .font(.system(size: 13))
                    .foregroundColor(.tangemGrayDark)
                    .padding(.leading, 2)
                    .lineLimit(1)
                    .fixedSize()
            }
            
            Spacer(minLength: 0)
            
            if !model.isReadOnly {
                Toggle("", isOn: $model.selectedPublisher)
                    .labelsHidden()
                    .toggleStyleCompat(.tangemGreen)
                    .scaleEffect(0.8)
                    .offset(x: 2)
            }
        }
    }
    
    private var networkNameForegroundColor: Color {
        model.selectedPublisher ? .black : .tangemGrayDark
    }
}

struct CurrencyItemView_Previews: PreviewProvider {
    static var previews: some View {
            StatefulPreviewWrapper(false) {
                CurrencyItemView(model: CurrencyItemViewModel(tokenItem: .blockchain(.ethereum(testnet: false)),
                                                              isReadOnly: false,
                                                              isSelected: $0))
            }
    }
}
