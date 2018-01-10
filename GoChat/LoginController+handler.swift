//
//  LoginController+handler.swift
//  GoChat
//
//  Created by Virtual on 12/25/17.
//  Copyright © 2017 Virtual. All rights reserved.
//

import UIKit
import Firebase

extension LoginController: UIImagePickerControllerDelegate , UINavigationControllerDelegate {
    
    func handleRegister() {
        
        guard let email = emailTextField.text , let password = passwordTextField.text , let name = nameTextField.text else {
            print("type something on the text boxes")
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            
            if error != nil {
                print(error.debugDescription)
                return
            }
            
            guard let uid = user?.uid else {
                return
            }
            
            //successflly registered a user
            let imageName = NSUUID().uuidString
            let storageRef = Storage.storage().reference().child("Images").child("\(imageName).jpeg")
            
            if let uploadData = UIImageJPEGRepresentation(self.profileImageiew.image!, 0.1){
                storageRef.putData(uploadData, metadata: nil, completion: { (metadata, err) in
                    
                    if err != nil {
                        print(err.debugDescription)
                        return
                    }
                    
                    if let profileImageUrl = metadata?.downloadURL()?.absoluteString {
                        let values = ["name" : name , "email": email , "profileImageUrl": profileImageUrl]
                        self.registerUserIntoDatabaseWithUID(uid: uid , values: values as [String : AnyObject])                    }
                    
                    
                    
                })
            }
            
            
            
        }
    }
    
    private func registerUserIntoDatabaseWithUID(uid: String , values: [String: AnyObject]) {
        let ref = Database.database().reference()
        let usersReference = ref.child("users").child(uid)
        
        usersReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
            
            if err != nil {
                print(err.debugDescription)
                return
            }
            
            //self.messageController?.fetchUserAndSetupNavigationBarTitle()
            let user = User()
            user.setValuesForKeys(values)
            self.messageController?.setupNavBarWithUser(user: user)
            
            
            
            self.dismiss(animated: true, completion: nil)
            
        })
    }

    
    func handleSelectProfileImageView() {
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
            
        } else if let orginalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = orginalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            profileImageiew.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
}
