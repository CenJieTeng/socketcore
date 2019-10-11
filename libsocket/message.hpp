#pragma once
#ifndef MESSAGE_HPP
#define MESSAGE_HPP
#include "stdafx.h"

enum class MessageType : uint8_t {
	JSON = 1,
	PROTO = 2,
	RAW = 3
};

enum class ProtoMessageType : uint8_t {
	SESSION_MSG = 1,
	GAME_MSG = 2,
	ROOM_MSG = 3,
	DEFAULT_MSG = 255
};

//消息头部
const int maxByte = 2;
struct Header {
	char len_[maxByte]; //消息长度
	MessageType mt_; //消息类型
	ProtoMessageType pmt_; //proto消息类型
};

enum {
	head_lenght = sizeof(Header),
	max_body_lenght = 1024
};

class message {
public:
	message()
		: body_lenght_(0),
		header_(){
	}

	size_t head_len() { return head_lenght; }
	char* body() { return data_ + head_lenght; }
	const char* body() const { return data_ + head_lenght; }
	size_t body_len() { return body_lenght_; }
	char* data()  { return data_; }
	const char* data() const { return data_; }
	size_t size() { return head_lenght + body_lenght_; }
	const MessageType getMessageType() const { return header_.mt_; }
	const ProtoMessageType getProtoMessageType() const { return header_.pmt_; }

	//编码
	void encode(const std::string &msg, MessageType mt, ProtoMessageType pmt=ProtoMessageType::DEFAULT_MSG) {
		size_t len = msg.size();
		if (len > max_body_lenght || len > pow(maxByte, 16))
			throw(std::length_error("class message.encode:'msg' too lenght"));

		Header header; //消息头
		header.mt_ = mt;
		if (mt == MessageType::PROTO) {
			assert(pmt != ProtoMessageType::DEFAULT_MSG);
			header.pmt_ = pmt;
		}
		memcpy(header.len_, (void*)&len, maxByte); //编码长度
		memcpy(data_, &header, head_lenght); //编码头部

		memcpy(body(), msg.c_str(), len); //拷贝内容
	}

	//解码
	void decode() {
		//memset(&body_lenght_, 0, sizeof(body_lenght_));
		memcpy(&header_, (void*)data_, head_lenght); //解码头部
		memcpy(&body_lenght_, (void*)header_.len_, maxByte); //解码长度
		data_[head_lenght + body_lenght_] = 0;
	}

	//序列化
	template <typename _Type>
	static std::string serialize(_Type &msg) {
		std::string ret;
		assert(msg.SerializeToString(&ret));

		return ret;
	}

private:
	size_t body_lenght_; //数据大小
	Header header_; //数据头
	char data_[head_lenght + max_body_lenght + 1]; //数据
};

#endif // !MESSAGE_HPP