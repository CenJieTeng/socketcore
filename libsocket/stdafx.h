//#pragma once

#ifdef _WIN32
#include "targetver.h"
#define WIN32_LEAN_AND_MEAN             // 从 Windows 头文件中排除极少使用的内容
// Windows 头文件
#include <windows.h>
//#pragma warning(disable : 4996)
#endif

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