//
//  TotalSumBalanceView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class TotalSumBalanceViewModel: ObservableObject {
    
    var tokens: Published<[TokenItemViewModel]>.Publisher
    @Published var shimmer: Bool = false
    @Published var currency: String = ""
    @Published var countBalance: String = ""
    
    var bag = Set<AnyCancellable>()
    var currencyRateService: CurrencyRateService
    
    private var tokenItems: [TokenItemViewModel] = []
    
    init(currencyRateService: CurrencyRateService, tokens: Published<[TokenItemViewModel]>.Publisher) {
        self.tokens = tokens
        self.currencyRateService = currencyRateService
        bind()
    }
    
    func bind() {
        tokens.sink { [weak self] newValue in
            guard let tokenItem = self?.tokenItems else { return }
            if newValue == tokenItem && !tokenItem.isEmpty {
                return
            }
            self?.tokenItems = newValue
            self?.refresh()
        }.store(in: &bag)
    }
    
    func refresh() {
        guard !shimmer else { return }
        withAnimation {
            shimmer = true
        }
        currency = currencyRateService.selectedCurrencyCode
        currencyRateService
            .baseCurrencies()
            .receive(on: RunLoop.main)
            .sink { _ in
                
            } receiveValue: { currencyes in
                guard let symbol = currencyes.first(where: { $0.code == self.currencyRateService.selectedCurrencyCode }) else { return }
                var count: Decimal = 0.0
                self.tokenItems.forEach { token in
                    count += token.fiatValue
                }
                self.countBalance = "\(symbol.unit) \(count)"
                self.shimmerOff()
            }.store(in: &bag)
    }
    
    func shimmerOff() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation {
                self.shimmer = false
            }
        }
    }
}

struct TotalSumBalanceView: View {
    
    @ObservedObject var viewModel: TotalSumBalanceViewModel
    
    var tapOnCurrencySymbol: () -> ()
    
    var body: some View {
        VStack {
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
                            Text(viewModel.currency)
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
                    Text(viewModel.shimmer ? "wallet_balance_loading".localized : viewModel.countBalance)
                        .redactedIfPossible(viewModel.shimmer)
                        .if(viewModel.shimmer, transform: { view in
                            view.shimmering()
                        })
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
        }
        .frame(width: UIScreen.main.bounds.width, height: 120)
        .background(Color.clear)
        .onDisappear {
            viewModel.shimmerOff()
        }
    }
}

//struct TotalSumBalanceView_Previews: PreviewProvider {
//    static var previews: some View {
//        TotalSumBalanceView(currencyRateService: Assembly(isPreview: true).services.ratesService, tokens: Binding<[TokenItemViewModel]>.init(get: {[]}, set: {_ in})) { }
//    }
//}
