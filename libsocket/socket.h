#ifndef SOCKET_H
#define SOCKET_H
#include "stdafx.h"
#include "session.h"
using boost::asio::ip::tcp;
class Session;
using session_ptr = std::shared_ptr<Session>;

class Socket {
public:
	Socket(boost::asio::io_context &ioc)
		: ioc_(ioc), socket_(ioc), acceptor_(ioc, tcp::v4()){}

	Socket(const Socket&) = delete;
	Socket& operator=(const Socket&) = delete;

	void listen(const std::string &host, uint16_t port); //监听端口
	void accept(); //接收连接
	void connect(const std::string &host, uint16_t port); //连接到特定主机和端口
	std::tuple<std::string, int> read(uint32_t fd); //从特定的socket读取数据
	bool write(uint32_t fd, std::string str); //往特定的socket写数据

private:
	uint32_t uuid(); //创建唯一id,用于映射连接
	bool try_lock_fd(uint32_t fd);

private:
	std::atomic<uint32_t> uuid_ = 0; //id
	std::mutex mutex_;
	std::unordered_set<uint32_t> fds_; //id集合
	boost::asio::io_context &ioc_;
	tcp::socket socket_;
	tcp::acceptor acceptor_;
	std::unordered_map<uint32_t, tcp::socket> connections_; //连接映射
};

#endif