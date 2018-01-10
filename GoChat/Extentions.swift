//
//  Extentions.swift
//  GoChat
//
//  Created by Virtual on 12/26/17.
//  Copyright © 2017 Virtual. All rights reserved.
//

import UIKit

let imageCache = NSCache<AnyObject, AnyObject>()

extension UIImageView {
    
    func loadImageUsingCacheWithUrlString(urlString: String) {
        
        self.image = nil
        
        let url = URL(string: urlString)
        
        //check cache for image first
        if let cacheImage = imageCache.object(forKey: urlString as AnyObject){
            self.image = cacheImage as? UIImage
            return
        }
        
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, err) in
            if err != nil {
                print(err.debugDescription)
                return
            }
            
            DispatchQueue.main.async {
                
                if let downloadedImage = UIImage(data: data!) {
                    imageCache.setObject(downloadedImage, forKey: urlString as AnyObject)
                    self.image = downloadedImage
                    
                }
                
                
            }
            
        }).resume()

        
    }
    

    
}
