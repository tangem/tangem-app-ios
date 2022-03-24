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
        NetworkIcon(imageName: model.selectedPublisher ? model.imageNameSelected : model.imageName,
                    isMainIndicatorVisible: model.isMain)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            icon
                .padding(.trailing, 4)
            
            HStack(alignment: .top, spacing: 2) {
                Text(model.networkName.uppercased())
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .foregroundColor(model.networkNameForegroundColor)
                    .lineLimit(2)
                
                model.contractName.map {
                    Text($0)
                        .font(.system(size: 14))
                        .foregroundColor(model.contractNameForegroundColor)
                        .padding(.leading, 2)
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            
            Spacer()
            
            if !model.isReadOnly {
                Toggle("", isOn: $model.selectedPublisher)
                    .labelsHidden()
                    .disabled(model.isDisabled)
                    .toggleStyleCompat(.tangemGreen2)
                    .offset(x: 2)
                    .scaleEffect(0.8)
            }
        }
    }
}

fileprivate struct NetworkIcon: View {
    let imageName: String
    let isMainIndicatorVisible: Bool
    let size: CGSize = .init(width: 20, height: 20)
    let indicatorSize: CGSize = .init(width: 6.5, height: 6.5)
    
    var body: some View {
        Image(imageName)
            .resizable()
            .frame(width: size.width, height: size.height)
            .overlay(indicatorOverlay)
    }
    
    @ViewBuilder
    private var indicatorOverlay: some View {
        if isMainIndicatorVisible {
            MainNetworkIndicator()
                .frame(width: indicatorSize.width, height: indicatorSize.height)
                .offset(x: size.width/2 - indicatorSize.width/2,
                        y: -size.height/2 + indicatorSize.height/2)
        } else {
            EmptyView()
        }
    }
}

fileprivate struct MainNetworkIndicator: View {
    let borderPadding: CGFloat = 1.5
    
    var body: some View {
        Circle()
            .foregroundColor(.tangemGreen2)
            .padding(borderPadding)
            .background(Circle().fill(Color.white))
    }
}

struct CurrencyItemView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StatefulPreviewWrapper(false) {
                CurrencyItemView(model: CurrencyItemViewModel(tokenItem: .blockchain(.ethereum(testnet: false)),
                                                              isReadOnly: false, isDisabled: false,
                                                              isSelected: $0))
            }
            
            StatefulPreviewWrapper(true) {
                CurrencyItemView(model: CurrencyItemViewModel(tokenItem: .token(.init(name: "Tether",
                                                                                      symbol: "USDT",
                                                                                      contractAddress: "",
                                                                                      decimalCount: 8,
                                                                                      customIconUrl: nil,
                                                                                      blockchain: .polygon(testnet: false))),
                                                              isReadOnly: false, isDisabled: false,
                                                              isSelected: $0))
            }
            
            Spacer()
        }
    }
}
