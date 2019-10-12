// libsocket.cpp : 定义 DLL 应用程序的导出函数。
//

#include "stdafx.h"
#include "socket.h"
#include "session.h"
#include "mytimer.hpp"
#include "database.hpp"

extern "C" {

	//lua入口函数
	#ifdef _WIN32
	__declspec(dllexport)
	#endif
	int luaopen_socketcore(lua_State *L) {
		sol::state_view *sv = new sol::state_view(L);
		sol::table module = sv->create_table(); //创建表

		auto ioc = std::shared_ptr<boost::asio::io_context>(new boost::asio::io_context);
		auto socket = std::shared_ptr<Socket>(new Socket(*ioc));

		//--注册函数到表
		module.set_function("run", [ioc]() {
			ioc->run();
		});

		module.set_function("listen", [socket](const std::string &host, uint16_t port) {
			socket->listen(host, port);
		});

		module.set_function("accept", [socket]() {
			socket->accept();
		});

		module.set_function("connect", [socket](const std::string &host, uint16_t port) {
			socket->connect(host, port);
		});

		module.set_function("read", [socket](uint32_t fd) {
			return socket->read(fd);
		});

		module.set_function("write", [socket](uint32_t fd, std::string msg) ->bool {
			return socket->write(fd, msg);
		});

		module.set_function("setCallBack", [](const std::string &name, std::function<void(session_ptr)> cb) {
			Session::setCallBack(name, cb);
		});

		module.set_function("getReadmsg", [](session_ptr sp) ->std::string {
			return sp->getReadmsg();
		});

		module.set_function("doWrite", [](session_ptr sp, const std::string &msg, const MessageType mt,
			const ProtoMessageType pmt = ProtoMessageType::DEFAULT_MSG) {
			sp->doWrite(std::move(msg), mt, pmt);
		});

		module.set_function("getKey", [](const session_ptr sp) ->int {
			return sp->getKey();
		});

		module.set_function("setKey", [](session_ptr sp, int key) {
			sp->setKey(key);
		});

		module.set_function("getRoomId", [](const session_ptr sp) ->int {
			return sp->getRoomId();
		});

		module.set_function("setRoomId", [](session_ptr sp, int roomId) {
			sp->setRoomId(roomId);
		});

		module.set_function("getMessageType", [](session_ptr sp) ->MessageType {
			return sp->getMessageType();
		});

		module.set_function("getProtoMessageType", [](session_ptr sp) ->ProtoMessageType {
			return sp->getProtoMessageType();
		});


		//------------timer-----------
		/*auto timer_ioc = std::shared_ptr<boost::asio::io_context>(new boost::asio::io_context);

		module.set_function("timerRun", [timer_ioc]() {
			std::thread *timerRunTherad = new std::thread(([timer_ioc]() { timer_ioc->run(); }));
		});*/

		module.set_function("timer", [ioc](int msTime, std::function<void()> func, bool loop) ->int {
			std::shared_ptr<mytimer> timer(new mytimer(*ioc, msTime, func, loop));
			timer->retain();

			return timer->getId();
		});

		module.set_function("timerCancel", [](int id) {
			mytimer::cancelById(id);
		});
		//------------timer-----------

		//-----------database---------

		std::shared_ptr<DataBase> db(new DataBase());
		module.set_function("db_connect", [db](const char *host, const char *user, const char *password, const char *table, int port) {
			db->connect(host, user, password, table, port);
		});

		module.set_function("db_query", [db](const char *que) {
			db->query(que);
		});

		module.set_function("db_fetch_row", [sv, db](const char *que) ->sol::table {
			MYSQL_ROW row = db->fetch_row(que);
			auto tb = sv->create_table();
			if (row == nullptr) return tb;

			MYSQL_FIELD *fields = db->fetch_fields();
			int n = db->num_fields();
			for (int i = 0; i < n; ++i) {
				if (row[i])
					tb[fields[i].name] = row[i];
				else
					tb[fields[i].name] = sol::nil;
			}
			return tb;
		});

		//-----------database---------

		lua_getglobal(L, "package");
		lua_getfield(L, -1, "loaded"); /* get 'package.loaded' */
		module.push();
		lua_setfield(L, -2, "socketcore"); /* package.loaded[name] = f */
		lua_pop(L, 2); /* pop 'package' and 'loaded' tables */

		return 0;
	}
}
