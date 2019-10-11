// stdafx.h: 标准系统包含文件的包含文件，
// 或是经常使用但不常更改的
// 项目特定的包含文件
//

#pragma once

#include "targetver.h"

#define WIN32_LEAN_AND_MEAN             // 从 Windows 头文件中排除极少使用的内容
// Windows 头文件
#include <windows.h>

#pragma warning(disable : 4996)

// 在此处引用程序需要的其他标头
extern "C" {
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
}
#include <cassert>
#include <iostream>
#include <sstream>
#include <thread>
#include <atomic>
#include <mutex>
#include <memory>
#include <string>
#include <deque>
#include <unordered_map>
#include <unordered_set>
#include <sol/sol.hpp>
#include <boost/asio.hpp>
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/json_parser.hpp>
#include "../cjson/tools.h"
#include "message.hpp"
#include "socket.h"
#include "session.h"