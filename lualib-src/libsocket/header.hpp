#pragma once
#ifndef HEADER_H
#define HEADER_H

enum class MessageType {
	JSON_MSG = 1,
	PROTO_MSG = 2
};

//消息头部
struct Header {
	char len_[2]; //消息长度
	MessageType mt_; //消息类型
};

#endif // !HEADER_H
