//
//  CurrencySelectView.swift
//  Tangem
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
    
    @State private var searchText: String = ""
    
    var body: some View {
        VStack {
            if viewModel.loading {
                ActivityIndicatorView(isAnimating: true, style: .medium, color: .tangemGrayDark)
            } else {
                VStack {
                    SearchBar(text: $searchText, placeholder: "common_search".localized)
                    List {
                        ForEach(
                            viewModel.currencies.filter {
                                searchText.isEmpty ||
                                    $0.description.localizedStandardContains(searchText)
                            }) { currency in
                            HStack {
                                Text(currency.description)
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .foregroundColor(.tangemGrayDark6)
                                Spacer()
                                if self.viewModel.ratesService.selectedCurrencyCode == currency.code {
                                    Image(systemName: "checkmark.circle")
                                        .font(.system(size: 18, weight: .regular, design: .default))
                                        .foregroundColor(Color.tangemGreen)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                self.viewModel.objectWillChange.send()
                                self.viewModel.ratesService.selectedCurrencyCode = currency.code
                            }
                        }
                    }
                    
                }
                .background(Color.tangemBgGray.edgesIgnoringSafeArea(.all))
            }
        }
        .navigationBarTitle("details_row_title_currency", displayMode: .inline)
        .onAppear {
            self.viewModel.onAppear()
        }
        .alert(item: $viewModel.error) { $0.alert }
    }
}
