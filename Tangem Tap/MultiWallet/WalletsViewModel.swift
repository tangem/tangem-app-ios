////
////  File.swift
////  Tangem Tap
////
////  Created by [REDACTED_AUTHOR]
////  Copyright © 2021 Tangem AG. All rights reserved.
////
//
//import Foundation
//import UIKit
//import Combine
//import SwiftUI
////import TangemSdk
//
//class WalletsViewModel: ViewModel {
//    // MARK: Dependencies -
//    weak var imageLoaderService: ImageLoaderService!
//    weak var assembly: Assembly!
//    weak var navigation: NavigationCoordinator!
//
//    [REDACTED_USERNAME] var isRefreshing = false
//    [REDACTED_USERNAME] var image: UIImage? = nil
//    [REDACTED_USERNAME] var card: CardViewModel? = nil {
//        willSet {
//            print("⚠️ Reset bag")
//            image = nil
//            bag = Set<AnyCancellable>()
//        }
//        didSet {
//            bind()
//        }
//    }
//    
//    private var bag = Set<AnyCancellable>()
//    
//    private func bind() {
//        $card
//            .compactMap { $0 }
//            .flatMap { $0.objectWillChange }
//            .receive(on: RunLoop.main)
//            .sink { [unowned self] in
//                print("‼️ Card model will change")
//                self.objectWillChange.send()
//            }
//            .store(in: &bag)
//        
////        $state
////            .compactMap { $0.cardModel }
////            .flatMap { $0.$state }
////            .compactMap { $0.walletModel }
////            .flatMap { $0.objectWillChange }
////            .receive(on: RunLoop.main)
////            .sink { [unowned self] in
////                print("⚠️ Wallet model will change")
////                self.objectWillChange.send()
////            }
////            .store(in: &bag)
//        
////        $state
////            .compactMap { $0.cardModel }
////            .flatMap { $0.$state }
////            .receive(on: RunLoop.main)
////            .sink { [unowned self] state in
////                print("🌀 Card model state updated")
////                self.fetchWarnings()
////            }
////            .store(in: &bag)
//        
//        $card
//            .compactMap { $0 }
//            .flatMap { $0.$state }
//            .compactMap { $0.walletModel }
//            .flatMap { $0.$state }
//            .map { $0.isLoading }
//            .filter { !$0 }
//            .receive(on: RunLoop.main)
//            .sink {[unowned self] isRefreshing in
//                print("♻️ Wallet model loading state changed")
//                withAnimation {
//                    self.isRefreshing = isRefreshing
//                }
//            }
//            .store(in: &bag)
//        
////        $state
////            .filter { $0.cardModel != nil }
////            .sink {[unowned  self] _ in
////                print("✅ Receive new card model")
////                self.selectedAddressIndex = 0
////                self.isHashesCounted = false
////                self.assembly.reset()
////                if !self.showTwinCardOnboardingIfNeeded() {
////                    self.showUntrustedDisclaimerIfNeeded()
////                }
////            }
////            .store(in: &bag)
//        
//        $card
//            .compactMap { $0?.cardInfo }
//            .tryMap { cardInfo -> (String, Data, ArtworkInfo?) in
//                if let cid = cardInfo.card.cardId,
//                   let key = cardInfo.card.cardPublicKey  {
//                    return (cid, key, cardInfo.artworkInfo)
//                }
//                
//                throw "Some error"
//            }
//            .flatMap {[unowned self] info in
//                return self.imageLoaderService
//                    .loadImage(cid: info.0,
//                               cardPublicKey: info.1,
//                               artworkInfo: info.2)
//            }
//            .receive(on: DispatchQueue.main)
//            .sink(receiveCompletion: { completion in
//                    switch completion {
//                    case .failure(let error):
//                        Analytics.log(error: error)
//                        print(error.localizedDescription)
//                    case .finished:
//                        break
//                    }}){ [unowned self] image in
//                self.image = image
//            }
//            .store(in: &bag)
//        
//        $isRefreshing
//            .removeDuplicates()
//            .filter { $0 }
//            .sink{ [unowned self] _ in
//                if let cardModel = self.card, cardModel.state.canUpdate {
//                    cardModel.update()
//                } else {
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                        withAnimation {
//                            self.isRefreshing = false
//                        }
//                    }
//                }
//                
//            }
//            .store(in: &bag)
//    }
//}
