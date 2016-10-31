//
// IGIAPManager.swift
// Aloha
//
// Created by IvanGao on 10/24/16.
// Copyright © 2016 IvanGao. All rights reserved.
//

import Foundation
import StoreKit

public protocol IGIAPManagerDelegate: NSObjectProtocol {
    
    func iapProductionListRequestSuccess()
    func iapProductionListRequestFailed()
    func iapProductionPurchaseSuccess(receiptString: String)
    func iapProductionPurchaseFailed(productIdentifier: String, error: NSError?)
}

public class IGIAPManager: NSObject {
    public static let sharedInstance = IGIAPManager()
    public weak var delegate: IGIAPManagerDelegate?
    private(set) var productList: [SKProduct] = []
    
    public static func addIAPTransactionObserver() {
        SKPaymentQueue.default().add(sharedInstance)
    }
    
    public static func removeIAPTransactionObserver() {
        SKPaymentQueue.default().remove(sharedInstance)
    }
    
    public static func purchaseProductWithIapId(iapId: String) {
        let product = sharedInstance.productList.filter { $0.productIdentifier == productIdentifier }.map {
            SKPaymentQueue.defaultQueue().addPayment(SKMutablePayment(product: $0))
        }
    }
    
    public static func closeSuccessTransaction(transactionIdentifier: String) {
        SKPaymentQueue.defaultQueue().transactions.filter { $0.transactionIdentifier == transactionIdentifier }.map {
            SKPaymentQueue.defaultQueue().finishTransaction($0)
        }
    }
    
    public static func closeFailedTransaction(productIdentifier: String) {
        SKPaymentQueue.defaultQueue().transactions.filter { $0.payment.productIdentifier == productIdentifier && $0.transactionState == .Failed }.map {
            SKPaymentQueue.defaultQueue().finishTransaction($0)
        }
    }
}

extension IGIAPManager: SKPaymentTransactionObserver {
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach { paymentTransaction in
            switch paymentTransaction.transactionState {
            case .failed:
                self.delegate?.iapProductionPurchaseFailed(productIdentifier: paymentTransaction.payment.productIdentifier, error: paymentTransaction.error as NSError?)
            case .purchased, .restored:
                if let url = Bundle.main.appStoreReceiptURL,
                    let data = NSData(contentsOf: url) {
                    let receiptString = data.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                    self.delegate?.iapProductionPurchaseSuccess(receiptString)
                }
            case .purchasing, .deferred:
                break
            }
        }
    }
}

extension IGIAPManager: SKProductsRequestDelegate {
    
    public static func productRequest(iapIds: [String]) {
        let request = SKProductsRequest(productIdentifiers: Set(iapIds))
        request.delegate = sharedInstance
        request.start()
    }
    
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        response.products.count > 0 ? self.delegate?.iapProductionListRequestSuccess() : self.delegate?.iapProductionListRequestFailed()
        self.productList = response.products
    }
}
