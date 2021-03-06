/* Copyright (c) 2008 Google Inc.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

//
//  GDataFeedContactGroup.m
//


#import "GDataFeedContactGroup.h"
#import "GDataEntryContact.h"
#import "GDataEntryContactGroup.h"
#import "GDataCategory.h"

@implementation GDataFeedContactGroup

+ (GDataFeedContactGroup *)contactGroupFeed {
  GDataFeedContactGroup *obj = [[[[self class] alloc] init] autorelease];

  [obj setNamespaces:[GDataEntryContact contactNamespaces]];

  return obj;
}

+ (NSString *)standardFeedKind {
  return kGDataCategoryContactGroup;
}

+ (void)load {
  [self registerFeedClass];
}

- (Class)classForEntries {
  return [GDataEntryContactGroup class];
}

#pragma mark -

- (id)entryForSystemGroupID:(NSString *)str {
  GDataEntryContactGroup *obj;
  
  obj = [GDataUtilities firstObjectFromArray:[self entries]
                                   withValue:str
                                  forKeyPath:@"systemGroup.identifier"];
  return obj;
}

@end
