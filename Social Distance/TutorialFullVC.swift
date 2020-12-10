//
//  TutorialFullVC.swift
//  Social Distance
//
//  Created by Nick Crews on 4/28/20.
//  Copyright © 2020 People. Love. Change. All rights reserved.
//

import UIKit

class TutorialFullVC: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
        @IBOutlet weak var leftButton: UIButton!
        @IBOutlet weak var rightButton: UIButton!
        @IBOutlet weak var doneButton: UIButton!
        @IBOutlet weak var xButton: UIButton!
        
        var pages = [TutuorialImageVC]()
        
        var fromSet = false
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            if #available(iOS 13.0, *) {
                     overrideUserInterfaceStyle = .light
                 } else {
                     // Fallback on earlier versions
                 }
            self.leftButton.isUserInteractionEnabled = false
            self.leftButton.alpha = 0.3
            scrollView.delegate = self
           // scrollView.contentSize = CGSizeMake(scrollView.contentSize.width,scrollView.frame.size.height)
            self.doneButton.alpha = 0.0
            scrollView.isPagingEnabled = true
            scrollView.alwaysBounceVertical = true
            scrollView.isDirectionalLockEnabled = true
            
            if fromSet {
                self.xButton.alpha = 1
            } else {
                self.xButton.alpha = 0
            }
            
            if !fromSet {
                self.navigationController?.navigationItem.backBarButtonItem?.isEnabled = false
                navigationController?.interactivePopGestureRecognizer?.isEnabled = false
            }
            
            
            let page1 = createStep(title: "Set your comfort level and tap the start button\n", icon: "demographic", background: "startPhone")
            let page2 = createStep(title: "We will send a notification to those who breach your comfort zone\n", icon: "notification", background: "phoneGroce")
            let page3 = createStep(title: "Use in any location you need to practice Social Distancing\n", icon: "shop", background: "grocer")
            let page4 = createStep(title: "Share the app with Family & Friends to help stop the spread\n", icon: "team", background: "famfam")
            let page5 = createStep(title: "Donate to help us support Front-Line Workers\n", icon: "care", background: "healthy")
            
            pages = [page1, page2, page3, page4, page5]
            
            let views: [String: UIView] = ["view": view, "page1": page1.view, "page2": page2.view, "page3": page3.view, "page4": page4.view ,"page5": page5.view]
            
            let vertConsts = NSLayoutConstraint.constraints(withVisualFormat: "V:|[page1(==view)]|", options: [], metrics: nil, views: views)
            let horzConsts = NSLayoutConstraint.constraints(withVisualFormat: "H:|[page1(==view)][page2(==view)][page3(==view)][page4(==view)][page5(==view)]|", options: [.alignAllTop, .alignAllBottom], metrics: nil, views: views)
           
           
            NSLayoutConstraint.activate(vertConsts + horzConsts)
            
            self.view.bringSubviewToFront(leftButton)
            self.view.bringSubviewToFront(rightButton)
            self.view.bringSubviewToFront(doneButton)
            self.view.bringSubviewToFront(xButton)
        }
        
        
        private func createStep(title: String, icon: String, background: String) -> TutuorialImageVC {
            let tutStep = storyboard!.instantiateViewController(withIdentifier: "TutuorialImageVC") as! TutuorialImageVC
            tutStep.view.translatesAutoresizingMaskIntoConstraints = false
            
            
            tutStep.iconImage = UIImage(named: icon)
            tutStep.backImage = UIImage(named: background)
            tutStep.titleText = title
            
            scrollView.addSubview(tutStep.view)
            addChild(tutStep)
            tutStep.didMove(toParent: self)
            return tutStep
            
        }
        
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
                scrollView.contentOffset.y = 0.0
            if scrollView.bounds.contains(pages[4].view.frame) {
                // entire UIView is visible in scroll view
                print("page5")
            }
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            self.stoppedScrolling()
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate {
                self.stoppedScrolling()
            }
        }

        func stoppedScrolling() {
            print("Scroll finished")
            self.currentX = self.scrollView.contentOffset.x
            print(self.currentX)
            if currentX <= 0 {
                self.leftButton.isUserInteractionEnabled = false
               
                self.rightButton.isUserInteractionEnabled = true
          
                UIView.animate(withDuration: 0.4) {
                    self.rightButton.alpha = 1.0
                    self.leftButton.alpha = 0.3
                   
                }

            } else if currentX >= self.view.frame.width * 4 {
                self.rightButton.isUserInteractionEnabled = false
                
                self.leftButton.isUserInteractionEnabled = true
                
                print("done shows")
                UIView.animate(withDuration: 0.4) {
                    self.rightButton.alpha = 0.3
                    self.leftButton.alpha = 1.0
                    self.doneButton.alpha = 1.0
                }
            } else {
                self.leftButton.isUserInteractionEnabled = true

                self.rightButton.isUserInteractionEnabled = true
     
                UIView.animate(withDuration: 0.4) {
                    self.rightButton.alpha = 1.0
                    self.leftButton.alpha = 1.0
                }

            }
        }
        

        var currentX: CGFloat = 0.0
        @IBAction func tapRight(_ sender: AnyObject) {
            if currentX + self.view.frame.width <= self.view.frame.width * 4 {
            let point = CGPoint(x: self.view.frame.width + currentX, y: 200) // 200 or any value you like.
            currentX = self.view.frame.width + currentX
                     UIView.animate(withDuration: 0.4) {
                 self.scrollView.contentOffset = point
             }
            }
            self.leftButton.isUserInteractionEnabled = true
            
            if currentX >= self.view.frame.width * 4 {
                self.rightButton.isUserInteractionEnabled = false
           
                UIView.animate(withDuration: 0.4) {
                    self.doneButton.alpha = 1.0
                      self.rightButton.alpha = 0.3
                    self.leftButton.alpha = 1.0
                }
            } else {
                self.rightButton.isUserInteractionEnabled = true
                UIView.animate(withDuration: 0.4) {
                    self.rightButton.alpha = 1.0
                    self.leftButton.alpha = 1.0
                }
              
            }
         }
        
        @IBAction func tapLeft(_ sender: AnyObject) {
            if currentX - self.view.frame.width >= 0 {
            let point = CGPoint(x: currentX - self.view.frame.width, y: 200) // 200 or any value you like.
            currentX = currentX - self.view.frame.width
            UIView.animate(withDuration: 0.4) {
                self.scrollView.contentOffset = point
            }
            }
            self.rightButton.isUserInteractionEnabled = true

            if currentX <= 0 {
                self.leftButton.isUserInteractionEnabled = false
       
                UIView.animate(withDuration: 0.4) {
                    self.rightButton.alpha = 1.0
                    self.leftButton.alpha = 0.3
                }
            } else {
                self.leftButton.isUserInteractionEnabled = true
              
                UIView.animate(withDuration: 0.4) {
                    self.rightButton.alpha = 1.0
                    self.leftButton.alpha = 1.0
                }
            }
         }
        
        
        @IBAction func tapDone(_ sender: AnyObject) {
            if fromSet {
                self.dismiss(animated: true) {
                    print("peace")
                }
            } else {
                self.performSegue(withIdentifier: "toHomeTut", sender: nil)
            }
         }




}
