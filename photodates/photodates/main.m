//
//  main.m
//  photodates
//
//  Created by Chris Dzombak on 5/20/15.
//  Copyright (c) 2015 Chris Dzombak. All rights reserved.
//

@import Foundation;
#import <IOKit/pwr_mgt/IOPMLib.h>
#import "Photos.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        IOPMAssertionID powerAssertionID;
        IOReturn powerAssertionResult = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoIdleSleep, kIOPMAssertionLevelOn, CFSTR("photodate tool is runnng"), &powerAssertionID);

        if (powerAssertionResult != kIOReturnSuccess) {
            NSLog(@"Sleep assertion failed with error %@; continuing…", @(powerAssertionResult).stringValue);
        }

        PhotosApplication *photosApp = [SBApplication applicationWithBundleIdentifier:@"com.apple.Photos"];
        NSArray *items = photosApp.selection;

        if (items.count == 0) {
            NSLog(@"You must select photos in Photos.app before running photodates.");
            return 1;
        }

        NSDateFormatter *parser = [[NSDateFormatter alloc] init];
        parser.dateFormat = @"YYYY-MM-dd HH.mm.ss";

        NSDate *startTime = [NSDate date];
        NSUInteger itemN = 0;

        for (PhotosMediaItem *item in items) {
            ++itemN;

            if (itemN > 1) {
                NSTimeInterval timePerItem = [startTime timeIntervalSinceNow]*-1.0 / itemN;
                NSTimeInterval timeRemaining = timePerItem * (items.count - itemN + 1);
                double minutesRemaining = timeRemaining / 60.0;
                NSLog(@"%lu of %lu; %1.0f seconds (%1.0f minutes) remaining", itemN, items.count, timeRemaining, minutesRemaining);
            }

            NSString *filename = item.filename;
            while (!filename) {
                filename = item.filename;
            }

            NSLog(@"Filename: %@", filename);

            NSString *nameToParse = [filename stringByDeletingPathExtension];
            if ([nameToParse hasSuffix:@"-1"] || [nameToParse hasSuffix:@"-2"] || [nameToParse hasSuffix:@"-3"]
                || [nameToParse hasSuffix:@"-4"] || [nameToParse hasSuffix:@"-5"] || [nameToParse hasSuffix:@"-6"]
                || [nameToParse hasSuffix:@"-7"] || [nameToParse hasSuffix:@"-8"] || [nameToParse hasSuffix:@"-9"]) {
                // Some of the Dropbox uploads have "-n" suffixes if there were multiple files with identical timestamps.
                nameToParse = [nameToParse substringToIndex:(nameToParse.length-2)];
            }

            NSDate *parsedDate = [parser dateFromString:nameToParse];

            if (parsedDate) {
                NSLog(@"Parsed '%@' and setting date: %@", nameToParse, parsedDate);
                while (![item.date isEqualToDate:parsedDate]) {
                    item.date = parsedDate;
                }
            }
            else {
                NSLog(@"Parsed '%@' into NOTHING", nameToParse);
            }
        }

        if (powerAssertionResult == kIOReturnSuccess) {
            IOPMAssertionRelease(powerAssertionID);
        }
    }
    return 0;
}
