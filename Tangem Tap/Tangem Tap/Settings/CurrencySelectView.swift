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
    
    @State private var loading: Bool = false
    @State private var currencies: [FiatCurrency] = []
    
    @State private var showError: Bool = false
    @State private var error: Error? = nil
    
    @State private var bag: AnyCancellable? = nil
    
    var body: some View {
        VStack {
            if loading {
                ActivityIndicatorView(isAnimating: true, style: .medium)
            } else {
                if currencies.isEmpty {
                    EmptyView()
                } else {
                        List (currencies, id: \.id) { currency in
                            Text("\(currency.name) (\(currency.symbol)) - \(currency.sign)")
                        }
                }
            }
        }.onAppear {
            self.bag = self.cardViewModel
                .ratesService?
                .loadFiatMap()
               // .receive(on: RunLoop.main)
                .sink(receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        self.error = error
                        self.showError = true
                    }
                    self.loading = false
                }, receiveValue: { currencies in
                    self.currencies = currencies
                })
        }.alert(isPresented: $showError) { () -> Alert in
            return Alert(title: Text("common_error"),
                         message: Text(self.error!.localizedDescription),
                         dismissButton: Alert.Button.default(Text("common_ok"),
                                                             action: { }))
            
        }
    }
}
