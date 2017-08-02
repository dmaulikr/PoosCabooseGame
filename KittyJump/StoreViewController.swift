//
//  StoreViewController.swift
//  KittyJump
//
//  Created by Olivia Brown on 7/10/17.
//  Copyright © 2017 Olivia Brown. All rights reserved.
//

import UIKit
import Contacts
import MessageUI
import StoreKit
import SwiftyGif
import Firebase
import FirebaseDatabase

var using: Int = 0
var selectedPhoneNumber: String = ""

class StoreViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver, MFMessageComposeViewControllerDelegate {
    
    var ref: DatabaseReference?
    var handle: DatabaseHandle?
    let user = Auth.auth().currentUser
    
    var itemStates: [String] = []
    
    @IBOutlet weak var currentCoins: UILabel!
    @IBOutlet weak var coinImage: UIImageView!
    @IBOutlet weak var modalView: UIView!
    @IBOutlet weak var modalTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var darkenedView: UIView!
    @IBOutlet weak var modalHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var peek: UIImageView!
    @IBAction func backButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "unwindToGameOver", sender: self)
    }
    @IBOutlet weak var inviteFriendsView: UIView!
    @IBOutlet weak var unlockedLabel: UILabel!
    
    // Slides
    let slide0 = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
    let slide1 = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
    let slide2 = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
    let slide3 = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
    let slide4 = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
    let slide5 = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
    let slide6 = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
    let slide7 = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
    
    @IBOutlet weak var scrollView: UIScrollView!
    var confirm: Bool = false
    //var coins = SharingManager.sharedInstance.lifetimeScore
    var coins = 10000
    var cost: Int = 0
    var buyButton: UIButton? = nil
    var coin: UIImageView? = nil
    var itemTitle: String = ""
    var use: Bool = false
    var pageIndex: Int = 0
    
    // Connections for add coins popup
    @IBOutlet weak var addCoinsView: UIView!
    @IBOutlet weak var firstAddCoins: UIView!
    @IBOutlet weak var addCoinsLabel: UILabel!
    @IBOutlet weak var secondAddCoins: UIView!
    @IBOutlet weak var thirdAddCoins: UIView!
    @IBOutlet weak var fourthAddCoins: UIView!
    @IBOutlet weak var fifthAddCoins: UIView!
    @IBOutlet weak var addModalTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var pageControl: UIPageControl!
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        _ = tapGestureRecognizer.view as! UIImageView
    }
    
    func removeUserDefaults() {

        itemStates = SharingManager.sharedInstance.itemStates
        ref?.child("players").child(user!.uid).updateChildValues(["poosesOwned": itemStates])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        handle = ref?.child("players").child(user!.uid).child("poosesOwned").observe(.childChanged, with: { (snapshot) in
            if let item = snapshot.value as? String {
                let index = Int(snapshot.key)
                self.itemStates[index!] = item
            }
        })
        
        if user != nil {
        removeUserDefaults()
        }
        
        self.gifView.delegate = self
        
        //Add coin button click
        
        let addCoinBtnClick = UITapGestureRecognizer(target: self, action: #selector(animateAddCoinsView))
        coinImage.isUserInteractionEnabled = true
        coinImage.addGestureRecognizer(addCoinBtnClick)
        
        let slides: [Slide] = createSlides()
        setupScrollView(slides: slides)
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        scrollView.delegate = self
        pageControl.numberOfPages = slides.count
        pageControl.currentPage = 0
        view.bringSubview(toFront: pageControl)
        
        updateCoinsLabel()
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        swipeRight.delegate = self
        self.view.addGestureRecognizer(swipeRight)
        
        if (SKPaymentQueue.canMakePayments()) {
            let productID: NSSet = NSSet(objects: "org.pooscaboose.onek", "org.pooscaboose.fivek", "org.pooscaboose.tenk", "org.pooscaboose.hundredk")
            let request: SKProductsRequest = SKProductsRequest(productIdentifiers: productID as! Set<String>)
            
            request.delegate = self
            request.start()
        }
        else {
        }
        updateUnlocked()
    }
    
    func updateUnlocked() {
        var unlocked: Int = 0
        for i in SharingManager.sharedInstance.itemStates {
            if i == "inCloset" {
                unlocked += 1
            }
        }
        let unlockedString: String = "\(unlocked) of 8 unlocked"
        let attributedText = NSMutableAttributedString(string: unlockedString, attributes: [NSFontAttributeName:UIFont(name: "Avenir-Medium", size: 18.0)!])
        attributedText.addAttribute(NSFontAttributeName, value: UIFont(name: "Avenir-Black",size: 18.0)!, range: NSRange(location:0,length:1))
        attributedText.addAttribute(NSFontAttributeName, value: UIFont(name: "Avenir-Black",size: 18.0)!, range: NSRange(location:5,length:1))
        unlockedLabel.attributedText = attributedText
    }
    
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if pageIndex == 0 {
            performSegue(withIdentifier: "unwindToGameOver", sender: self)
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
    
    func buttonInUse(button: UIButton) {
        button.backgroundColor = UIColor.white
        button.setTitleColor(UIColor(red:0.21, green:0.81, blue:0.85, alpha:1.0), for: .normal)
        button.setTitle("in use", for: .normal)
    }
    
    func buttonNotInUse(button: UIButton) {
        button.backgroundColor = UIColor.clear
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitle("use", for: .normal)
    }
    
    func setupInCloset(slide: Slide, x: Int) {
        slide.buyButton.isHidden = true
        slide.coinImage.isHidden = true
        slide.costLabel.isHidden = true
        slide.coinLabel.isHidden = true
        slide.useButton.isHidden = false
        if SharingManager.sharedInstance.using == x {
            buttonInUse(button: slide.useButton)
        }
        else {
            buttonNotInUse(button: slide.useButton)
        }
        slide.useButton.layer.cornerRadius = 20
        slide.useButton.layer.borderWidth = 3
        slide.useButton.layer.borderColor = UIColor.white.cgColor
        slide.useButton.addTarget(self, action: #selector(updateUsing), for: .touchUpInside)
    }
    
    func setupInStore(slide: Slide) {
        slide.useButton.isHidden = true
        slide.buyButton.layer.cornerRadius = 20
        slide.buyButton.layer.borderWidth = 3
        slide.buyButton.layer.borderColor = UIColor.white.cgColor
        slide.buyButton.addTarget(self, action: #selector(purchaseItem), for: .touchUpInside)
    }
    
    func createSlides() -> [Slide] {
        
        let slideArray = [slide0, slide1, slide2, slide3, slide4, slide5, slide6, slide7]
        
        var x = 0
        for i in slideArray {
            if SharingManager.sharedInstance.itemStates[x] == "inCloset" {
                setupInCloset(slide: i, x: x)
            }
            else {
                setupInStore(slide: i)
            }
            x += 1
        }
        
        slide0.image.image = #imageLiteral(resourceName: "ogStore")
        slide0.titleLabel.text = "og poos"
        slide0.imageHeight.constant = 216
        
        slide1.image.image = #imageLiteral(resourceName: "trotterStore")
        slide1.titleLabel.text = "poos trotter"
        slide1.costLabel.text = "1,000"
        slide1.imageHeight.constant = 245
        
        slide2.image.image = #imageLiteral(resourceName: "rateStore")
        slide2.titleLabel.text = "pirate poos"
        slide2.costLabel.text = "1,000"
        slide2.imageHeight.constant = 217
        
        slide3.image.image = #imageLiteral(resourceName: "properStore")
        slide3.titleLabel.text = "proper poos"
        slide3.costLabel.text = "2,000"
        slide3.imageHeight.constant = 230
        
        slide4.image.image = #imageLiteral(resourceName: "quaStore")
        slide4.titleLabel.text = "quapoos"
        slide4.costLabel.text = "5,000"
        slide4.imageHeight.constant = 217
        
        slide5.image.image = #imageLiteral(resourceName: "pousStore")
        slide5.titleLabel.text = "le pous"
        slide5.costLabel.text = "10,000"
        slide5.imageHeight.constant = 208
        
        slide6.image.image = #imageLiteral(resourceName: "bootsStore")
        slide6.titleLabel.text = "poos in boots"
        slide6.costLabel.text = "25,000"
        slide6.imageHeight.constant = 253
        
        if coins >= 100000 {
            slide7.image.image = #imageLiteral(resourceName: "trumpStore")
            slide7.titleLabel.text = "trumpoos"
            slide7.imageHeight.constant = 216
        }
        else if SharingManager.sharedInstance.itemStates[7] == "inCloset" {
            slide7.image.image = #imageLiteral(resourceName: "trumpStore")
            slide7.titleLabel.text = "trumpoos"
            slide7.imageHeight.constant = 216
        }
        else {
            slide7.image.image = #imageLiteral(resourceName: "mysteryStore")
            slide7.titleLabel.text = "?????"
            slide7.imageHeight.constant = 207
        }
        slide7.costLabel.text = "100,000"
        
        return [slide0, slide1, slide2, slide3, slide4, slide5, slide6, slide7]
    }
    
    func setupScrollView(slides: [Slide]) {
        scrollView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        scrollView.contentSize = CGSize(width: view.frame.width * CGFloat(slides.count), height: view.frame.height)
        
        for i in 0 ..< slides.count {
            slides[i].frame = CGRect(x: view.frame.width * CGFloat(i), y: 0, width: view.frame.width, height: view.frame.height)
            
            scrollView.addSubview(slides[i])
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        pageIndex = Int(round(scrollView.contentOffset.x/view.frame.width))
        pageControl.currentPage = pageIndex
    }
    @IBAction func confirmPressed(_ sender: Any) {
        confirm = true
        hideModal()
    }
    @IBAction func cancelPressed(_ sender: Any) {
        confirm = false
        hideModal()
    }
    
    // Change display to use button
    func itemAlreadyPurchased() {
        
        var currentSlide: Slide = slide1
        
        if pageIndex == 1 {
            currentSlide = slide1
        }
        else if pageIndex == 2 {
            currentSlide = slide2
        }
        else if pageIndex == 3 {
            currentSlide = slide3
        }
        else if pageIndex == 4 {
            currentSlide = slide4
        }
        else if pageIndex == 5 {
            currentSlide = slide5
        }
        else if pageIndex == 6 {
            currentSlide = slide6
        }
        else if pageIndex == 7 {
            currentSlide = slide7
        }
        setupInCloset(slide: currentSlide, x: pageIndex)
    }
    
    func updateUseButton() {
        let allSlides = [slide0, slide1, slide2, slide3, slide4, slide5, slide6, slide7]
        
        var x = 0
        for i in allSlides {
            if SharingManager.sharedInstance.using == x {
                buttonInUse(button: i.useButton)
            }
            else {
                if SharingManager.sharedInstance.itemStates[x] == "inCloset" {
                    buttonNotInUse(button: i.useButton)
                }
                else {
                    buttonInUse(button: i.useButton)
                }
            }
            x += 1
        }
    }
    
    func updateUsing() {
        
        if pageIndex == 0 {
            SharingManager.sharedInstance.using = 0
            SharingManager.sharedInstance.catImageString = "poos"
            updateUseButton()
        }
        else if pageIndex == 1 {
            SharingManager.sharedInstance.using = 1
            SharingManager.sharedInstance.catImageString = "trotterpoos"
            updateUseButton()
        }
        else if pageIndex == 2 {
            SharingManager.sharedInstance.using = 2
            SharingManager.sharedInstance.catImageString = "poosrate"
            updateUseButton()
        }
        else if pageIndex == 3 {
            SharingManager.sharedInstance.using = 3
            SharingManager.sharedInstance.catImageString = "properpoos"
            updateUseButton()
        }
        else if pageIndex == 4 {
            SharingManager.sharedInstance.using = 4
            SharingManager.sharedInstance.catImageString = "quapoos"
            updateUseButton()
        }
        else if pageIndex == 5 {
            SharingManager.sharedInstance.using = 5
            SharingManager.sharedInstance.catImageString = "pous"
            updateUseButton()
        }
        else if pageIndex == 6 {
            SharingManager.sharedInstance.using = 6
            SharingManager.sharedInstance.catImageString = "bootspoos"
            updateUseButton()
        }
        else if pageIndex == 7 {
            SharingManager.sharedInstance.using = 7
            SharingManager.sharedInstance.catImageString = "trumpoos"
            updateUseButton()
        }
    }
    
    // Try to buy something
    func purchaseItem() {
        
        let failureGenerator = UINotificationFeedbackGenerator()
        failureGenerator.prepare()

        if pageIndex == 1 {
            itemTitle = "poos trotter"
            cost = 1000
        }
        else if pageIndex == 2 {
            itemTitle = "pirate poos"
            cost = 1000
        }
        else if pageIndex == 3 {
            itemTitle = "proper poos"
            cost = 2000
        }
        else if pageIndex == 4 {
            itemTitle = "quapoos"
            cost = 5000
        }
        else if pageIndex == 5 {
            itemTitle = "le pous"
            cost = 10000
        }
        else if pageIndex == 6 {
            itemTitle = "poos in boots"
            cost = 25000
        }
        else if pageIndex == 7 {
            itemTitle = "trumpoos"
            cost = 100000
        }
        
        if cost <= coins {
            modalView.layer.cornerRadius = 20
            confirmButton.layer.cornerRadius = 25
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = NumberFormatter.Style.decimal
            let formattedCost = numberFormatter.string(from: NSNumber(value:cost))
            messageLabel.text = "Buy \(itemTitle) for \n \(formattedCost!) coins?"
            showModal()
        }
        else {
            failureGenerator.notificationOccurred(.error)
            modalView.layer.cornerRadius = 20
            confirmButton.layer.cornerRadius = 25
            messageLabel.text = "Poos... You don't have enough poos coin. Would you like to buy more?"
            showModal()
        }
    }
    
    func showModal() {
        
        darkenedView.isHidden = false
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        darkenedView.addGestureRecognizer(tap)
        
        modalTopConstraint.constant += self.view.bounds.height
        view.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.5, animations: {
            self.modalView.isHidden = false
            self.modalTopConstraint.constant -= self.view.bounds.height
            self.view.layoutIfNeeded()
        })
    }
    
    func handleTap() {
        confirm = false
        hideModal()
        hideAddCoinsModal()
        hideShareModal()
    }
    
    func hideModal() {
        view.layoutIfNeeded()
        
        if confirm == false {
            darkenedView.isHidden = true
            UIView.animate(withDuration: 0.5, animations: {
                self.modalTopConstraint.constant += self.view.bounds.height
                self.view.layoutIfNeeded()
            }, completion: { (finished: Bool) in
                if finished {
                    self.modalView.isHidden = true
                    self.modalTopConstraint.constant -= self.view.bounds.height
                }
            })
        }
        
        if confirm == true && coins >= cost {
            darkenedView.isHidden = true
            UIView.animate(withDuration: 0.5, animations: {
                self.modalTopConstraint.constant += self.view.bounds.height
                self.view.layoutIfNeeded()
            }, completion: { (finished: Bool) in
                if finished {
                    self.modalView.isHidden = true
                    self.modalTopConstraint.constant -= self.view.bounds.height
                }
            })
            
            coins -= cost
            
            updateCoinsLabel()
            SharingManager.sharedInstance.lifetimeScore = coins
            ref?.child("players").child(user!.uid).child("poosesOwned").updateChildValues(["\(pageIndex)": "inCloset"])
            updateUnlocked()
            itemAlreadyPurchased()
            if #available(iOS 10.3, *) {
                SKStoreReviewController.requestReview()
            }
        }
        else if confirm == true && cost >= coins {
            showAddCoinsView();
        }
    }
    
    func showAddCoinsView(){
        view.layoutIfNeeded()
        
        darkenedView.isHidden = false
        modalView.isHidden = true
        addCoinsView.layer.cornerRadius = 28
        addCoinsLabel.text = "Pick your poos coin \n package"
        peek.isHidden = false
        addCoinsView.isHidden = false
        addCoinsGestures()
    }
    
    func animateAddCoinsView() {
        addCoinsView.layer.cornerRadius = 28
        addCoinsLabel.text = "Pick your poos coin \n package"
        
        darkenedView.isHidden = false
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        darkenedView.addGestureRecognizer(tap)
        
        addModalTopConstraint.constant += self.view.bounds.height
        view.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.5, animations: {
            self.addCoinsView.isHidden = false
            self.addModalTopConstraint.constant -= self.view.bounds.height
            self.view.layoutIfNeeded()
        })
        addCoinsGestures()
    }
    
    func setPlaceHolder(placeholder: String)-> String
    {
        
        var text = placeholder
        if text.characters.last! != " " {
            
            // define a max size
            let maxSize = CGSize(width: UIScreen.main.bounds.size.width - 104, height: 40)
            // get the size of the text
            let widthText = text.boundingRect( with: maxSize, options: .usesLineFragmentOrigin, attributes:nil, context:nil).size.width
            // get the size of one space
            let widthSpace = " ".boundingRect( with: maxSize, options: .usesLineFragmentOrigin, attributes:nil, context:nil).size.width
            let spaces = floor((maxSize.width - widthText) / widthSpace)
            // add the spaces
            let newText = text + ((Array(repeating: " ", count: Int(spaces)).joined(separator: "")))
            // apply the new text if nescessary
            if newText != text {
                return newText
            }
            
        }
        
        return placeholder;
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func inviteFriends() {
        checkAuthorization()
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        inviteFriendsView.addGestureRecognizer(tap)
        inviteFriendsView.layer.cornerRadius = 28
        let textFieldInsideSearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = UIColor.black
        textFieldInsideSearchBar?.font = UIFont(name: "Avenir-Medium", size: 18)
        textFieldInsideSearchBar?.attributedPlaceholder = NSAttributedString(string: self.setPlaceHolder(placeholder: "search"), attributes: [NSForegroundColorAttributeName: UIColor.black])
        let button = textFieldInsideSearchBar?.value(forKey: "clearButton") as! UIButton
        if let image = button.imageView?.image {
            button.setImage(image.transform(withNewColor: UIColor.black), for: .normal)
            if let imageView = textFieldInsideSearchBar?.leftView as? UIImageView {
                imageView.image = imageView.image?.transform(withNewColor: UIColor.black)
            }
        }

        inviteFriendsView.isHidden = false
    }
    
    func addCoinsGestures() {
        
        let firstTap = UITapGestureRecognizer(target: self, action: #selector(inviteFriends))
        firstAddCoins.addGestureRecognizer(firstTap)
        let secondTap = UITapGestureRecognizer(target: self, action: #selector(buyCoins))
        secondAddCoins.addGestureRecognizer(secondTap)
        let thirdTap = UITapGestureRecognizer(target: self, action: #selector(buyCoins))
        thirdAddCoins.addGestureRecognizer(thirdTap)
        let fourthTap = UITapGestureRecognizer(target: self, action: #selector(buyCoins))
        fourthAddCoins.addGestureRecognizer(fourthTap)
        let fifthTap = UITapGestureRecognizer(target: self, action: #selector(buyCoins))
        fifthAddCoins.addGestureRecognizer(fifthTap)
    }
    
    func hideAddCoinsModal() {
        view.layoutIfNeeded()
        darkenedView.isHidden = true
        UIView.animate(withDuration: 0.5, animations: {
            self.addModalTopConstraint.constant += self.view.bounds.height
            self.view.layoutIfNeeded()
        }, completion: { (finished: Bool) in
            if finished {
                self.addCoinsView.isHidden = true
                self.addModalTopConstraint.constant -= self.view.bounds.height
                self.peek.isHidden = true
            }
        })
    }
    
    @IBOutlet weak var shareTopConstraint: NSLayoutConstraint!
    
    func hideShareModal() {
        view.layoutIfNeeded()
        darkenedView.isHidden = true
        UIView.animate(withDuration: 0.5, animations: {
            self.shareTopConstraint.constant += self.view.bounds.height
            self.view.endEditing(true)
            self.view.layoutIfNeeded()
        }, completion: { (finished: Bool) in
            if finished {
                self.inviteFriendsView.isHidden = true
                self.shareTopConstraint.constant -= self.view.bounds.height
                self.peek.isHidden = true
            }
        })
    }
    
    @IBAction func cancelShare(_ sender: Any) {
        hideShareModal()
    }
    
    @IBAction func cancelAddCoins(_ sender: Any) {
        hideAddCoinsModal()
    }
    
    func buyCoins(_ recognizer: UITapGestureRecognizer) {
        
        let viewTapped = recognizer.view
        viewTapped?.backgroundColor = UIColor(red:0.93, green:0.93, blue:0.93, alpha:1.0)
        
        if viewTapped == secondAddCoins {
            for product in list {
                let prodID = product.productIdentifier
                if prodID == "org.pooscaboose.onek" {
                    p = product
                    buyProduct()
                }
            }
        }
        else if viewTapped == thirdAddCoins {
            for product in list {
                let prodID = product.productIdentifier
                if prodID == "org.pooscaboose.fivek" {
                    p = product
                    buyProduct()
                }
            }
        }
        else if viewTapped == fourthAddCoins {
            for product in list {
                let prodID = product.productIdentifier
                if prodID == "org.pooscaboose.tenk" {
                    p = product
                    buyProduct()
                }
            }
        }
        else if viewTapped == fifthAddCoins {
            for product in list {
                let prodID = product.productIdentifier
                if prodID == "org.pooscaboose.hundredk" {
                    p = product
                    buyProduct()
                }
            }
        }
        viewTapped?.backgroundColor = UIColor(red:1, green:1, blue:1, alpha:1.0)
    }
    
    func buyProduct() {
        let pay = SKPayment(product: p)
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().add(pay as SKPayment)
    }

    func updateCoinsLabel() {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        let formattedCoins = numberFormatter.string(from: NSNumber(value:coins))
        currentCoins.text = formattedCoins
    }
    
    @IBOutlet weak var gifView: UIImageView!
    func addPurchasedCoins(amount: Int) {
        
        gifView.isHidden = false
        
        let gif = UIImage(gifName: "coin.gif")
        let gifManager = SwiftyGifManager(memoryLimit: 20)
        self.gifView.setGifImage(gif, manager: gifManager, loopCount: 1)
        
        coins += amount
        SharingManager.sharedInstance.lifetimeScore += amount
        
        if coins >= 100000 {
            slide7.image.image = #imageLiteral(resourceName: "trumpStore")
            slide7.titleLabel.text = "trumpoos"
        }
        updateCoinsLabel()
        
        if amount > 250 {
            hideAddCoinsModal()
        }
    }
    
    var list = [SKProduct]()
    var p = SKProduct()
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let myProduct = response.products
        for product in myProduct {
            list.append(product)
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction: AnyObject in transactions {
            let trans = transaction as! SKPaymentTransaction
            
            switch trans.transactionState {
            case .purchased:
                let prodID = p.productIdentifier
                switch prodID {
                case "org.pooscaboose.onek":
                    addPurchasedCoins(amount: 1000)
                    
                case "org.pooscaboose.fivek":
                    addPurchasedCoins(amount: 5000)
                    
                case "org.pooscaboose.tenk":
                    addPurchasedCoins(amount: 10000)
                    
                case "org.pooscaboose.hundredk":
                    addPurchasedCoins(amount: 100000)
                    
                default:
                    print("IAP not found")
                }
            case .failed:
                queue.finishTransaction(trans)
                break
                
            default:
                break
            }
        }
    }
    
    // CONTACTS
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!

    var contacts = [CNContact]()
    var authStatus: CNAuthorizationStatus = .denied {
        didSet {
            searchBar.isUserInteractionEnabled = authStatus == .authorized
            if authStatus == .authorized { // all search
                contacts = fetchContacts("")
                DispatchQueue.main.async() {
                    self.tableView.reloadData()
                }
                
            }
        }
    }
    
    fileprivate let kCellID = "ContactsTableViewCell"
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        contacts = fetchContacts(searchText)
        tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kCellID, for: indexPath) as! ContactsTableViewCell
        
        cell.viewController = self
        let contact = contacts[indexPath.row]
        
        // get the full name
        let fullName = CNContactFormatter.string(from: contact, style: .fullName) ?? "NO NAME"
        cell.nameLabel?.text = fullName.lowercased()
        
        return cell
    }
    
    fileprivate func checkAuthorization() {
        // get current status
        let status = CNContactStore.authorizationStatus(for: .contacts)
        authStatus = status
        
        switch status {
        case .notDetermined: // case of first access
            CNContactStore().requestAccess(for: .contacts) { [unowned self] (granted, error) in
                if granted {
                    self.authStatus = .authorized
                } else {
                    self.authStatus = .denied
                }
            }
        case .restricted, .denied:
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            let settingsAction = UIAlertAction(title: "Settings", style: .default, handler: { (action: UIAlertAction) in
                let url = URL(string: UIApplicationOpenSettingsURLString)
                self.open(link: String(describing: url))
            })
            showAlert(
                title: "Permission Denied",
                message: "You have not permission to access contacts. Please allow the access the Settings screen.",
                actions: [okAction, settingsAction])
        case .authorized:
            print("Authorized")
        }
    }
    // Opening URLs with iOS 10 & below
    func open(link: String) {
        if let url = URL(string: link) {
            if #available(iOS 10, *) {
                UIApplication.shared.open(url, options: [:],
                                          completionHandler: {
                                            (success) in
                                            print("Open \(link): \(success)")
                })
            } else {
                let success = UIApplication.shared.openURL(url)
                print("Open \(link): \(success)")
            }
        }
    }
    
    
    // fetch the contact of matching names
    fileprivate func fetchContacts(_ name: String) -> [CNContact] {
        let store = CNContactStore()
        
        do {
            let request = CNContactFetchRequest(keysToFetch: [CNContactFormatter.descriptorForRequiredKeys(for: .fullName), CNContactPhoneNumbersKey as CNKeyDescriptor])
            if name.isEmpty { // all search
                request.predicate = nil
            } else {
                request.predicate = CNContact.predicateForContacts(matchingName: name)
            }
            
            var contacts = [CNContact]()
            try store.enumerateContacts(with: request, usingBlock: { (contact, error) in
                contacts.append(contact)
            })
            
            return contacts
        } catch let error as NSError {
            NSLog("Fetch error \(error.localizedDescription)")
            return []
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let contact = contacts[indexPath.row]
        selectedPhoneNumber = ""
        
        for phoneNumber:CNLabeledValue in contact.phoneNumbers {
            let number  = phoneNumber.value
            
            let tempNumString = "0123456789"
            
            for c in number.stringValue.characters {
                if tempNumString.characters.contains(c) {
                    selectedPhoneNumber.append(c)
                }
            }
            break
        }
        
        let messageComposer = MessageComposer()
        
        let textMessageRecipients = ["\(selectedPhoneNumber)"]
        if (messageComposer.canSendText()) {
            let messageVC = MFMessageComposeViewController()
            
            messageVC.body = "Yo hop on the Caboose, Poos! http://pooscaboose.com/download";
            messageVC.recipients = textMessageRecipients
            messageVC.messageComposeDelegate = self;
            
            self.present(messageVC, animated: false, completion: nil)
            tableView.deselectRow(at: indexPath, animated: true)
            
        } else {
            let errorAlert = UIAlertController(title: "Cannot Send Text Message", message: "Your device is not able to send text messages.", preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
            self.present(errorAlert, animated: true){}
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch (result.rawValue) {
        case MessageComposeResult.cancelled.rawValue:
            controller.dismiss(animated: true, completion: nil)
        case MessageComposeResult.failed.rawValue:
            controller.dismiss(animated: true, completion: nil)
        case MessageComposeResult.sent.rawValue:
            controller.dismiss(animated: true, completion: nil)
            addPurchasedCoins(amount: 250)
            darkenedView.isHidden = false
        default:
            break;
        }
    }
    
    fileprivate func showAlert(title: String, message: String, actions: [UIAlertAction]) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        
        for action in actions {
            alert.addAction(action)
        }
        
        DispatchQueue.main.async(execute: { [unowned self] () in
            self.present(alert, animated: true, completion: nil)
        })
    }
    
    // Hide status bar
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
extension String {
    
    subscript (i: Int) -> Character {
        return self[self.characters.index(self.startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        let start = characters.index(startIndex, offsetBy: r.lowerBound)
        let end = characters.index(start, offsetBy: r.upperBound - r.lowerBound)
        return self[Range(start ..< end)]
    }
}
extension StoreViewController: SwiftyGifDelegate {
    
    func gifDidLoop() {
        gifView.isHidden = true
    }
}
extension UIImage {
    
    func transform(withNewColor color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(.normal)
        
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        context.clip(to: rect, mask: cgImage!)
        
        color.setFill()
        context.fill(rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}
