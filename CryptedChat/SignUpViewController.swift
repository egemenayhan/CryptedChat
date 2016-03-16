//
//  SignUpViewController.swift
//  CryptedChat
//
//  Created by egemen ayhan on 16/03/16.
//  Copyright © 2016 Razeware LLC. All rights reserved.
//

import UIKit
import Firebase

class SignUpViewController: UIViewController {

    @IBOutlet weak var BtnDismiss: UIButton!
    @IBOutlet weak var TFUsername: UITextField!
    @IBOutlet weak var TFMail: UITextField!
    @IBOutlet weak var TFPass1: UITextField!
    @IBOutlet weak var TFPass2: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.BtnDismiss.layer.cornerRadius = 45.0/2
        self.BtnDismiss.layer.borderWidth = 2
        self.BtnDismiss.layer.borderColor = UIColor.whiteColor().CGColor
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func signUpTapped(sender: AnyObject) {
        if self.TFUsername.text == "" || self.TFMail.text == "" || !self.isValidEmail(self.TFMail.text!) || self.TFPass1.text == "" || self.TFPass2.text == "" || self.TFPass1.text?.characters.count < 4 || self.TFPass1.text != self.TFPass2.text {
            let alert = UIAlertController(title: "Ooops!", message: "Please check fields, you did something wrong.", preferredStyle: UIAlertControllerStyle.Alert)
            
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
                return
            }))
            
            presentViewController(alert, animated: true, completion: nil)
        } else {
            let ref = Firebase(url: "https://cryptedchat.firebaseio.com")
            
            ref.createUser(self.TFMail.text, password: self.TFPass1.text, withValueCompletionBlock: { (error, response) -> Void in
                if error == nil {
                    ref.authUser(self.TFMail.text, password: self.TFPass1.text, withCompletionBlock: { (error, response) -> Void in
                        if error == nil {
                            print(response)
                            let newUser = [
                                "mail": self.TFMail.text as String!,
                                "displayName": self.TFUsername.text as String!
                            ]
                            
                            ref.childByAppendingPath("users").childByAppendingPath(response.uid).setValue(newUser)
                            	
                            NSUserDefaults.standardUserDefaults().setObject(response.token, forKey: "user_token")
                            self.dismissViewControllerAnimated(true, completion: nil);
                        } else {
                            print(error.description)
                        }
                    })
                } else {
                    print(error.description)
                }
            })
        }
    }

    @IBAction func dismissTapped(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        
        let result = emailTest.evaluateWithObject(testStr)
        
        return result
    }
}
