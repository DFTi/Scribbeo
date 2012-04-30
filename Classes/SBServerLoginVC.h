//
//  SBServerLoginVC.h
//  SBServerLogin
//
//  Created by Zachry Thayer on 4/19/12.
//  Copyright (c) 2012 Zachry Thayer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SBServerLoginVC : UIViewController<NSURLConnectionDelegate, UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UIView       *serverInputView;
@property (strong, nonatomic) IBOutlet UITextField  *serverIPInput;
@property (strong, nonatomic) IBOutlet UITextField  *serverPortInput;

@property (strong, nonatomic) IBOutlet UIView       *loginInputView;
@property (strong, nonatomic) IBOutlet UITextField  *usernameInput;
@property (strong, nonatomic) IBOutlet UITextField  *passwordInput;

@property (strong, nonatomic) IBOutlet UINavigationBar *navBar;
@property (strong, nonatomic)          NSString     *HTTPMethod;//"GET" or "POST"

+ (SBServerLoginVC*) serverLoginVCAccepted:(void (^)(void))acceptedBlock canceled:(void (^)(NSString* reason))canceledBlock;

@end
