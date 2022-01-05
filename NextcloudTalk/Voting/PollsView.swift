//
//  PollsView.swift
//  NextcloudTalk
//
//  Created by StevalbertS on 28/12/2021.
//

import SwiftUI
import UIKit

//extension UINavigationController {
//    var rootViewController: UIViewController? {
//        return viewControllers.first
//    }
//}
//
//let navigationController = UINavigationController()

//NSString *userToken = [[NCKeyChainController sharedInstance] tokenForAccountId:account.accountId];
//NSString *authStr = [NSString stringWithFormat:@"%@:%@", account.userId, userToken];
//NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
//NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:0]];
//NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:URLString]];
//[urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];

//struct LandmarksApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}

@available(iOS 14.0, *)
struct PollsView: View {
    
    @State var votes = [Vote]()
    
    @Environment(\.presentationMode) var presentation

    var body: some View {
        
//        Text("")
//            .navigationTitle("Vote")
//            .navigationBarItems(
//                leading: Button(
//                    action: {
//                        self.presentation.wrappedValue.dismiss()
//
//                        print("Dismiss....")
//                    },
//                    label: {
//                        Text("Cancel")
//                    }
//                )
//            )
        
//        NavigationView {
//                    Text("Sheet")
//                        .toolbar {
//                            Button("Done") {
//                                self.presentation.wrappedValue.dismiss()
//                            }
//                        }
//                }
        
        Button {
            print("Button pressed")
            AuthClass.isValidUer(reasonString: "Voter verification") {(isSuccess, stringValue) in
                
                if isSuccess
                {
                    print("evaluating...... successfully completed")
                }
                else
                {
                    print("evaluating...... failed to recognise user \n reason = \(stringValue?.description ?? "invalid")")
                }
                
            }
        } label: {
            Text("Click to request OTP")
                .padding(12)
        }
        .contentShape(Rectangle())
        .padding(.all, 12)
                  .background(Color.yellow)
                  .foregroundColor(Color.black)
                  .cornerRadius(25)
        
        
        
        Text("Hello, world!")
                    .padding()
                    .onAppear() {
                        print("It came")
        
                        print("Values are here")
                        // user account
                        var account = TalkAccount()
                        let db = NCDatabaseManager()
                        account = db.activeAccount()

                        let api = NCAPIController()
                        

                        
                        
                        api.getPolls(account) { response, error in
                          
                            print("Response: \(String(describing: response))")
                            
                            if(error != nil){
                                print("Error: \(String(describing: error))")
                            }

                        }.resume()
                        
                        
                        
//                        api.getPolls(account, withCompletionBlock: { [AnyHashable : Any]?, Error? in
//
//                        }).resume()
//
                        
                        
                        
                        
                        // room session as! RequestCompletionBlock
//                        let room = NCRoom()
//                        let roomM = NCChatViewController()

//                        NCRoom *room = _callViewController.room;

//                        NCRoom *room = [[NCRoomsManager sharedInstance] roomWithToken:_room.token forAccountId:activeAccount.accountId];
                        
//                        let user = NCUser()
//                        let call = NCCallController()
//                        print("Account: \(String(describing: account))")
                        print("UserId: \(String(describing: account.userId))")
//                        print("User: \(String(describing: user.userId))")
//                        print("Room: \(String(describing: room.token))")
                        
//                        print(room.token)
//                        VotingAPI().loadData { (votes) in
//                            self.votes = votes
//                        }
                    }
                    
    }
}


@available(iOS 14.0, *)
struct OtpView: View {
    var body: some View{
        Text("Otp")
    }
}


@available(iOS 14.0, *)
struct PollsView_Previews: PreviewProvider {
    static var previews: some View {
        PollsView()
    }
}
