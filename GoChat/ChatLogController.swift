//
//  ChatLogController.swift
//  GoChat
//
//  Created by Virtual on 12/26/17.
//  Copyright © 2017 Virtual. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVFoundation

class ChatLogController: UICollectionViewController, UITextFieldDelegate , UICollectionViewDelegateFlowLayout , UIImagePickerControllerDelegate , UINavigationControllerDelegate {
    
    let cellId = "cellId"
    
    var user: User? {
        didSet{
            navigationItem.title = user?.name
            observeMessages()
        }
    }
    
    var messages = [Message](){
        didSet{
            //print("massage count is \(messages.count)")
        }
    }
    
    func observeMessages() {
        guard let uid = Auth.auth().currentUser?.uid , let toId = user?.id else {
            return
        }
        
        let userMessageRef = Database.database().reference().child("user-messages").child(uid).child(toId)
        userMessageRef.observe(.childAdded, with: { (snapshot) in
            //print(snapshot)
            let messageId = snapshot.key
            let messageRef = Database.database().reference().child("messages").child(messageId)
            messageRef.observeSingleEvent(of: .value, with: { (snapshot) in
                //print(snapshot)
                guard let dictionary = snapshot.value as? [String : Any] else {
                    return
                }
                
                self.messages.append(Message(dictionary: dictionary))
                
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                    //auto scrolling to the last message
                    let indexPath = NSIndexPath(item: self.messages.count - 1, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath as IndexPath, at: .bottom, animated: true)
                    
                    
                }
                
                
                
                
                
            }, withCancel: nil)
        }, withCancel: nil)
    }
    
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.backgroundColor = UIColor.white
        collectionView?.alwaysBounceVertical = true
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        //collectionView?.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        collectionView?.keyboardDismissMode = .interactive
        
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        
        setupKeyboardObservers()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    lazy var inputContainerView: ChatInputContainerView = {
        let chatInputContainerView = ChatInputContainerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        chatInputContainerView.chatLogController = self
        return chatInputContainerView
        //let containerView = UIView()
        //containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
        //containerView.backgroundColor = UIColor.white
        //containerView.addSubview(self.chatBox)
        
        
        
        
        //return containerView
    }()
    
    func handleUploadTap() {
        
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        imagePicker.mediaTypes = [kUTTypeImage as String , kUTTypeMovie as String]
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? URL{
            
            handleVideoForSelectedUrl(url: videoUrl)
            
        } else {
            
            handleImageSelectedForInfo(info: info)
        }
        
        
        dismiss(animated: true, completion: nil)
        
    }
    
    func handleVideoForSelectedUrl(url: URL) {
        
        let fileName = UUID().uuidString + ".mov"
        
        let uploadTask = Storage.storage().reference().child("message_movies").child(fileName).putFile(from: url, metadata: nil, completion: { (metadata, error) in
            
            if error != nil {
                print(error.debugDescription)
                return
            }
            
            
            
            if let videoUrl = metadata?.downloadURL()?.absoluteString {
                
                if let thumbnailImage = self.thumbnailImageForFileUrl(fileUrl: url) {
                    
                    self.uploadToFirebaseStroageUsingImage(image: thumbnailImage, completion: { (imageUrl) in
                        let propertries: [String: Any] = ["imageUrl": imageUrl, "imageWidth": thumbnailImage.size.width , "imageHeight": thumbnailImage.size.height , "videoUrl": videoUrl]
                        self.sendMessageWithProperties(properties: propertries)
                    })
                    
                }
                
                
            }
        })
        
        uploadTask.observe(.progress) { (snapshot) in
        
            if let statusOfTask = snapshot.progress?.totalUnitCount {
                self.navigationItem.title = String(statusOfTask)
            }
        }
        
        uploadTask.observe(.success) { (snapshot) in
            self.navigationItem.title = self.user?.name
        }
    }
    
    func thumbnailImageForFileUrl(fileUrl: URL) -> UIImage? {
        
        let asset = AVAsset(url: fileUrl)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
            let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(1, 60), actualTime: nil)
            return UIImage(cgImage: thumbnailCGImage)
        }catch let err {
            
            print(err)
        }
        
        return nil
        
        
    }
    
    func handleImageSelectedForInfo(info: [String: Any]){
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            selectedImageFromPicker = editedImage
        }else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            uploadToFirebaseStroageUsingImage(image: selectedImage, completion: { (imageUrl) in
                self.sendMessageWithImageUrl(imageUrl: imageUrl , image: selectedImage)            })
        }
        
    }
    
    func uploadToFirebaseStroageUsingImage(image: UIImage , completion: @escaping (_ imageUrl: String) -> ()) {
        
        let imageName = NSUUID().uuidString
        let ref = Storage.storage().reference().child("message_images").child(imageName)
        
        if let uploadData = UIImageJPEGRepresentation(image, 0.2) {
            
            ref.putData(uploadData, metadata: nil) { (metadata, error) in
                
                if error != nil {
                    print("Image Upload Failed")
                    return
                }
                
                if let imageUrl = metadata?.downloadURL()?.absoluteString {
                    completion(imageUrl)
                    
                }
            }
        }
        
        
    }
    
    private func sendMessageWithImageUrl(imageUrl: String , image: UIImage) {
        
        let properties =  ["imageUrl" : imageUrl , "imageWidth": image.size.width , "imageHeight": image.size.height] as [String : Any]
        
        sendMessageWithProperties(properties: properties)
        
    }
    
    override var inputAccessoryView: UIView? {
        get{
            return inputContainerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
    
    
    
    func setupKeyboardObservers() {
        //        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        //        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
    }
    
    func handleKeyboardDidShow() {
        
        if messages.count > 0 {
            let indexPath = NSIndexPath(item: self.messages.count - 1, section: 0)
            self.collectionView?.scrollToItem(at: indexPath as IndexPath, at: .top, animated: true)
        }
    }
    
    func handleKeyboardWillShow(notification: NSNotification) {
        let keyboardFrame = (notification.userInfo?["UIKeyboardFrameEndUserInfoKey"] as AnyObject).cgRectValue
        let keyboardDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! Double
        //print(keyboardFrame?.height , keyboardFrame?.width)
        containerViewBottomAnchor?.isActive = false
        containerViewBottomAnchor?.constant = -(keyboardFrame?.height)!
        containerViewBottomAnchor?.isActive = true
        
        UIView.animate(withDuration: keyboardDuration) {
            self.view.layoutIfNeeded()
        }
        
    }
    
    func handleKeyboardWillHide() {
        
        containerViewBottomAnchor?.isActive = false
        containerViewBottomAnchor?.constant = 0
        containerViewBottomAnchor?.isActive = true
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        cell.chatLogController = self
        
        let message = messages[indexPath.row]
        cell.message = message
        cell.textView.text = message.text
        
        setupCell(cell: cell, message: message)
        
        //modify cells width
        
        if let text = message.text {
            cell.bubblWidthAncher?.constant = estimateFrameForText(text: text).width + 32
            cell.textView.isHidden = false
        } else if message.imageUrl != nil {
            cell.bubblWidthAncher?.constant = 200
            cell.textView.isHidden = true
        }
        
        cell.playButton.isHidden = message.videoUrl == nil
        
        
        //cell.backgroundColor = UIColor.blue
        return cell
    }
    
    private func setupCell(cell: ChatMessageCell , message: Message) {
        
        if let profileImageUrl = self.user?.profileImageUrl {
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        if let messageImageUrl = message.imageUrl {
            cell.messageImageView.loadImageUsingCacheWithUrlString(urlString: messageImageUrl)
            cell.messageImageView.isHidden = false
            cell.backgroundColor = UIColor.clear
        }else {
            cell.messageImageView.isHidden = true
        }
        
        if message.fromId == Auth.auth().currentUser?.uid {
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = UIColor.white
            cell.profileImageView.isHidden = true
            
            cell.bubbleRightAnchor?.isActive = true
            cell.bubbleLeftAnchor?.isActive = false
            
        }else {
            cell.bubbleView.backgroundColor = UIColor(r: 240, g: 240, b: 240)
            cell.textView.textColor = UIColor.black
            cell.profileImageView.isHidden = false
            
            cell.bubbleRightAnchor?.isActive = false
            cell.bubbleLeftAnchor?.isActive = true
        }
    }
    
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80
        
        let message = messages[indexPath.row]
        
        if let text = message.text {
            height = estimateFrameForText(text: text).height + 20
        } else if let imageWidth = message.imageWidth?.floatValue , let imageHeight = message.imageHeight?.floatValue {
            height = CGFloat(imageHeight / imageWidth * 200)
        }
        
        let width = UIScreen.main.bounds.width
        
        return CGSize(width: width, height: height)
    }
    
    private func estimateFrameForText(text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    var containerViewBottomAnchor: NSLayoutConstraint?
    let containerView = UIView()
    
    
    
    func handleSend(){
        
        let properties = ["text": inputContainerView.chatBox.text]
        sendMessageWithProperties(properties: properties)
    }
    
    func sendMessageWithProperties(properties: [String: Any]) {
        
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        
        
        
        let toId = user!.id!
        let fromId = Auth.auth().currentUser!.uid
        let time = Date().timeIntervalSince1970
        let timeStamp = String(time)
        
        var values = ["toId": toId , "fromId": fromId , "timeStamp": timeStamp ] as [String : Any]
        
        properties.forEach({values[$0] = $1})
        
        //childRef.updateChildValues(values)
        childRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
            
            if error != nil {
                print(error.debugDescription)
                return
            }
            
            self.inputContainerView.chatBox.text = nil
            
            let userMessagesRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
            
            let messageId = childRef.key
            userMessagesRef.updateChildValues([messageId: 1])
            
            let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toId).child(fromId)
            recipientUserMessagesRef.updateChildValues([messageId: 1])
            
            
        })
        
        
        
    }
    
    var startingFrame: CGRect?
    var blackBackgroundView: UIView?
    var startingImageView: UIImageView?
    
    func performZoomForStatingImageView(startingImageView: UIImageView) {
        
        self.startingImageView = startingImageView
        startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
        startingImageView.isHidden = true
        
        let zoomingImageView = UIImageView(frame: startingFrame!)
        zoomingImageView.image = startingImageView.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
        
        if let keyWindow = UIApplication.shared.keyWindow {
            
            blackBackgroundView = UIView(frame: keyWindow.frame)
            blackBackgroundView?.backgroundColor = UIColor.black
            keyWindow.addSubview(blackBackgroundView!)
            blackBackgroundView?.alpha = 0
            
            keyWindow.addSubview(zoomingImageView)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                let height = startingImageView.frame.height / startingImageView.frame.width * keyWindow.frame.width
                self.blackBackgroundView?.alpha = 1
                self.inputContainerView.alpha = 0
                
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                zoomingImageView.center = keyWindow.center
                
            }, completion: { (bool) in
                //zoomOutImageView.removeFromSuperview()
            })
            
            
        }
        
    }
    
    func handleZoomOut(tapGesture: UITapGestureRecognizer) {
        
        if let zoomOutImageView = tapGesture.view {
            
            zoomOutImageView.layer.cornerRadius = 16
            zoomOutImageView.layer.masksToBounds = true
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                zoomOutImageView.frame = self.startingFrame!
                
                self.blackBackgroundView?.alpha = 0
                self.inputContainerView.alpha = 1
            }, completion: { (bool) in
                zoomOutImageView.removeFromSuperview()
                self.startingImageView?.isHidden = false
                self.blackBackgroundView?.removeFromSuperview()
            })
            
            
        }
        
    }
    
    
}
