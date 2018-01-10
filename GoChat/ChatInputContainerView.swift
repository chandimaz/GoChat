//
//  ChatInputContainerView.swift
//  GoChat
//
//  Created by Virtual on 1/8/18.
//  Copyright © 2018 Virtual. All rights reserved.
//

import UIKit

class ChatInputContainerView: UIView , UITextFieldDelegate {
    
    var chatLogController: ChatLogController? {
        didSet{
           sendButton.addTarget(chatLogController, action: #selector(ChatLogController.handleSend) , for: .touchUpInside)
            
           uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: chatLogController, action: #selector(ChatLogController.handleUploadTap)))
        }
    }
    
    lazy var chatBox: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Type a message..."
        tf.delegate = self
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    let sendButton: UIButton = {
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        return sendButton
    }()
    let uploadImageView: UIImageView = {
        let uploadImageView = UIImageView()
        uploadImageView.image = #imageLiteral(resourceName: "addimage_icon")
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        uploadImageView.contentMode = .scaleAspectFill
        uploadImageView.isUserInteractionEnabled = true
        return uploadImageView
    }()
    
    let separatorView: UIView = {
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor.gray
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        return separatorView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        
        addSubview(self.chatBox)
        addSubview(uploadImageView)
        addSubview(sendButton)
        addSubview(separatorView)
        
        sendButton.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        sendButton.topAnchor.constraint(equalTo: topAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        //x,y,w,h
        uploadImageView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        
        //constraints x,y,w,h
        self.chatBox.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor, constant: 8).isActive = true
        self.chatBox.topAnchor.constraint(equalTo: topAnchor).isActive = true
        self.chatBox.rightAnchor.constraint(equalTo: sendButton.leftAnchor, constant: -8).isActive = true
        self.chatBox.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        //constraints x,y,w,h
        separatorView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        separatorView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        separatorView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        separatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        chatLogController?.handleSend()
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
