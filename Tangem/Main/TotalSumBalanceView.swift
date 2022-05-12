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
            TotalBalanceHeaderView(currencyRateService: currencyRateService, tapOnCurrencySymbol: tapOnCurrencySymbol)
                .padding(.bottom, 8)

            CounterBalanceView(currencyRateService: currencyRateService, tokens: tokens)
        }
        .frame(width: UIScreen.main.bounds.width, height: 140)
        .background(Color.clear)
    }
}

struct CounterBalanceView: View {
    
    var currencyRateService: CurrencyRateService
    var tokens: [TokenItemViewModel]
    
    @State var countBalance: String = ""
    @State var bag = Set<AnyCancellable>()
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(countBalance)
                    .font(Font.system(size: 34, weight: .bold))
                    .foregroundColor(Color.tangemGrayDark6)
                    .padding(.leading, 20)
                Spacer()
            }
            .padding(.top, 14)
            
            HStack(spacing: 0) {
                Text("+1390.21 $ (3,2%)")
                    .foregroundColor(Color.tangemGreen)
                    .font(Font.system(size: 16, weight: .medium))
                    .padding(.leading, 20)
                    .padding(.top, 6)
                Spacer()
            }
            
            Spacer()
        }
        .frame(width: UIScreen.main.bounds.width - 32, height: 97)
        .background(Color.white)
        .cornerRadius(16)
        .onAppear {
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

struct TotalBalanceHeaderView: View {
    
    var currencyRateService: CurrencyRateService
    var tapOnCurrencySymbol: () -> ()
    
    @State var currency: String = ""
    
    var body: some View {
        HStack(spacing: 0) {
            Text("main_page_balance".localized)
                .font(Font.system(size: 24, weight: .bold))
                .foregroundColor(Color.tangemGrayDark6)
                .padding(.leading, 16)
            
            Spacer()
            
            Button {
                tapOnCurrencySymbol()
            } label: {
                HStack(spacing: 0) {
                    Image("tangemArrowDown")
                        .padding(.trailing, 10)
                    Text(currency)
                        .font(Font.system(size: 15, weight: .medium))
                        .foregroundColor(Color.tangemGreen)
                        .padding(.trailing, 16)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .onAppear {
            currency = currencyRateService.selectedCurrencyCode
        }
    }
    
}

struct TotalSumBalanceView_Previews: PreviewProvider {
    static var previews: some View {
        TotalSumBalanceView(currencyRateService: Assembly(isPreview: true).services.ratesService, tokens: []) { }
    }
}
