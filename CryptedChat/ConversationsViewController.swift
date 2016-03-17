//
//  ConversationsViewController.swift
//  CryptedChat
//
//  Created by egemen ayhan on 16/03/16.
//  Copyright © 2016 egemen ayhan. All rights reserved.
//

import UIKit
import Firebase

class ConversationsViewController: UITableViewController {
    
    var ref: Firebase!
    var transactionRef: Firebase!
    var conversationsRef: Firebase!
    var conversations: NSMutableArray!
    var userMail: String!
    var userDisplayName: String!
    var selectedConversation: Conversation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBarHidden = false
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadUI", name: "reload_conversations", object: nil)
        
        self.userMail = NSUserDefaults.standardUserDefaults().stringForKey("user_mail")
        self.userDisplayName = NSUserDefaults.standardUserDefaults().stringForKey("displayName")
        self.navigationItem.title = self.userDisplayName
        
        self.conversations = NSMutableArray()
        
        ref = Firebase(url: "https://cryptedchat.firebaseio.com/")
        transactionRef = ref.childByAppendingPath("user_conversation")
        conversationsRef = ref.childByAppendingPath("conversations")
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.conversations.removeAllObjects()
        observeMessages()
    }
    
    func reloadUI() {
        self.tableView.reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.conversations.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        
        let conv = self.conversations[indexPath.row] as! Conversation
        cell.textLabel?.text = conv.title
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        self.selectedConversation = self.conversations[indexPath.row] as! Conversation
        self.performSegueWithIdentifier("chatSegue", sender: nil)
    }
    
    private func observeMessages() {
        self.transactionRef.queryOrderedByChild("mail").queryEqualToValue(self.userMail).observeEventType(.ChildAdded) { (snapshot: FDataSnapshot!) in
            let id = snapshot.value["conversationID"] as! String
            let conv = Conversation(conversationID: id)

            self.conversations.addObject(conv)
            
            self.tableView.reloadData()
        }
    }
    
    @IBAction func newConversationTapped(sender: AnyObject) {
        let alertController = UIAlertController(title: "New Conversation", message: "Enter recipient's mail address", preferredStyle: .Alert)
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "E-Mail"
            textField.keyboardType = .EmailAddress
        }
        
        let newConversationAction = UIAlertAction(title: "Create", style: .Default) { (_) in
            let TFMail = alertController.textFields![0] as UITextField
            
            if self.isValidEmail(TFMail.text!) {
                let usersRef = self.ref.childByAppendingPath("users")
                usersRef.queryOrderedByChild("mail").queryEqualToValue(TFMail.text).observeSingleEventOfType(.Value, withBlock: { (snapshot: FDataSnapshot!) -> Void in
                    if snapshot.value is NSNull {
                        alertController.dismissViewControllerAnimated(true, completion: { () -> Void in
                            let notFoundAlertController = UIAlertController(title: "Sorry :(", message: "User not found.", preferredStyle: .Alert)
                            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (_) in }
                            notFoundAlertController.addAction(cancelAction)
                            self.presentViewController(notFoundAlertController, animated: true, completion: nil)
                        })
                    } else {
                        
                        let data = snapshot.value as! NSDictionary
                        for (_, value) in data {
                            let recipientMail = value["mail"] as! String
                            let recipientDisplayName = value["displayName"] as! String
                            
                            let convRef = self.conversationsRef.childByAutoId()
                            let convItem = [
                                "title": recipientDisplayName+","+self.userDisplayName,
                                "date": NSDate().timeIntervalSince1970
                            ]
                            convRef.setValue(convItem)
                            
                            let transRef = self.transactionRef.childByAutoId()
                            let transItem = [
                                "mail": self.userMail,
                                "conversationID": convRef.key
                            ]
                            transRef.setValue(transItem)
                            
                            let recipintTransRef = self.transactionRef.childByAutoId()
                            let recipientTransItem = [
                                "mail": recipientMail,
                                "conversationID": convRef.key
                            ]
                            recipintTransRef.setValue(recipientTransItem)
                        }
                    }
                })
            } else {
                return
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (_) in }
        
        alertController.addAction(newConversationAction)
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }

    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        
        let result = emailTest.evaluateWithObject(testStr)
        
        return result
    }
    
    @IBAction func logoutTapped(sender: AnyObject) {
        NSUserDefaults.standardUserDefaults().removeObjectForKey("user_token")
        self.navigationController?.popViewControllerAnimated(true)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "chatSegue" {
            let destinationVC = segue.destinationViewController as! ChatViewController
            destinationVC.conversation = self.selectedConversation
        }
    }
}
