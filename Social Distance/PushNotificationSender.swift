


import Foundation
import UIKit


class PushNotificationSender {
    
    func sendPushNotification(to token: String, title: String, body: String) {
        let urlString = "https://fcm.googleapis.com/fcm/send"
        let url = NSURL(string: urlString)!
        let paramString: [String : Any] = ["to" : token,
                                           "notification" : ["title" : title, "body" : body, "badge": 1],
                                           "data" : ["user" : "test_id"]
        ]
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=AAAAhTItlho:APA91bHtrMdXn2Ueui90vCe3MFveGFoaY2c7XNnjVxpA4P7sAMQxTGyHtSMX1yNM328RSQWenzbPR0x3X6cpBhN52rVKbYJFmyEZ82WowMNxN11SJB3vxVlJS7e_HOVk617QhzdEw8NS", forHTTPHeaderField: "Authorization")
        let task =  URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in
            do {
                if let jsonData = data {
                    print("made it")
                    if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                        NSLog("Received data:\n\(jsonDataDict))")
                    }
                }
            } catch let err as NSError {
                print("her's the error")
                print(request)
                print(err.debugDescription)
            }
        }
        task.resume()
    }
    
}
