#ifndef SESSION_H
#define SESSION_H
#include "stdafx.h"
#include "message.hpp"
using boost::asio::ip::tcp;
using namespace boost::property_tree;

class Session;
using session_ptr = std::shared_ptr<Session>;

class Session : public std::enable_shared_from_this<Session> {
public:
	using  msg_deque = std::deque<message>;
public:
	Session(boost::asio::io_context &ioc)
		: socket_(ioc), 
		read_msg_(),
		key_(),
		roomId_(0){
	}
	~Session() { socket_.close(); }

	void start() { readHeader();}
	void readHeader(); //读取数据头部
	void readBody(); //读取数据头部
	void doWrite(std::string str, const MessageType mt, const ProtoMessageType pmt = ProtoMessageType::DEFAULT_MSG); //读取数据内容

	tcp::socket& socket() { return socket_; }
	void setKey(int key) { key_ = key; }
	const int getKey() const { return key_; }
	void setRoomId(int roomId) { roomId_ = roomId; }
	const int getRoomId() const { return roomId_; }
	const MessageType getMessageType() const { return read_msg_.getMessageType(); }
	const ProtoMessageType getProtoMessageType() const { return read_msg_.getProtoMessageType(); }

	//返回读取到的数据
	std::string getReadmsg() {
		std::stringstream ss(
			std::string(
				read_msg_.body(), read_msg_.body_len()));

		return ss.str();
	}

	
	static void setCallBack(const std::string &name, std::function<void(session_ptr)> cb); //设置回调函数
	static void callBack(const std::string &name, const session_ptr sp); //调用回调函数
private:
	static std::map<std::string, std::function<void(session_ptr)>> cbs_; //注册的回调函数
	message read_msg_; //读取的消息
	tcp::socket socket_;
	int key_; //连接对应的key
	int roomId_; //房间id
};

#endif