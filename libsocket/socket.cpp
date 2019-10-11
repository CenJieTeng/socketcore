#include "stdafx.h"

using namespace boost::property_tree;
//消息最大长度
const int MaxSize = 1024;

//监听端口
void Socket::listen(const std::string &host, uint16_t port) {
	tcp::resolver resolver_(ioc_);
	tcp::endpoint endpoint_ = *resolver_.resolve(host, std::to_string(port)).begin();

	acceptor_.bind(endpoint_);
	acceptor_.listen();
}

//异步
//接收连接
void Socket::accept() {
	session_ptr new_session = session_ptr(new Session(ioc_));

	acceptor_.async_accept(new_session->socket(), [this, new_session](const boost::system::error_code &ec) {
		if (!ec) {
			new_session->start();
			Session::callBack("accept", new_session);

			accept();
		}
		else
			std::cout << ec.message() << std::endl;
	});
}

//异步
//连接到特定主机和端口
void Socket::connect(const std::string &host, uint16_t port) {
	tcp::resolver resolver_(ioc_);
	session_ptr new_session = session_ptr(new Session(ioc_));

	boost::asio::async_connect(new_session->socket(), resolver_.resolve(host, std::to_string(port)),
		[this, new_session](const boost::system::error_code &ec, auto ep) {
		if (!ec) {
			new_session->start();

			Session::callBack("connect", new_session);
		}
		else
			std::cout << ec.message() << std::endl;
	});
}

//从特定的socket读取数据
std::tuple<std::string, int> Socket::read(uint32_t fd) {
	auto iter = connections_.find(fd);
	if (iter == connections_.end())
		return std::make_tuple("", false);

	char buf[MaxSize + 1];
	try {
		size_t n = (*iter).second.read_some(boost::asio::buffer(buf, MaxSize));
		buf[n] = 0;
	}
	catch (boost::system::system_error &) {
		fds_.erase(fd);
		return std::make_tuple("", false);
	}

	std::stringstream ss(
		std::string(
			buf, strlen(buf)));
	ptree pt;
	read_json(ss, pt);

	return std::make_tuple(pt.get<std::string>("info"), true);
}

//往特定的socket写数据
bool Socket::write(uint32_t fd, std::string str) {
	auto iter = connections_.find(fd);
	if (iter == connections_.end())
		return false;

	std::stringstream ss;
	ptree pt;
	pt.put("info", str);
	write_json(ss, pt);

	message msg;
	str = ss.str();
	msg.encode(str, MessageType::JSON);
	boost::asio::write((*iter).second, boost::asio::buffer(msg.data(), head_lenght+str.size()));

	return true;
}

//创建唯一id,用于映射连接
uint32_t Socket::uuid() {
	uint32_t ret = 0;
	do {
		ret = uuid_.fetch_add(1);
		ret %= UINT32_MAX;
	} while (!try_lock_fd(ret));

	return ret;
}

bool Socket::try_lock_fd(uint32_t fd) {
	//std::unique_lock lock(mutex_);
	std::lock_guard<std::mutex> lock(mutex_);
	return fds_.emplace(fd).second;
}