#ifndef DATABASE_H
#define DATABASE_H
#include <iostream>
#include <cassert>
#include <mysql.h>

class DataBase {
public:
	DataBase() 
		: res_(nullptr){
		//初始化
		mysql_init(&connection_);
	}
	DataBase(const char *host, const char *user, const char *password, const char *dbname, int port)
		: res_(nullptr){
		//初始化
		mysql_init(&connection_);
		connect(host, user, password, dbname, port);
	}

	~DataBase() { 
		mysql_close(&connection_);
	}

	//连接到数据库
	void connect(const char *host, const char *user, const char *password, const char *table, int port) {
		//连接到数据库
		if (!mysql_real_connect(&connection_, host, user, password, table,
			port, 0, CLIENT_FOUND_ROWS)) {
			throw(std::exception(mysql_error(&connection_)));
		}
	}

	//一般查询
	void query(const char *que) {
		if (mysql_query(&connection_, que)) {
			throw(std::exception(mysql_error(&connection_)));
		}
	}

	//获取一行数据
	MYSQL_ROW fetch_row(const char* que) {
		if (res_ == nullptr) {
			query(que);
			if (res_ != nullptr) {
				mysql_free_result(res_);
			}
			if ((res_ = mysql_use_result(&connection_)) == nullptr) {
				throw(std::exception(mysql_error(&connection_)));
			}
			return fetch_row(nullptr);
		}
		else {
			row_ = mysql_fetch_row(res_);
			if (row_) {
				return row_;
			}
			else {
				mysql_free_result(res_);
				res_ = nullptr;
				return nullptr;
			}
		}
	}

	//获取当前res_的段信息
	MYSQL_FIELD* fetch_fields() {
		return mysql_fetch_fields(res_);
	}

	//获取当前res_段数量
	int num_fields() const {
		return mysql_num_fields(res_);
	}

private:
	MYSQL connection_;
	MYSQL_RES *res_; //结果集
	MYSQL_ROW row_; //行
};

#endif // !DATABASE_H
