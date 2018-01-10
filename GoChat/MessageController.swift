//
//  ViewController.swift
//  GoChat
//
//  Created by Virtual on 12/22/17.
//  Copyright © 2017 Virtual. All rights reserved.
//

import UIKit
import Firebase
//import FirebaseDatabase
//import FirebaseStorage
//import FirebaseAuth

class MessageController: UITableViewController {
    
    let cellId = "cellId"

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
       checkUserIsLogged()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(MessageController.logoutHandler))
        
        //let image = UIImage(named: "newMsg")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "New", style: .plain, target: self, action: #selector(MessageController.handleNewMessage))
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        //observeMessages()
        tableView.allowsMultipleSelectionDuringEditing = true
        
        
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let message = self.messages[indexPath.row]
        
        if let chatPartnerId = message.chatPartnerId() {
            Database.database().reference().child("user-messages").child(uid).child(chatPartnerId).removeValue(completionBlock: { (error, ref) in
                if error != nil {
                    print("message deletion didnt complete: \(error)")
                }
                
                self.messageDictionary.removeValue(forKey: chatPartnerId)
                self.attemptReloadOfTable()
            })
        }
        
        
    }
    
    func observeUserMessages() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let ref = Database.database().reference().child("user-messages").child(uid)
        ref.observe(.childAdded, with: { (snapshot) in
            
            
            let userId = snapshot.key
            
            Database.database().reference().child("user-messages").child(uid).child(userId).observe(.childAdded, with: { (snapshot) in
                
                let messageId = snapshot.key
                self.fetchMessageWithMessageId(messageId: messageId)
                
            
            }, withCancel: nil)
            
            
            
            
                    }, withCancel: nil)
        
        ref.observe(.childRemoved, with: { (snapshot) in
           self.messageDictionary.removeValue(forKey: snapshot.key)
           self.attemptReloadOfTable()
        }, withCancel: nil)
    }
    
    private func fetchMessageWithMessageId(messageId: String){
        let messageRefference = Database.database().reference().child("messages").child(messageId)
        messageRefference.observeSingleEvent(of: .value, with: { (snapshot) in
            
            //make the messageMenu
            if let dictionary = snapshot.value {
                let message = Message(dictionary: dictionary as! [String : Any])
                
                //self.messages.append(message)
                
                if let chatPartnerId = message.chatPartnerId() {
                    self.messageDictionary[chatPartnerId] = message
                    
                }
                
                self.attemptReloadOfTable()
                
            }
            
            
        }, withCancel: nil)

    }
    
    var timer: Timer?
    private func attemptReloadOfTable() {
        self.timer?.invalidate()
        //print("timer stoped")
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
        //print("timer started")    
    }
    
    
    
    func handleReloadTable() {
        
        self.messages = Array(self.messageDictionary.values)
        self.messages.sort(by: { (message1, message2) -> Bool in
            return Double(message1.timeStamp!)! > Double(message2.timeStamp!)!
        })
        
        DispatchQueue.main.async {
            //print("reload Table")
            self.tableView.reloadData()
        }
    }
    
    var messages = [Message]()
    var messageDictionary = [String : Message]()
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        let message = messages[indexPath.row]
        cell.message = message
        
        
       // cell.detailTextLabel?.text = message.toId
        return cell
        
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        //print(message.text,message.fromId,message.toId)
        guard let chatPartnerId = message.chatPartnerId() else {
            return
       }
       let ref = Database.database().reference().child("users").child(chatPartnerId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            //print(snapshot)
           guard let dictionary = snapshot.value  else {
                return
            }
        
           let user = User()
            user.id = chatPartnerId
            user.setValuesForKeys(dictionary as! [String : Any])
            self.showChatControllerForUser(user: user)
        }, withCancel: nil)
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    func handleNewMessage() {
        let newMessageController = NewMessageController()
        newMessageController.messageController = self
        let navigationController = UINavigationController(rootViewController: newMessageController)
        present(navigationController, animated: true, completion: nil)
    }
    
    
    func checkUserIsLogged() {
        
        if Auth.auth().currentUser?.uid == nil {
            perform(#selector(MessageController.logoutHandler), with: nil, afterDelay: 0)
        }else {
            fetchUserAndSetupNavigationBarTitle()
            
        }
    }
    
    func fetchUserAndSetupNavigationBarTitle() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String : Any] {
                
                let user = User()
                user.setValuesForKeys(dictionary)
                self.setupNavBarWithUser(user: user)
            }
            
        }, withCancel: nil)
        
        
    }
    
    func setupNavBarWithUser(user: User) {
        
        messages.removeAll()
        messageDictionary.removeAll()
        tableView.reloadData()
        
        observeUserMessages()
        
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        //titleView.backgroundColor = UIColor.red
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleView.addSubview(containerView)
        
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.layer.masksToBounds = true
        if let profileUrl = user.profileImageUrl {
            profileImageView.loadImageUsingCacheWithUrlString(urlString: profileUrl)
        }
        containerView.addSubview(profileImageView)
        
        //constraints x,y width, height
        profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        let nameLabel: UILabel = {
            let nl = UILabel()
            nl.text = user.name
            nl.translatesAutoresizingMaskIntoConstraints = false
            return nl
        }()
        
        containerView.addSubview(nameLabel)
        
        //constraints x,y,width,height
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        
        containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        
//        titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MessageController.showChatController)))
        self.navigationItem.titleView = titleView
        
    }
    
    func showChatControllerForUser(user: User) {
        let chatController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
    chatController.user = user
        navigationController?.pushViewController(chatController, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .default
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    
    
    func logoutHandler(){
        do {
        try Auth.auth().signOut()
        } catch let err {
            print(err)
        }
        
        let loginController = LoginController()
        loginController.messageController = self
        
        present(loginController, animated: true, completion: nil)
        
    }
    
    

    
}

extension UIColor {
    
    convenience init(r: CGFloat , g: CGFloat , b: CGFloat){
        self.init(red: r/255 , green: g/255 , blue: b/255 , alpha: 1)
    }
}

