//
//  NewMessageController.swift
//  GoChat
//
//  Created by Virtual on 12/24/17.
//  Copyright © 2017 Virtual. All rights reserved.
//

import UIKit
import Firebase

class NewMessageController: UITableViewController {
    
    let cellId = "cell"
    var users = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "cancel", style: .plain, target: self, action: #selector(NewMessageController.handleCancel))
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        
        fetchUser()
    }
    
    func fetchUser() {
        Database.database().reference().child("users").observe(.childAdded, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String : AnyObject] {
                let user = User()
                user.id = snapshot.key
                user.setValuesForKeys(dictionary)
                self.users.append(user)
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            }
            
            
            
        }, withCancel: nil)
    }
    
    func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        let user = users[indexPath.row]
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.email
        //cell.imageView?.image = UIImage(named: "user" )
        
        if let imageUrl = user.profileImageUrl {
            
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: imageUrl)
            
//            let url = URL(string: imageURL)
//            
//            URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, err) in
//                if err != nil {
//                    print(err.debugDescription)
//                    return
//                }
//                
//                DispatchQueue.main.async {
//                    cell.profileImageView.image = UIImage(data: data!)
//                    
//                }
//                
//            }).resume()
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    var messageController: MessageController?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true) {
            
            let user = self.users[indexPath.row]
        
            self.messageController?.showChatControllerForUser(user: user)
        }
    }
    
    
}

