//
//  StoreManager.swift
//  ShaderMania
//
//  Created by Markus Moenig on 17/2/21.
//

import Foundation
import StoreKit

#if os(macOS)

@MainActor
class StoreManager: ObservableObject {

    enum PurchaseState {
        case purchasing
        case purchased
        case failed
    }

    let productIDs = [
        "com.moenig.ShaderMania.IAP.Tip2",
        "com.moenig.ShaderMania.IAP.Tip5",
        "com.moenig.ShaderMania.IAP.Tip10"
    ]

    @Published var myProducts       = [Product]()
    @Published var transactionState : PurchaseState?

    func getProducts() {
        Task {
            do {
                myProducts = try await Product.products(for: productIDs)
            } catch {
                print("Product request failed: \(error.localizedDescription)")
            }
        }
    }

    func purchaseId(_ id: String)
    {
        guard let product = myProducts.first(where: { $0.id == id }) else {
            return
        }

        Task {
            transactionState = .purchasing
            do {
                let result = try await product.purchase()
                switch result {
                case .success(let verification):
                    if case .verified(let transaction) = verification {
                        UserDefaults.standard.setValue(true, forKey: product.id)
                        await transaction.finish()
                        transactionState = .purchased
                    } else {
                        transactionState = .failed
                    }
                case .userCancelled, .pending:
                    transactionState = nil
                @unknown default:
                    transactionState = .failed
                }
            } catch {
                print("Payment Error: \(error.localizedDescription)")
                transactionState = .failed
            }
        }
    }
}

#else

class StoreManager: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    let productIDs = [
        "com.moenig.ShaderMania.IAP.Tip2",
        "com.moenig.ShaderMania.IAP.Tip5",
        "com.moenig.ShaderMania.IAP.Tip10"
    ]
    
    @Published var myProducts       = [SKProduct]()
    @Published var transactionState : SKPaymentTransactionState?

    var request                     : SKProductsRequest!
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if !response.products.isEmpty {
            for fetchedProduct in response.products {
                DispatchQueue.main.async {
                    print(fetchedProduct.productIdentifier)
                    self.myProducts.append(fetchedProduct)
                }
            }
        }
        
        for invalidIdentifier in response.invalidProductIdentifiers {
            print("Invalid identifiers found: \(invalidIdentifier)")
        }
    }
    
    func getProducts() {
        
        SKPaymentQueue.default().add(self)

        let request = SKProductsRequest(productIdentifiers: Set(productIDs))
        request.delegate = self
        request.start()
    }
    
    func purchaseProduct(product: SKProduct) {
        if SKPaymentQueue.canMakePayments() {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        } else {
            print("User can't make payment.")
        }
    }
    
    func purchaseId(_ id: String)
    {
        for p in myProducts {
            if p.productIdentifier == id {
                purchaseProduct(product: p)
            }
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                transactionState = .purchasing
            case .purchased:
                UserDefaults.standard.setValue(true, forKey: transaction.payment.productIdentifier)
                queue.finishTransaction(transaction)
                transactionState = .purchased
            case .restored:
                UserDefaults.standard.setValue(true, forKey: transaction.payment.productIdentifier)
                queue.finishTransaction(transaction)
                transactionState = .restored
            case .failed, .deferred:
                print("Payment Queue Error: \(String(describing: transaction.error))")
                queue.finishTransaction(transaction)
                transactionState = .failed
                default:
                queue.finishTransaction(transaction)
            }
        }
    }
}

#endif
