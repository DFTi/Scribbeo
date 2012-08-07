//
//  SBServerLoginVC.m
//  SBServerLogin
//
//  Created by Zachry Thayer on 4/19/12.
//  Copyright (c) 2012 Zachry Thayer. All rights reserved.
//

#import "SBServerLoginVC.h"
#import <QuartzCore/QuartzCore.h>
#import "NSURLConnection+BlockPatch.h"
#import <dispatch/dispatch.h>

typedef void (^AcceptedBlock)(void);
typedef void (^CanceledBlock)(NSString*);


@interface SBServerLoginVC ()

- (void)serverLoginCanceled:(UIBarButtonItem*)barButtonItem;
- (void)serverLoginAttempt:(UIBarButtonItem*)barButtonItem;

@property (readwrite, copy) AcceptedBlock _acceptedBlock;
@property (readwrite, copy) CanceledBlock _canceledBlock;

@property (nonatomic, strong) UINavigationItem *navItem;

@end


//#ifdef DEBUG
//@interface NSURLRequest (DummyInterface)
//+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
//+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
//@end
//#endif

@implementation SBServerLoginVC

@synthesize _acceptedBlock;
@synthesize _canceledBlock;

@synthesize navItem;

@synthesize serverInputView;
@synthesize serverIPInput;
@synthesize serverPortInput;
@synthesize loginInputView;
@synthesize usernameInput;
@synthesize passwordInput;
@synthesize navBar;
@synthesize HTTPMethod;


+ (SBServerLoginVC*) serverLoginVCAccepted:(void (^)(void))acceptedBlock canceled:(void (^)(NSString* reason))canceledBlock
{
    SBServerLoginVC *newServerLogin = [[SBServerLoginVC alloc] initWithNibName:@"SBServerLoginVC" bundle:nil];
    
    newServerLogin._acceptedBlock = acceptedBlock;
    newServerLogin._canceledBlock = canceledBlock;
    
    return newServerLogin;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.serverIPInput.text = [defaults stringForKey:@"ServerIP"];
    self.serverPortInput.text = [defaults stringForKey:@"ServerPort"];
    
    #ifdef DEBUG
    self.usernameInput.text = @"jon";
    self.passwordInput.text = @"jon";
    #endif
    
    
    self.title = @"Server login";
        
    self.navItem = [[UINavigationItem alloc] initWithTitle:@"Server Login"];
    
    [self.navBar pushNavigationItem:navItem animated:YES];
    
    self.navItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(serverLoginCanceled:)];
        
    self.navItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Login" style:UIBarButtonItemStyleDone target:self action:@selector(serverLoginAttempt:)];
    
    //make post default
    self.HTTPMethod = @"POST";
    
    //make it look better
    
    self.serverInputView.layer.cornerRadius = 8.f;
    self.serverInputView.clipsToBounds = YES;
    
    
    self.loginInputView.layer.cornerRadius = 8.f;
    self.loginInputView.clipsToBounds = YES;
    
    self.navBar.tintColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    self.modalPresentationStyle = UIModalPresentationFormSheet;
}

- (void)viewDidUnload
{
    [self setServerIPInput:nil];
    [self setServerPortInput:nil];
    [self setUsernameInput:nil];
    [self setPasswordInput:nil];
    [self setServerInputView:nil];
    [self setLoginInputView:nil];
    [self setHTTPMethod:nil];
    
    [self setNavBar:nil];
    [self setNavItem:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField == self.usernameInput || textField == self.passwordInput) 
    {
        
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [usernameInput becomeFirstResponder];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

#pragma mark - Events

- (void)serverLoginCanceled:(UIBarButtonItem*)barButtonItem
{
    self._canceledBlock(@"Canceled");
}

- (void)serverLoginAttempt:(UIBarButtonItem*)barButtonItem
{
    
    [self becomeFirstResponder];
    [self resignFirstResponder];
    
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@:%@/login", self.serverIPInput.text, self.serverPortInput.text]];
    
    NSMutableURLRequest* urlRequest = [NSMutableURLRequest requestWithURL:requestURL];
    
    [urlRequest setHTTPMethod:self.HTTPMethod];
    
    NSMutableString *POSTDataString = [NSMutableString stringWithFormat:@"username=%@", self.usernameInput.text];
    [POSTDataString appendFormat:@"&password=%@", self.passwordInput.text];
    
    NSData *POSTData = [NSData dataWithBytes:[POSTDataString UTF8String] length:[POSTDataString length]];
    [urlRequest setHTTPBody:POSTData];
    
    NSLog(@"\n%@\nUser:%@\nPass:%@", requestURL, self.usernameInput.text, self.passwordInput.text);
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
#ifdef DEBUG
    [NSURLRequest setAllowsAnyHTTPSCertificate:YES
                  forHost:[requestURL host]];
#endif
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:queue completionHandler:
     ^(NSURLResponse* response, NSData* data, NSError* error)
    {
        
        if (error)
        {
                        
            if (error.code == -1012)
            {
                __block SBServerLoginVC *blockSelf = self;
                
                dispatch_async(dispatch_get_main_queue(), ^(){
                    
                    //blockSelf._canceledBlock(@"Login failed, username or password incorrect");
                    
                    
                    blockSelf.navBar.tintColor = [UIColor colorWithRed:0.75 green:0.01 blue:0.01 alpha:1.0];
                    blockSelf.navItem.title = @"Bad username or password";
                    
                });

                return;
            }
            
            NSLog(@"ErrorCode:%i", error.code);
            
            UIAlertView *loginAlert = [[UIAlertView alloc] initWithTitle:@"Server Login Alert" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
            loginAlert.alertViewStyle = UIAlertViewStyleDefault;
            [loginAlert show]; 
            
            __block SBServerLoginVC *blockSelf = self;
            
            dispatch_async(dispatch_get_main_queue(), ^(){
                
                blockSelf._canceledBlock(error.localizedDescription);
                
            });
            
            return;
            
        }
        
        if (data)//Login success
        {
            
            #ifdef DEBUG
            
            NSLog(@"%s", (char*)[data bytes]);
            
            #endif
            
            __block SBServerLoginVC *blockSelf = self;
            
            dispatch_async(dispatch_get_main_queue(), ^(){

                blockSelf.navBar.tintColor = [UIColor colorWithWhite:0.15 alpha:1.0];
                blockSelf.navItem.title = @"Server login";
                
                blockSelf._acceptedBlock();
                
            });
            
            return;
        }
        
    }];
    
}

#pragma mark - NSURLConnectionDelegate

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    
}

@end
