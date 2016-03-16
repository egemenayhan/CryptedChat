//
//  Conversation.swift
//  CryptedChat
//
//  Created by egemen ayhan on 16/03/16.
//  Copyright © 2016 egemen ayhan. All rights reserved.
//

import UIKit
import Firebase

class Conversation: NSObject {
    var ref: Firebase!
    
    var conversationID: String!
    var title: String!
    var dateInterval: Double!
    
    init(conversationID: String) {
        super.init()
        self.conversationID = conversationID
        
        self.ref = Firebase(url: "https://cryptedchat.firebaseio.com/conversations/")
        self.ref.childByAppendingPath(conversationID).observeSingleEventOfType(.Value) { (snapshot: FDataSnapshot!) -> Void in
            self.title = snapshot.value["title"] as! String
            self.dateInterval = snapshot.value["date"] as! Double
            NSNotificationCenter.defaultCenter().postNotificationName("reload_conversations", object: nil)
        }
    }
}
