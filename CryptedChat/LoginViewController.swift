/*
* Copyright (c) 2015 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit
import Firebase
import MRProgress

class LoginViewController: UIViewController {
    
    @IBOutlet weak var TFMail: UITextField!
    @IBOutlet weak var TFPass: UITextField!
    var ref: Firebase!
    var overlay: MRProgressOverlayView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Firebase(url: "https://cryptedchat.firebaseio.com/")
        //NSUserDefaults.standardUserDefaults().removeObjectForKey("user_token")
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if (self.overlay != nil) {
            self.overlay.dismiss(false)
        }
        
        self.TFMail.text = ""
        self.TFPass.text = ""
        
        self.view.endEditing(true)
        
        self.navigationController?.navigationBarHidden = true
        
        let token = NSUserDefaults.standardUserDefaults().stringForKey("user_token")
        if token != nil {
            self.overlay = MRProgressOverlayView.showOverlayAddedTo(self.view, animated: true)
            self.overlay.mode = .Indeterminate
            self.overlay.tintColor = self.view.backgroundColor
            self.view.addSubview(self.overlay)
            self.overlay.show(true)
            
            ref.authWithCustomToken(token, withCompletionBlock: { (error, data) -> Void in
                if error == nil {
                    self.overlay.show(false)
                    self.overlay.mode = .Checkmark
                    self.overlay.show(true)
                    
                    self.performSegueWithIdentifier("conversationsSegue", sender: nil)
                } else {
                    self.overlay.show(false)
                    self.overlay.mode = .Cross
                    self.overlay.titleLabelText = error.localizedDescription
                    self.overlay.show(true)
                    
                    print(error.description)
                }
            })
        }
    }
    
    @IBAction func loginDidTouch(sender: AnyObject) {
        if self.TFMail.text == "" || !self.isValidEmail(self.TFMail.text!) || self.TFPass.text?.characters.count < 4  {
            let alert = UIAlertController(title: "Ooops!", message: "Please check fields, you did something wrong.", preferredStyle: UIAlertControllerStyle.Alert)
            
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
                return
            }))
            
            presentViewController(alert, animated: true, completion: nil)
        } else {
            self.overlay = MRProgressOverlayView.showOverlayAddedTo(self.view, animated: true)
            self.overlay.mode = .Indeterminate
            self.overlay.tintColor = self.view.backgroundColor
            self.view.addSubview(self.overlay)
            self.overlay.show(true)
            
            ref.authUser(self.TFMail.text, password: self.TFPass.text) { (error: NSError!, data: FAuthData!) -> Void in
                if error == nil {
                    NSUserDefaults.standardUserDefaults().setObject(data.token, forKey: "user_token")
                    self.ref.childByAppendingPath("users").childByAppendingPath(data.uid).observeSingleEventOfType(.Value, withBlock: { (snapshot: FDataSnapshot!) -> Void in
                        print(snapshot.value)
                        NSUserDefaults.standardUserDefaults().setObject(snapshot.value["displayName"] ,forKey: "displayName")
                        NSUserDefaults.standardUserDefaults().setObject(snapshot.value["mail"], forKey: "user_mail")
                        self.overlay.show(false)
                        self.overlay.mode = .Checkmark
                        self.overlay.show(true)
                        
                        self.performSegueWithIdentifier("conversationsSegue", sender: nil)
                    })
                } else {
                    self.overlay.show(false)
                    self.overlay.mode = .Cross
                    self.overlay.titleLabelText = error.localizedDescription
                    self.overlay.show(true)
                    print(error.description)
                }
            }
        }
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        
        if segue.identifier == "chatSegue" {
            let navVc = segue.destinationViewController as! UINavigationController // 1
            let chatVc = navVc.viewControllers.first as! ChatViewController // 2
            chatVc.senderId = ref.authData.uid // 3
            chatVc.senderDisplayName = "" // 4
        }
    }
    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        
        let result = emailTest.evaluateWithObject(testStr)
        
        return result
    }
}

