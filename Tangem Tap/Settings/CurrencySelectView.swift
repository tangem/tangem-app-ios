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
    @EnvironmentObject var cardViewModel: CardViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var loading: Bool = false
    @State private var currencies: [FiatCurrency] = []
    @State private var error: AlertBinder?
    @State private var bag = Set<AnyCancellable>()
   // [REDACTED_USERNAME] private var selected: String = ""
    var body: some View {
        VStack {
            if loading {
                ActivityIndicatorView(isAnimating: true, style: .medium)
            } else {
                List (currencies) { currency in
                    HStack {
                        Text("\(currency.name) (\(currency.symbol)) - \(currency.sign)")
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .foregroundColor(.tangemTapGrayDark6)
                        Spacer()
                        if self.cardViewModel.selectedCurrency == currency.symbol {
                            Image("checkmark.circle")
                                .font(.system(size: 18, weight: .regular, design: .default))
                                .foregroundColor(Color.tangemTapGreen)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.cardViewModel.selectedCurrency = currency.symbol
                       // self.selected = currency.symbol
                    }
                }
                .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))
            }
        }
        .onAppear {
            self.loading = true
            self.cardViewModel
                .ratesService?
                .loadFiatMap()
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        self.error = error.alertBinder
                    }
                    self.loading = false
                }, receiveValue: { currencies in
                    self.currencies = currencies
                })
                .store(in: &self.bag)
        }
        .alert(item: $error) { $0.alert }
    }
}
