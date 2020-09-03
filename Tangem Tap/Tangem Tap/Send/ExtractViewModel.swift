//
//  ExtractViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import EFQRCode

struct TextHint {
    let isError: Bool
    let message: String
}

class ExtractViewModel: ObservableObject {
    @Published var showQR = false
    @Published var validatedClipboard: String? = nil
    @Published var destination: String = ""
    @Published var amount: String = "0"
    @Published var destinationHint: TextHint? = nil
    @Binding var sdkService: TangemSdkService
    @Binding var cardViewModel: CardViewModel {
        didSet {
            bind()
        }
    }
    
    @Published var isSendEnabled: Bool = false
    
    
    //MARK: ValidatedInput
    private var validatedDestination: String? = nil
    
    
    private var bag = Set<AnyCancellable>()
    
    init(cardViewModel: Binding<CardViewModel>, sdkSerice: Binding<TangemSdkService>) {
        self._sdkService = sdkSerice
        self._cardViewModel = cardViewModel
        bind()
    }
    
    func bind() {
        bag = Set<AnyCancellable>()
        
        cardViewModel.objectWillChange
              .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
        }
        .store(in: &bag)
        
        $destination
            .throttle(for: 0.3, scheduler: RunLoop.main, latest: true)
        .sink{ [weak self] newText in
            print(newText)
            self?.validatedDestination = nil
            self?.destinationHint = nil
            guard !newText.isEmpty else {
                return
            }
              //[REDACTED_TODO_COMMENT]
            self?.destinationHint = TextHint(isError: true, message: "Invalid")
        }
        .store(in: &bag)
    }
    
    func validateClipboard() {
        
    }
    
    func stripBlockchainPrefix(_ string: String) -> String {
        if let qrPrefix = cardViewModel.wallet?.blockchain.qrPrefix {
            return string.remove(qrPrefix)
        } else {
            return string
        }
    }
}
