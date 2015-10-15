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
    Input input;
	NSString *temporaryURL;
}

@property UIWebView *webview;
@property (strong) CADisplayLink *link;
@property (strong, nonatomic) GCController *controller;
@property BOOL cursorMode;
@property CGPoint lastTouchLocation;


@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	cursorView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
	cursorView.center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), CGRectGetMidY([UIScreen mainScreen].bounds));
    cursorView.image = [UIImage imageNamed:@"Cursor"];
    cursorView.backgroundColor = [UIColor clearColor];
	cursorView.hidden = YES;
    
	
	self.webview = [[UIWebView alloc] initWithFrame:[UIScreen mainScreen].bounds];
	[self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.apple.com"]]];
	
	[self.view addSubview:self.webview];
	[self.view addSubview:cursorView];
	

	self.webview.scrollView.bounces = YES;
	self.webview.scrollView.panGestureRecognizer.allowedTouchTypes = @[ @(UITouchTypeIndirect) ];
	
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
            [self toggleMode];
        }
        else
        {
            /* Gross. */
            CGPoint point = [self.webview convertPoint:cursorView.frame.origin toView:nil];
            [self.webview stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.elementFromPoint(%i, %i).click()", (int)point.x, (int)point.y]];
        
            [self toggleMode];
        }
	}
	
	else if (presses.anyObject.type == UIPressTypePlayPause)
	{
		UIAlertController *alertController = [UIAlertController
											  alertControllerWithTitle:@"Enter URL:"
											  message:@""
											  preferredStyle:UIAlertControllerStyleAlert];
		
		[alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
		 {
			 textField.keyboardType = UIKeyboardTypeURL;
			 textField.placeholder = @"www.apple.com";
			 [textField addTarget:self
						   action:@selector(alertTextFieldDidChange:)
				 forControlEvents:UIControlEventEditingChanged];

		 }];
		
		UIAlertAction *okAction = [UIAlertAction
								   actionWithTitle:@"GO"
								   style:UIAlertActionStyleDefault
								   handler:^(UIAlertAction *action)
								   {
									   [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@", temporaryURL]]]];
									   temporaryURL = nil;
								   }];
		
		[alertController addAction:okAction];
		
		[self presentViewController:alertController animated:YES completion:nil];

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
