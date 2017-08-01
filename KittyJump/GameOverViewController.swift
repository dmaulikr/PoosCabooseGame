//
//  GameOverViewController.swift
//  KittyJump
//
//  Created by Olivia Brown on 6/24/17.
//  Copyright © 2017 Olivia Brown. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
import GoogleMobileAds
import StoreKit

var removedAds: Bool = SharingManager.sharedInstance.didRemoveAds

class GameOverViewController: UIViewController, GADInterstitialDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    var interstitial: GADInterstitial!
    
    // Variables for changing label text
    var lastNineScores = SharingManager.sharedInstance.lastScores
    let highScore = SharingManager.sharedInstance.highScore
    
    @IBOutlet weak var highScoreLabel: UILabel!
    @IBOutlet weak var mostRecentScore: UILabel!
    @IBOutlet weak var pastScores: UILabel!
    
    // Start over image
    @IBOutlet weak var startOver: UIImageView?
    
    @IBOutlet weak var preferencesView: UIView!
    @IBOutlet weak var preferencesTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var removeAdsButton: UIButton!
    @IBOutlet weak var restorePurchasesButton: UIButton!
    @IBOutlet weak var darkenedView: UIView!
    @IBAction func removeAdButtonTapped(_ sender: Any) {
        for product in list {
            let prodID = product.productIdentifier
            if prodID == "org.pooscaboose.noads" {
                p = product
                buyProduct()
            }
        }
    }
    @IBAction func restoreButtonTapped(_ sender: Any) {
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
        restorePurchasesButton.isEnabled = false
        restorePurchasesButton.alpha = 0.5
    }
    
    func buyProduct() {
        let pay = SKPayment(product: p)
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().add(pay as SKPayment)
        
    }
    @IBAction func cancelPreferences(_ sender: Any) {
        hidePreferencesView()
    }

    @IBAction func preferencesButtonTapped(_ sender: Any) {
        showPreferencesView()
    }
    var showFirst: Bool = true
    
    var list = [SKProduct]()
    var p = SKProduct()
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let myProduct = response.products
        for product in myProduct {
            list.append(product)
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        for transaction in queue.transactions {
            let t: SKPaymentTransaction = transaction
            let prodID = t.payment.productIdentifier as String
            restorePurchasesButton.alpha = 0.5
            restorePurchasesButton.isEnabled = false
            
            switch prodID {
            case "org.pooscaboose.noads":
                removedAds = true
                SharingManager.sharedInstance.didRemoveAds = true
                removeAdsButton.alpha = 0.5
                removeAdsButton.isEnabled = false
            default:
                print("iap not found")
            }
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction: AnyObject in transactions {
            let trans = transaction as! SKPaymentTransaction
            
            switch trans.transactionState {
            case .purchased:
                
                let prodID = p.productIdentifier
                switch prodID {
                case "org.pooscaboose.noads":
                    removedAds = true
                    SharingManager.sharedInstance.didRemoveAds = true
                    removeAdsButton.isEnabled = false
                    removeAdsButton.alpha = 0.5
                default:
                    print("iap not found")
                }
                queue.finishTransaction(trans)
            case .failed:
                queue.finishTransaction(trans)
                break
            default:
                break
            }
        }
    }
    
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        if showFirst == true && playCount % 3 == 0 && removedAds == false {
            interstitial.present(fromRootViewController: self)
            showFirst = false
        }
    }
    
    func hidePreferencesView() {
        darkenedView.isHidden = true
        UIView.animate(withDuration: 0.5, animations: {
            self.preferencesTopConstraint.constant += self.view.bounds.height
            self.view.layoutIfNeeded()
        }, completion: { (finished: Bool) in
            if finished {
                self.preferencesView.isHidden = true
                self.preferencesTopConstraint.constant -= self.view.bounds.height
            }
        })
    }
    
    func showPreferencesView() {
        preferencesView.layer.cornerRadius = 20
        removeAdsButton.layer.cornerRadius = 22
        restorePurchasesButton.layer.cornerRadius = 22
        darkenedView.isHidden = false
        
        if removedAds == true {
            removeAdsButton.isEnabled = false
            removeAdsButton.alpha = 0.5
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(hidePreferencesView))
        darkenedView.addGestureRecognizer(tap)
        
        preferencesTopConstraint.constant += self.view.bounds.height
        view.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.5, animations: {
            self.preferencesView.isHidden = false
            self.preferencesTopConstraint.constant -= self.view.bounds.height
            self.view.layoutIfNeeded()
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        interstitial = createAndLoadInterstitial()
        
        if playCount % 3 != 0{
            if #available(iOS 10.3, *) {
                SKStoreReviewController.requestReview()
            }
        }
        
        if(SKPaymentQueue.canMakePayments()) {
            let productID: NSSet = NSSet(object: "org.pooscaboose.noads")
            let request: SKProductsRequest = SKProductsRequest(productIdentifiers: productID as! Set<String>)
            request.delegate = self
            request.start()
            
        }
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(GameOverViewController.swiped(_:)))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.left
        self.view.addGestureRecognizer(swipeLeft)
        
        highScoreLabel.text = "Best: \(highScore)"
        // Setting text of labels to stored value
        mostRecentScore.text = "\(lastNineScores[0])"
        let stringArray = lastNineScores.map
        {
            String($0)
        }
        pastScores.text = stringArray.joined(separator: "  ")
    }
    
    func createAndLoadInterstitial() -> GADInterstitial {
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-1224845211182149/4021005644")
        interstitial.delegate = self
        let request = GADRequest()
        interstitial.load(request)
        return interstitial
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        interstitial = createAndLoadInterstitial()
    }
    
    func swiped(_ gesture: UIGestureRecognizer) {
        performSegue(withIdentifier: "toStore", sender: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        startOver?.isUserInteractionEnabled = true
        startOver?.addGestureRecognizer(tapGestureRecognizer)
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated);
    }
    
    // Unwind segue back to gameView
    func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        performSegue(withIdentifier: "unwindToHomeView", sender: self)
    }
    
    // Replay game with unwind segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "unwindToHomeView" {
            if let gameViewController = segue.destination as? GameViewController {
                gameViewController.isReplayGame = true
            }
        }
    }
    
    @IBAction func unwindToGameOver(sender: UIStoryboardSegue) {
    }
    
    // Hide status bar
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
