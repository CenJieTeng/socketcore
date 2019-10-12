#include "session.h"
#include "message.hpp"

std::map<std::string, std::function<void(session_ptr)>> Session::cbs_;

//设置回调函数
void Session::setCallBack(const std::string &name, std::function<void(session_ptr)>cb){
	//cbs_.emplace(name, cb);
	cbs_[name] = cb;
}

//调用回调函数
void Session::callBack(const std::string & name, const session_ptr sp){
	assert(cbs_.find(name) != cbs_.end());
	cbs_[name](sp);
}

//读取数据头部
void Session::readHeader() {
	boost::asio::async_read(
		socket_,
		boost::asio::buffer(read_msg_.data(), read_msg_.head_len()),
		[self = shared_from_this(), this](const boost::system::error_code &ec, size_t /* lenght */) {
		if (!ec) {
			read_msg_.decode();
			readBody();
		}
		else
			std::cout << ec.message() << std::endl;
	});	
}

//读取数据内容
void Session::readBody() {
	boost::asio::async_read(
		socket_,
		boost::asio::buffer(read_msg_.body(), read_msg_.body_len()),
		[self = shared_from_this(), this](const boost::system::error_code &ec, size_t /* lenght */) {
		if (!ec){
			callBack("read", shared_from_this());

			readHeader();
		}
		else 
			std::cout << ec.message() << std::endl;
	});
}

//写数据到对端
void Session::doWrite(std::string str, const MessageType mt, const ProtoMessageType pmt) {
	message msg;
	msg.encode(str, mt, pmt);

	boost::asio::async_write(
		socket_,
		boost::asio::buffer(msg.data(), msg.head_len() + str.size()),
		[](const boost::system::error_code &ec, size_t /* lenght */) {
			if (!ec) {
			}
			else
				std::cout << ec.message() << std::endl;
		});
}