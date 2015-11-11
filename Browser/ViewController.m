//
//  ViewController.m
//  Browser
//
//  Created by Steven Troughton-Smith on 20/09/2015.
//  Improved by Jip van Akker on 14/10/2015
//  Copyright © 2015 High Caffeine Content. All rights reserved.
//

#import "ViewController.h"
#import <GameController/GameController.h>

typedef struct _Input
{
    CGFloat x;
    CGFloat y;
} Input;


@interface ViewController ()
{
    UIImageView *cursorView;
    UIActivityIndicatorView *loadingSpinner;
    Input input;
    NSString *temporaryURL;
    NSString *requestURL;
}

@property UIWebView *webview;
@property (strong) CADisplayLink *link;
@property (strong, nonatomic) GCController *controller;
@property BOOL cursorMode;
@property BOOL inputViewVisible;
@property CGPoint lastTouchLocation;


@end

@implementation ViewController {
    UITapGestureRecognizer *tapRecognizer;
}
-(void) webViewDidStartLoad:(UIWebView *)webView {
    [loadingSpinner startAnimating];
    [self.view bringSubviewToFront:loadingSpinner];
}
-(void) webViewDidFinishLoad:(UIWebView *)webView {
    [loadingSpinner stopAnimating];
    [self.view bringSubviewToFront:loadingSpinner];
}
-(void)viewDidAppear:(BOOL)animated {
    loadingSpinner.center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), CGRectGetMidY([UIScreen mainScreen].bounds));
    if (_webview.request == nil) {
        [self requestURL];
    }
}
-(void)viewDidLoad {
    [super viewDidLoad];
    tapRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTap:)];
    tapRecognizer.numberOfTapsRequired = 2;
    tapRecognizer.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeSelect]];
    [self.view addGestureRecognizer:tapRecognizer];
    
    cursorView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
    cursorView.center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), CGRectGetMidY([UIScreen mainScreen].bounds));
    cursorView.image = [UIImage imageNamed:@"Cursor"];
    cursorView.backgroundColor = [UIColor clearColor];
    cursorView.hidden = YES;
    
    
    self.webview = [[UIWebView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    //[self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.google.com"]]];
    
    [self.view addSubview:self.webview];
    [self.view addSubview:cursorView];
    
    self.webview.delegate = self;
    self.webview.scrollView.bounces = YES;
    self.webview.scrollView.panGestureRecognizer.allowedTouchTypes = @[ @(UITouchTypeIndirect) ];
    loadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    loadingSpinner.center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), CGRectGetMidY([UIScreen mainScreen].bounds));
    loadingSpinner.tintColor = [UIColor blackColor];
    loadingSpinner.hidesWhenStopped = true;
    //[loadingSpinner startAnimating];
    [self.view addSubview:loadingSpinner];
    [self.view bringSubviewToFront:loadingSpinner];
    //ENABLE CURSOR MODE INITIALLY
    self.cursorMode = YES;
    self.webview.scrollView.scrollEnabled = NO;
    self.webview.userInteractionEnabled = NO;
    cursorView.hidden = NO;
}
-(void)handleTap:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self toggleMode];
    }
}
-(void)requestURL
{
    _inputViewVisible = true;
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Enter URL or Search Terms"
                                          message:@""
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
         textField.keyboardType = UIKeyboardTypeURL;
         textField.placeholder = @"Enter URL or Search Terms";
         [textField setReturnKeyType:UIReturnKeyDone];
         [textField addTarget:self
                       action:@selector(alertTextFieldDidChange:)
             forControlEvents:UIControlEventEditingChanged];
         [textField addTarget:self
                       action:@selector(alertTextFieldShouldReturn:)
             forControlEvents:UIControlEventEditingDidEnd];
         
     }];
    
    UIAlertAction *goAction = [UIAlertAction
                               actionWithTitle:@"Go To Website"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action)
                               {
                                   if ([temporaryURL containsString:@" "] || ![temporaryURL containsString:@"."]) {
                                       temporaryURL = [temporaryURL stringByReplacingOccurrencesOfString:@" " withString:@"+"];
                                       temporaryURL = [temporaryURL stringByReplacingOccurrencesOfString:@"." withString:@"+"];
                                       temporaryURL = [temporaryURL stringByReplacingOccurrencesOfString:@"++" withString:@"+"];
                                       temporaryURL = [temporaryURL stringByReplacingOccurrencesOfString:@"++" withString:@"+"];
                                       temporaryURL = [temporaryURL stringByReplacingOccurrencesOfString:@"++" withString:@"+"];
                                       temporaryURL = [temporaryURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                                       if (temporaryURL != nil) {
                                           [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.google.com/search?q=%@", temporaryURL]]]];
                                       }
                                       else {
                                           [self requestURL];
                                       }
                                       temporaryURL = nil;
                                   }
                                   else {
                                       if (temporaryURL != nil) {
                                           if ([temporaryURL containsString:@"http://"] || [temporaryURL containsString:@"https://"]) {
                                               [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", temporaryURL]]]];
                                               temporaryURL = nil;
                                           }
                                           else {
                                               [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@", temporaryURL]]]];
                                               temporaryURL = nil;
                                           }
                                       }
                                       else {
                                           [self requestURL];
                                       }
                                   }
                                   _inputViewVisible = false;
                                   
                               }];
    UIAlertAction *searchAction = [UIAlertAction
                                   actionWithTitle:@"Search Google"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       temporaryURL = [temporaryURL stringByReplacingOccurrencesOfString:@" " withString:@"+"];
                                       temporaryURL = [temporaryURL stringByReplacingOccurrencesOfString:@"." withString:@"+"];
                                       temporaryURL = [temporaryURL stringByReplacingOccurrencesOfString:@"++" withString:@"+"];
                                       temporaryURL = [temporaryURL stringByReplacingOccurrencesOfString:@"++" withString:@"+"];
                                       temporaryURL = [temporaryURL stringByReplacingOccurrencesOfString:@"++" withString:@"+"];
                                       temporaryURL = [temporaryURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                                       if (temporaryURL != nil) {
                                           [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.google.com/search?q=%@", temporaryURL]]]];
                                       }
                                       else {
                                           [self requestURL];
                                       }
                                       temporaryURL = nil;
                                       _inputViewVisible = false;
                                   }];
    UIAlertAction *reloadAction = [UIAlertAction
                                   actionWithTitle:@"Reload"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       [self.webview reload];
                                   }];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                   _inputViewVisible = false;
                                   }];
    [alertController addAction:goAction];
    [alertController addAction:searchAction];
    if (_webview.request != nil) {
        if (![_webview.request.URL.absoluteString  isEqual: @""]) {
            [alertController addAction:reloadAction];
            [alertController addAction:cancelAction];
        }
    }
    
    
    [self presentViewController:alertController animated:YES completion:nil];
    if (_webview.request == nil) {
        UITextField *loginTextField = alertController.textFields[0];
        [loginTextField becomeFirstResponder];
    }
    else if ([_webview.request.URL.absoluteString  isEqual: @""]) {
        UITextField *loginTextField = alertController.textFields[0];
        [loginTextField becomeFirstResponder];
    }
    
}
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    requestURL = request.URL.absoluteString;
    return YES;
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [loadingSpinner stopAnimating];
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Could Not Load Webpage"
                                          message:@""
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *searchAction = [UIAlertAction
                                   actionWithTitle:@"Search Google for This"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       if (requestURL != nil) {
                                           if ([requestURL length] > 1) {
                                               NSString *lastChar = [requestURL substringFromIndex: [requestURL length] - 1];
                                               if ([lastChar isEqualToString:@"/"]) {
                                                   NSString *newString = [requestURL substringToIndex:[requestURL length]-1];
                                                   requestURL = newString;
                                               }
                                           }
                                           requestURL = [requestURL stringByReplacingOccurrencesOfString:@"http://" withString:@""];
                                           requestURL = [requestURL stringByReplacingOccurrencesOfString:@"https://" withString:@"+"];
                                           [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.google.com/search?q=%@", requestURL]]]];
                                       }
                                       
                                   }];
    UIAlertAction *reloadAction = [UIAlertAction
                                   actionWithTitle:@"Reload"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       [self.webview reload];
                                   }];
    UIAlertAction *newurlAction = [UIAlertAction
                                   actionWithTitle:@"Enter URL"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       [self requestURL];
                                   }];
    if (requestURL != nil) {
        if ([requestURL length] > 1) {
            [alertController addAction:searchAction];
        }
    }
    if (_webview.request != nil) {
        if (![_webview.request.URL.absoluteString  isEqual: @""]) {
            [alertController addAction:reloadAction];
        }
        else {
            [alertController addAction:newurlAction];
        }
    }
    else {
        [alertController addAction:newurlAction];
    }
    
    
    [self presentViewController:alertController animated:YES completion:nil];
}
-(void)toggleMode
{
    self.cursorMode = !self.cursorMode;
    
    if (self.cursorMode)
    {
        self.webview.scrollView.scrollEnabled = NO;
        self.webview.userInteractionEnabled = NO;
        cursorView.hidden = NO;
    }
    else
    {
        self.webview.scrollView.scrollEnabled = YES;
        self.webview.userInteractionEnabled = YES;
        cursorView.hidden = YES;
    }
}
- (void)alertTextFieldShouldReturn:(UITextField *)sender
{
    /*
    UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
    if (alertController)
    {
        [alertController dismissViewControllerAnimated:true completion:nil];
        if ([temporaryURL containsString:@" "] || ![temporaryURL containsString:@"."]) {
            temporaryURL = [temporaryURL stringByReplacingOccurrencesOfString:@" " withString:@"+"];
            temporaryURL = [temporaryURL stringByReplacingOccurrencesOfString:@"." withString:@"+"];
            temporaryURL = [temporaryURL stringByReplacingOccurrencesOfString:@"++" withString:@"+"];
            temporaryURL = [temporaryURL stringByReplacingOccurrencesOfString:@"++" withString:@"+"];
            temporaryURL = [temporaryURL stringByReplacingOccurrencesOfString:@"++" withString:@"+"];
            temporaryURL = [temporaryURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            if (temporaryURL != nil) {
                [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.google.com/search?q=%@", temporaryURL]]]];
            }
            else {
                [self requestURL];
            }
            temporaryURL = nil;
        }
        else {
            if (temporaryURL != nil) {
                if ([temporaryURL containsString:@"http://"] || [temporaryURL containsString:@"https://"]) {
                    [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", temporaryURL]]]];
                    temporaryURL = nil;
                }
                else {
                    [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@", temporaryURL]]]];
                    temporaryURL = nil;
                }
            }
            else {
                [self requestURL];
            }
        }
        _inputViewVisible = false;
     
    }
     */
}
- (void)alertTextFieldDidChange:(UITextField *)sender
{
    UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
    if (alertController)
    {
        UITextField *urlField = alertController.textFields.firstObject;
        temporaryURL = urlField.text;
    }
}
-(void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
    
    if (presses.anyObject.type == UIPressTypeMenu)
    {
        if (self.presentedViewController)
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else
            [self.webview goBack];
    }
    else if (presses.anyObject.type == UIPressTypeUpArrow)
    {
        // Zoom testing (needs work) (requires old remote for up arrow)
        UIScrollView * sv = self.webview.scrollView;
        [sv setZoomScale:30];
    }
    else if (presses.anyObject.type == UIPressTypeDownArrow)
    {
    }
    else if (presses.anyObject.type == UIPressTypeSelect)
    {
        if(!self.cursorMode)
        {
            //[self toggleMode];
        }
        else
        {
            /* Gross. */
            CGPoint point = [self.webview convertPoint:cursorView.frame.origin toView:nil];
            [self.webview stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.elementFromPoint(%i, %i).click()", (int)point.x, (int)point.y]];
            
            //[self toggleMode];
        }
    }
    
    else if (presses.anyObject.type == UIPressTypePlayPause)
    {
        if (_inputViewVisible) {
            UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
            if (alertController)
            {
                [alertController dismissViewControllerAnimated:true completion:nil];
            }
            _inputViewVisible = NO;
            if (_webview.request == nil) {
                [self requestURL];
            }
            else if ([_webview.request.URL.absoluteString  isEqual: @""]) {
                [self requestURL];
            }
        }
        else {
           [self requestURL];
        }
        
        
    }
}


#pragma mark - Cursor Input

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.lastTouchLocation = CGPointMake(-1, -1);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches)
    {
        CGPoint location = [touch locationInView:self.webview];
        
        if(self.lastTouchLocation.x == -1 && self.lastTouchLocation.y == -1)
        {
            // Prevent cursor from recentering
            self.lastTouchLocation = location;
        }
        else
        {
            CGFloat xDiff = location.x - self.lastTouchLocation.x;
            CGFloat yDiff = location.y - self.lastTouchLocation.y;
            CGRect rect = cursorView.frame;
            
            if(rect.origin.x + xDiff >= 0 && rect.origin.x + xDiff <= 1920)
                rect.origin.x += xDiff;//location.x - self.startPos.x;//+= xDiff; //location.x;
            
            if(rect.origin.y + yDiff >= 0 && rect.origin.y + yDiff <= 1080)
                rect.origin.y += yDiff;//location.y - self.startPos.y;//+= yDiff; //location.y;
            
            cursorView.frame = rect;
            self.lastTouchLocation = location;
        }
        
        // We only use one touch, break the loop
        break;
    }
    
}



@end
