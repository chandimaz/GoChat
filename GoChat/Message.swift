//
//  Message.swift
//  GoChat
//
//  Created by Virtual on 12/26/17.
//  Copyright © 2017 Virtual. All rights reserved.
//

import UIKit
import Firebase

class Message: NSObject {
    var text: String?
    var toId: String?
    var fromId: String?
    var timeStamp: String?
    var imageUrl: String?
    var imageWidth: NSNumber?
    var imageHeight: NSNumber?
    var videoUrl: String?
    
    func chatPartnerId() -> String? {
        
        
        return fromId == Auth.auth().currentUser?.uid ? toId : fromId
    }
    
    init(dictionary: [String: Any]) {
        super.init()
        text = dictionary["text"] as? String
        toId = dictionary["toId"] as? String
        fromId = dictionary["fromId"] as? String
        timeStamp = dictionary["timeStamp"] as? String
    
        imageUrl = dictionary["imageUrl"] as? String
        imageWidth = dictionary["imageWidth"] as? NSNumber
        imageHeight = dictionary["imageHeight"] as? NSNumber
        
        videoUrl = dictionary["videoUrl"] as? String
        
        
    }
    
}
