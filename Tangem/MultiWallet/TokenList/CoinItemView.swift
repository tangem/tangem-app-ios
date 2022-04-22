//
//  CoinItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import BlockchainSdk

struct CoinItemView: View {
    @ObservedObject var model: CoinItemViewModel
    
    var icon: some View {
        NetworkIcon(imageName: model.selectedPublisher ? model.imageNameSelected : model.imageName,
                    isMainIndicatorVisible: model.isMain)
    }
    
    @State private var size: CGSize = .zero
    
    var body: some View {
        HStack(spacing: 6) {
            ArrowView(position: model.position, height: size.height)
            
            HStack(spacing: 0) {
                icon
                    .padding(.trailing, 4)
                
                HStack(alignment: .top, spacing: 2) {
                    Text(model.networkName.uppercased())
                        .font(.system(size: 14, weight: .semibold, design: .default))
                        .foregroundColor(model.networkNameForegroundColor)
                        .lineLimit(2)
                    
                    if let contractName = model.contractName {
                        Text(contractName)
                            .font(.system(size: 14))
                            .foregroundColor(model.contractNameForegroundColor)
                            .padding(.leading, 2)
                            .lineLimit(1)
                            .fixedSize()
                    }
                }
                
                Spacer()
                
                if !model.isReadonly {
                    Toggle("", isOn: $model.selectedPublisher)
                        .labelsHidden()
                        .disabled(model.isDisabled)
                        .toggleStyleCompat(.tangemGreen2)
                        .offset(x: 2)
                        .scaleEffect(0.8)
                }
            }
            .padding(.vertical, 8)
        }
        .contentShape(Rectangle())
        .onTapGesture {  } //fix scroll/longpress conflict
        .onLongPressGesture(perform: model.onCopy)
        .readSize(onChange: { self.size = $0 })
    }
}

struct CurrencyItemView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            CoinItemView(model: CoinItemViewModel(tokenItem: .blockchain(.ethereum(testnet: false)),
                                                          isReadonly: false,
                                                          isDisabled: false,
                                                          isSelected: .constant(false)))
            
            CoinItemView(model: CoinItemViewModel(tokenItem: .blockchain(.ethereum(testnet: false)),
                                                          isReadonly: false,
                                                          isDisabled: false,
                                                          isSelected: .constant(true),
                                                          position: .last))
            
            
            StatefulPreviewWrapper(false) {
                CoinItemView(model: CoinItemViewModel(tokenItem: .blockchain(.ethereum(testnet: false)),
                                                              isReadonly: false,
                                                              isDisabled: false,
                                                              isSelected: $0))
                
            }
            
            Spacer()
        }
    }
}
