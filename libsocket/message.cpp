#include "stdafx.h"

//extern sol::state_view sv;
//
////返回消息,统一 json 和 protobuf 的C++访问接口
//template<typename _Type>
//std::string message::operator[](const std::string key) {
//	switch (header_.mt_)
//	{
//	case MessageType::JSON: {
//		static sol::table tb = json2table(&sv, std::string(body(), body_lenght_));
//		return tb.raw_get<_Type>(key);
//	}break;
//	case MessageType::PROTO: {
//
//	}break;
//	case MessageType::RAW: {
//
//	}break;
//	default:
//		assert(false);
//	}
//}