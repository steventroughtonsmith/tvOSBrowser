//
//  ViewController.m
//  Browser
//
//  Created by Steven Troughton-Smith on 20/09/2015.
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
	UIView *cursorView;
	Input input;
	NSString *temporaryURL;
}

@property id webview;
@property (strong) CADisplayLink *link;
@property (strong, nonatomic) GCController *controller;
@property BOOL cursorMode;
@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	cursorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
	cursorView.center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), CGRectGetMidY([UIScreen mainScreen].bounds));
	cursorView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Cursor"]];
	cursorView.hidden = YES;
	
    
    Class UIWebViewClass = NSClassFromString(@"UIWebView");
    
	_webview = [[UIWebViewClass alloc] initWithFrame:[UIScreen mainScreen].bounds];
	[_webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.apple.com"]]];
	
	[self.view addSubview:_webview];
	[self.view addSubview:cursorView];
	
	self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateCursor)];
	[self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
	
	[_webview scrollView].bounces = YES;
	[_webview scrollView].panGestureRecognizer.allowedTouchTypes = @[ @(UITouchTypeIndirect) ];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupController) name:GCControllerDidConnectNotification object:nil];
}

-(void)toggleMode
{
	self.cursorMode = !self.cursorMode;
	
	if (self.cursorMode)
	{
		[_webview scrollView].scrollEnabled = NO;
        [_webview setUserInteractionEnabled:NO];
		cursorView.hidden = NO;
	}
	else
	{
		[_webview scrollView].scrollEnabled = YES;
        [_webview setUserInteractionEnabled:YES];
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
			[_webview goBack];
	}
	else if (presses.anyObject.type == UIPressTypeSelect)
	{
		/* Gross. */
		CGPoint point = [self.webview convertPoint:cursorView.frame.origin toView:nil];
		[_webview stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.elementFromPoint(%i, %i).click()", (int)point.x, (int)point.y]];
	}
	
	else if (presses.anyObject.type == UIPressTypePlayPause)
	{
		UIAlertController *alertController = [UIAlertController
											  alertControllerWithTitle:@"Enter Address"
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
								   actionWithTitle:@"OK"
								   style:UIAlertActionStyleDefault
								   handler:^(UIAlertAction *action)
								   {
									   [_webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@", temporaryURL]]]];
									   temporaryURL = nil;
								   }];
		
		[alertController addAction:okAction];
		
		[self presentViewController:alertController animated:YES completion:nil];

	}
	else if (presses.anyObject.type == UIPressTypeUpArrow)
	{
		[self toggleMode];
	}
}


#pragma mark - Cursor Input

-(void)setupController
{
	self.controller = [GCController controllers].firstObject;
	self.controller.microGamepad.dpad.valueChangedHandler = ^(GCControllerDirectionPad *pad, float x, float y) {
		input.x = x;
		input.y = -y;
	};
}

-(void)updateCursor
{
	CGFloat delta = 5.0;
	
	if (!self.cursorMode)
		return;
	
	if (input.x != 0)
	cursorView.transform = CGAffineTransformTranslate(cursorView.transform, pow(2,delta*fabs(input.x))*(input.x>0?1:-1), 0);
	
	if (input.y != 0)
		cursorView.transform = CGAffineTransformTranslate(cursorView.transform, 0, pow(2,delta*fabs(input.y))*(input.y>0?1:-1));

}

@end
