//
//  Extension+UITabBarController.swift
//  Fast Playist Maker
//
//

import UIKit

extension UITabBarController {
    
    @objc func animateToTab(toIndex: Int) {
        guard let tabViewControllers = viewControllers else {
            return
        }
        guard let fromView = selectedViewController?.view else {
            return
        }
        guard let toView = tabViewControllers[toIndex].view else {
            return
        }
        guard let fromIndex = tabViewControllers.firstIndex(of: selectedViewController!) else {
            return
        }
        
        guard fromIndex != toIndex else {return}
        
        // Add the toView to the tab bar view
        fromView.superview!.addSubview(toView)
        
        // Position toView off screen (to the left/right of fromView)
        let screenWidth = UIScreen.main.bounds.size.width;
        let scrollRight = toIndex > fromIndex
        let offset = (scrollRight ? screenWidth : -screenWidth)
        toView.center = CGPoint(x: fromView.center.x + offset, y: toView.center.y)
        
        // Disable interaction during animation
        view.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
            
            // Slide the views by -offset
            fromView.center = CGPoint(x: fromView.center.x - offset, y: fromView.center.y);
            toView.center   = CGPoint(x: toView.center.x - offset, y: toView.center.y);
            
        }, completion: { finished in
            
            // Remove the old view from the tabbar view.
            fromView.removeFromSuperview()
            self.selectedIndex = toIndex
            self.view.isUserInteractionEnabled = true
        })
    }
    
}
