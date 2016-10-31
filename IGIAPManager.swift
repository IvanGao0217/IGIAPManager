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
    func iapProductionPurchaseSuccess(paymentTransactionId: String, receiptString: String)
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
        let products = sharedInstance.productList.filter { $0.productIdentifier == iapId }
        guard let product = products.first else { return }
        let payment = SKMutablePayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    public static func closeSuccessTransaction(transactionIdentifier: String) {
        SKPaymentQueue.default().transactions.forEach { paymentTransaction in
            guard paymentTransaction.transactionIdentifier == transactionIdentifier else { return }
            SKPaymentQueue.default().finishTransaction(paymentTransaction)
        }
    }
    
    public static func closeFailedTransaction(productIdentifier: String) {
        SKPaymentQueue.default().transactions.forEach { paymentTransaction in
            guard paymentTransaction.payment.productIdentifier == productIdentifier else { return }
            SKPaymentQueue.default().finishTransaction(paymentTransaction)
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
                    self.delegate?.iapProductionPurchaseSuccess(paymentTransactionId: paymentTransaction.transactionIdentifier!, receiptString: receiptString)
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
        guard response.products.count > 0 else {
            self.delegate?.iapProductionListRequestFailed()
            return
        }
        self.delegate?.iapProductionListRequestSuccess()
    }
}
