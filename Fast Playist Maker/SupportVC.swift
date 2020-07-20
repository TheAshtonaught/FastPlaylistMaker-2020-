//
//  SupportVC.swift
//  Fast Playist Maker
//
//

import UIKit
import MessageUI

class SupportVC: UIViewController, MFMailComposeViewControllerDelegate {
    
    @objc func sendEmail() {
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        composeVC.setToRecipients(["playlistcheetah@gmail.com"])
        composeVC.setSubject("Support")
       
        self.present(composeVC, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult, error: Error?) {
        // Check the result or perform other tasks.
        // Dismiss the mail compose view controller.
        controller.dismiss(animated: true, completion: nil)
    }

    @IBAction func sendEmail(_ sender: Any) {
        
        if MFMailComposeViewController.canSendMail() {
            sendEmail()
        }
    }
    
    
    


}
