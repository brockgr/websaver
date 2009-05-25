//
//  WebSaverView.m
//
//    WebSaver - A web screen-saver for MacOS-X
//    Copyright (C) 2008 Gavin Brock http://brock-family.org/gavin
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

// Cheesy Debugging toggle
#define DebugLog //
//#define DebugLog NSLog


#import "WebSaverView.h"

static NSString * const MyModuleName = @"org.brock-family.WebSaver";
static NSString * upArrow, *downArrow, *leftArrow, *rightArrow;

@implementation WebSaverView

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
	DebugLog(@"webView:didStartProvisionalLoadForFrame: %@", frame);
}

- (void)webView:(WebView *)sender didCommitLoadForFrame:(WebFrame *)frame
{
	DebugLog(@"webView:didCommitLoadForFrame");
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	DebugLog(@"webView:didFailLoadWithError: %@", error);
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	DebugLog(@"webView:didFailProvisionalLoadWithError: %@", error);
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	DebugLog(@"webView:didFinishLoadForFrame");
}

- (void)webView:(WebView *)sender didReceiveIcon:(NSImage *)image forFrame:(WebFrame *)frame
{
	DebugLog(@"webView:didReceiveIcon");
}

- (void)webView:(WebView *)sender serverRedirectedForDataSource:(WebFrame *)frame
{
	DebugLog(@"webView:serverRedirectedForDataSource");
}

- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame
{
	NSLog(@"webView:didReceiveTitle: %@", title);
}



- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
	DebugLog(@"webView:initWithFrame isPreview:%d", isPreview);
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
	
		sms_type = detect_sms();
		if (sms_type) {
			unichar ua = NSUpArrowFunctionKey;
			unichar da = NSDownArrowFunctionKey;
			unichar la = NSLeftArrowFunctionKey;
			unichar ra = NSRightArrowFunctionKey;
			upArrow    = [[NSString alloc] initWithCharacters:&ua length:1];
			downArrow  = [[NSString alloc] initWithCharacters:&da length:1];
			leftArrow  = [[NSString alloc] initWithCharacters:&la length:1];
			rightArrow = [[NSString alloc] initWithCharacters:&ra length:1];	
		}

		ScreenSaverDefaults *defaults;
		defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];
		[defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys: 
			@"http://www.apple.com/",  @"URL",
			@"NO",                     @"EnableReload",
			@"300",                    @"ReloadTime",
			@"NO",                     @"EnableSMS",
			nil ]];
		
		[self setAnimationTimeInterval:0.5];
		
		saverURLString = [defaults stringForKey:@"URL"];
		DebugLog(@"URL: %@", saverURLString);
		
		enableReloadBool = [defaults boolForKey:@"EnableReload"];
		DebugLog(@"Will Reload: %d", enableReloadBool);
		
		reloadTimeFloat = [defaults floatForKey:@"ReloadTime"];
		DebugLog(@"Reload Time: %d", reloadTimeFloat);

		enableSMSBool = [defaults boolForKey:@"EnableSMS"];
		DebugLog(@"Will use SMS: %d", enableSMSBool);

		webView = [[WebView alloc] initWithFrame:frame];
		[webView setDrawsBackground:NO];

		if (isPreview) {
			[self scaleUnitSquareToSize:NSMakeSize( 0.25, 0.25 )];
		}

		[webView setFrameLoadDelegate:self];
		
		[self addSubview:webView];

	}

    return self;
}

- (void)setFrame:(NSRect)frameRect
{
	DebugLog(@"NSView:setFrame");
	//DebugLog(@"frameRect %d,%d %dx%d\n", frameRect.origin.x, frameRect.origin.y, frameRect.size.width, frameRect.size.height);
	[super setFrame:frameRect];
	[webView setFrame:frameRect];	
	[webView setFrameSize:[webView convertSize:frameRect.size fromView:nil]];
}


- (void)startAnimation
{
	DebugLog(@"webView:startAnimation");
    [super startAnimation];

	// Calibrate 'natural' positon with 20 readings
	if (enableSMSBool && sms_type) {
		int loop;	
		for(loop = 0; loop < 20; loop++) {
			int x, y, z;
			if (read_sms_scaled(sms_type, &x, &y, &z)) {
				avgx = avgx + x;
				avgy = avgy + y;
				avgz = avgz + z;
			}
		}
		avgx = avgx / 20;
		avgy = avgy / 20;
		avgz = avgz / 20; 
		DebugLog(@"SMS Average - x = %d, y = %d, z = %d", avgx, avgy, avgz);
	}

	// Reload the page and reset load time 
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:saverURLString]]];
	lastLoad = [[NSDate alloc] init];
	NSLog(@"reloaded %@",[lastLoad description]);

}

- (void)stopAnimation
{
	DebugLog(@"webView:stopAnimation");
	
	// Reload the page and reset load time 
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:"]]];
	lastLoad = [[NSDate alloc] init];
	DebugLog(@"reloaded %@",[lastLoad description]);

    [super stopAnimation];
}

/*
- (void)drawRect:(NSRect)rect
{
	// TOO VERBOSE // DebugLog(@"webView:drawRect");
	[super drawRect:rect];
}
*/

- (void)doKeyUp:(NSTimer*)theTimer {
	//DebugLog(@"doKeyUp");
	[[NSApplication sharedApplication] sendEvent:[NSEvent keyEventWithType:NSKeyUp 
		location:      NSMakePoint(1,1)
		modifierFlags: 0
		timestamp:     [[NSDate date] timeIntervalSinceReferenceDate]
		windowNumber:  [[self window] windowNumber] 
		context:       [NSGraphicsContext currentContext] 
		characters:    [theTimer userInfo]
		charactersIgnoringModifiers:[theTimer userInfo]
		isARepeat:     NO 
		keyCode:       0]];
}


- (void)doKeyDown:(NSTimer*)theTimer {
	//DebugLog(@"doKeyDown");
	[[NSApplication sharedApplication] sendEvent:[NSEvent keyEventWithType:NSKeyDown 
		location:      NSMakePoint(1,1)
		modifierFlags: 0
		timestamp:     [[NSDate date] timeIntervalSinceReferenceDate]
		windowNumber:  [[self window] windowNumber] 
		context:       [NSGraphicsContext currentContext] 
		characters:    [theTimer userInfo]
		charactersIgnoringModifiers:[theTimer userInfo]
		isARepeat:     NO 
		keyCode:      0]];
}


- (void)animateOneFrame
{
	// TOO VERBOSE // DebugLog(@"webView:animateOneFrame");
	if (enableReloadBool) {
		// DebugLog(@"time %f", [lastLoad timeIntervalSinceNow]);
		if (reloadTimeFloat + [lastLoad timeIntervalSinceNow] < 0) {
			[[webView mainFrame] reload];
			[lastLoad dealloc];
			lastLoad = [[NSDate alloc] init];
			DebugLog(@"reloaded %@",[lastLoad description]);
		}
	}
		
	if (enableSMSBool && sms_type) {
		int x,y,z;
		if (read_sms_scaled(sms_type, &x, &y, &z)) {
			//DebugLog(@"average - x = %d, y = %d, z = %d     Current Reading:  x = %d, y = %d, z = %d", avgx, avgy, avgz, x, y, z);
	
			int cx = avgx - x;
			int cy = avgy - y;
		
			if (abs(cx) > abs(cy)) {
				if(cx > 30) {
					DebugLog(@"SMS Send Right Cursor");
					[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)0 target:self selector:@selector(doKeyDown:) userInfo:rightArrow repeats:NO];
					[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval).05 target:self selector:@selector(doKeyUp:) userInfo:rightArrow repeats:NO];
				} else if(cx < -30) {
					DebugLog(@"SMS Send Left Cursor");
					[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)0 target:self selector:@selector(doKeyDown:) userInfo:leftArrow repeats:NO];
					[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval).05 target:self selector:@selector(doKeyUp:) userInfo:leftArrow repeats:NO];
				}
			} else {
				if(cy > 30) {
					DebugLog(@"SMS Send Up Cursor");
					[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)0 target:self selector:@selector(doKeyDown:) userInfo:upArrow repeats:NO];
					[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval).05 target:self selector:@selector(doKeyUp:) userInfo:upArrow repeats:NO];
				} else if(cy < -30) {
					DebugLog(@"SMS Send Down Cursor");
					[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)0 target:self selector:@selector(doKeyDown:) userInfo:downArrow repeats:NO];
					[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval).5 target:self selector:@selector(doKeyUp:) userInfo:downArrow repeats:NO];
				}	
			}
		}
	}
    return;
}



- (BOOL)hasConfigureSheet
{
	DebugLog(@"webView:hasConfigureSheet");
    return YES;
}

- (NSWindow*)configureSheet
{
	DebugLog(@"webView:configureSheet");

	
	if (!configSheet) { 
		if (![NSBundle loadNibNamed:@"ConfigureSheet" owner:self]) {
			NSLog( @"Failed to load configure sheet." ); 
			NSBeep(); 
		} 
	}

	NSDictionary *infoDictionary;
	infoDictionary = [[NSBundle bundleForClass:[self class]] infoDictionary];
	NSString *versionString;
	versionString = [infoDictionary objectForKey:@"CFBundleVersion"];

	[versionLabel setStringValue:versionString];
	[saverURL setStringValue:saverURLString];
	[enableReload setState:enableReloadBool];
	[reloadTime selectItemWithTag:reloadTimeFloat];
	[enableSMS setState:enableSMSBool];
	[reloadTime setEnabled:[enableReload state]];
	[enableSMS setEnabled:sms_type ? true : false];

	return configSheet;
}


- (IBAction)enableClick:(id)sender
{
	DebugLog(@"IBAction:enableClick");
	[reloadTime setEnabled:[enableReload state]];
}


- (IBAction)cancelClick:(id)sender
{
	DebugLog(@"IBAction:cancelClick");
	[[NSApplication sharedApplication] endSheet:configSheet];
}


- (IBAction)okClick:(id)sender
{
	DebugLog(@"IBAction:okClick");

	// Check what the user set
	saverURLString = [saverURL stringValue];
	NSLog(@"Set URL: %@", saverURLString);
	enableReloadBool = [enableReload state];
	NSLog(@"Set Will Reload: %d", enableReloadBool);
	reloadTimeFloat = [[reloadTime selectedItem] tag];
	NSLog(@"Set Reload Time: %d", reloadTimeFloat);
	enableSMSBool = [enableSMS state];
	NSLog(@"Set Use SMS: %d", enableSMSBool);


	// Save the Settings
	ScreenSaverDefaults *defaults;
	defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];
	[defaults setObject:saverURLString  forKey:@"URL"];
	[defaults setBool:enableReloadBool  forKey:@"EnableReload"];
	[defaults setFloat:reloadTimeFloat  forKey:@"ReloadTime"];
	[defaults setBool:enableSMSBool  forKey:@"EnableSMS"];
	[defaults synchronize];
	
	// Reload the page and reset load time 
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:saverURLString]]];
	lastLoad = [[NSDate alloc] init];
	DebugLog(@"reloaded %@",[lastLoad description]);

	// Close the window
	[[NSApplication sharedApplication] endSheet:configSheet];
}

@end
