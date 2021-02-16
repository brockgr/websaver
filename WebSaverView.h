//
//  WebSaverView.h
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

#import <ScreenSaver/ScreenSaver.h>
#import <WebKit/WebKit.h>
#include "unimotion.h"


@interface WebSaverView : ScreenSaverView 
{
    WKWebView *webView;
	NSDate *lastLoad;
	
	// Motion Sensor Related
	int sms_type, avgx, avgy, avgz;
    
	IBOutlet id configSheet;

	IBOutlet id versionLabel;

	IBOutlet NSTextField *saverURL;
	NSString *saverURLString;
	
	IBOutlet id enableReload;
	bool enableReloadBool;

	IBOutlet NSPopUpButton *reloadTime;
	long reloadTimeFloat;
	
	IBOutlet id enableSMS;
	bool enableSMSBool;

    IBOutlet id enableMultiMonitor;
	bool enableMultiMonitorBool;

}
@end
