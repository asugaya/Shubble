//
//  GoogleDocs.h
//  GoogleDocs
//
//  Created by Tom Saxton on 12/19/08.
//  Copyright (c) 2008-2009 Idle Loop Software Design, LLC.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#ifdef DEBUG

int AssertProc(const char pszCondition[], const char pszFunction[], const char pszFile[], long line);

#define Debug(e) e
#define Assert(f) ((f)?1:AssertProc(#f, __FUNCTION__, __FILE__, __LINE__))
#define DebugLog NSLog

#else

#define Debug(f)
#define Assert(f)
#define DebugLog(...)

#endif