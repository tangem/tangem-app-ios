//
//  CurrencySelectView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

struct CurrencySelectView: View {
    @ObservedObject var viewModel: CurrencySelectViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            if viewModel.loading {
            ActivityIndicatorView(isAnimating: true, style: .medium, color: .tangemTapGrayDark)
            } else {
                List (viewModel.currencies) { currency in
                    HStack {
                        Text("\(currency.name) (\(currency.symbol)) - \(currency.sign)")
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .foregroundColor(.tangemTapGrayDark6)
                        Spacer()
                        if self.viewModel.ratesService.selectedCurrencyCode == currency.symbol {
                            Image("checkmark.circle")
                                .font(.system(size: 18, weight: .regular, design: .default))
                                .foregroundColor(Color.tangemTapGreen)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.viewModel.objectWillChange.send()
                        self.viewModel.ratesService.selectedCurrencyCode = currency.symbol
                       // self.selected = currency.symbol
                    }
                }
                .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))
            }
        }
		.navigationBarTitle("", displayMode: .inline)
        .onAppear {
            self.viewModel.onAppear()
        }
        .alert(item: $viewModel.error) { $0.alert }
    }
}
