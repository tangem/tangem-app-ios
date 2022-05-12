//
//  TotalSumBalanceView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

struct TotalSumBalanceView: View {
    
    var currencyRateService: CurrencyRateService
    var tokens: [TokenItemViewModel]
    var tapOnCurrencySymbol: () -> ()
    
    var body: some View {
        VStack {
            CounterBalanceView(currencyRateService: currencyRateService, tokens: tokens, tapOnCurrencySymbol: tapOnCurrencySymbol)
        }
        .frame(width: UIScreen.main.bounds.width, height: 120)
        .background(Color.clear)
    }
}

struct CounterBalanceView: View {
    
    var currencyRateService: CurrencyRateService
    var tokens: [TokenItemViewModel]
    
    var tapOnCurrencySymbol: () -> ()
    
    @State var currency: String = ""
    @State var countBalance: String = ""
    @State var bag = Set<AnyCancellable>()
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("main_page_balance".localized)
                    .font(Font.system(size: 14, weight: .medium))
                    .foregroundColor(Color.tangemTextGray)
                    .padding(.leading, 20)
                    .padding(.top, 20)
                
                Spacer()
                
                Button {
                    tapOnCurrencySymbol()
                } label: {
                    HStack(spacing: 0) {
                        Text(currency)
                            .font(Font.system(size: 16, weight: .medium))
                            .foregroundColor(Color.tangemBalanceCurrencyGray)
                            .padding(.trailing, 6)
                        Image("tangemArrowDown")
                            .foregroundColor(Color.tangemTextGray)
                            .padding(.trailing, 20)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 22)
            }
            
            HStack(spacing: 0) {
                Text(countBalance)
                    .font(Font.system(size: 34, weight: .bold))
                    .foregroundColor(Color.tangemGrayDark6)
                    .padding(.leading, 20)
                Spacer()
            }
            .padding(.top, 4)
            
            Spacer()
        }
        .frame(width: UIScreen.main.bounds.width - 32, height: 101)
        .background(Color.white)
        .cornerRadius(16)
        .onAppear {
            currency = currencyRateService.selectedCurrencyCode
            currencyRateService
                .baseCurrencies()
                .receive(on: RunLoop.main)
                .sink { _ in
                    
                } receiveValue: { currencyes in
                    guard let symbol = currencyes.first(where: { $0.code == currencyRateService.selectedCurrencyCode }) else { return }
                    var count: Decimal = 0.0
                    tokens.forEach { token in
                        count += token.fiatValue
                    }
                    countBalance = "\(symbol.unit) \(count)"
                }.store(in: &bag)
        }
    }
    
}

struct TotalSumBalanceView_Previews: PreviewProvider {
    static var previews: some View {
        TotalSumBalanceView(currencyRateService: Assembly(isPreview: true).services.ratesService, tokens: []) { }
    }
}
