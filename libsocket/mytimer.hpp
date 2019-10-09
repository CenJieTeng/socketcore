#ifndef MYTIMER_H
#define MYTIMER_H
#include <chrono>
#include <thread>
#include <functional>
#include <unordered_set>
#include <unordered_map>
#include <boost/timer/timer.hpp>
#include <boost/asio.hpp>

using boost::timer::cpu_timer;
using boost::timer::cpu_times;
using boost::timer::nanosecond_type;

class mytimer : public std::enable_shared_from_this<mytimer> {
public:
	mytimer(boost::asio::io_context &ioc, int msTime, std::function<void()> func, bool loop = true)
		: ioc_(ioc), 
		msTime_(msTime), 
		func_(func),
		timer_(ioc, boost::posix_time::milliseconds(msTime)),
		bLoop_(loop){

		id_ = uuid();
		timerSet_.emplace(id_);
		start();
	}
	~mytimer() {
	}

	//运行定时器
	void start() {
		timer_.async_wait([this](const boost::system::error_code &ec) {
			if (!ec) {
				func_();
				if (bLoop_) {
					timer_.expires_at(timer_.expires_at() + boost::posix_time::milliseconds(msTime_));
					start();
				}
			}
			//else {
			//	std::cerr << ec.value() << ec.message() << std::endl;
			//}
		});
	}

	//保持定时器离开作用域后不被析构
	void retain() { 
		mapIdToTimer_.emplace(id_, shared_from_this());
	}

	//取消定时器
	void cancel() { 
		bLoop_ = false;
		timer_.cancel();

		//timerSet_.erase(id_);
		//mapIdToTimer_.erase(id_);
	}

	int getId()const { return id_; }

	//取消特定id的定时器
	static void cancelById(int id);

private:
	int uuid() {
		int ret = 0;
		do {
			ret = uuid_.fetch_add(1);
			ret %= UINT32_MAX;
		} while (!try_lock_id(ret));

		return ret;
	}


	bool try_lock_id(int id) {
		std::lock_guard<std::mutex> lock(id_mutex_);
		return timerSet_.emplace(id).second;
	}
	
private:
	static std::unordered_set<int> timerSet_; //正在运行的定时器
	static std::unordered_map<int, std::shared_ptr<mytimer>> mapIdToTimer_; //id到timer的映射

	boost::asio::io_context &ioc_;
	int id_; //定时器id
	int msTime_; //时间(毫秒ms)
	std::function<void()> func_; //回调函数
	boost::asio::deadline_timer timer_; //定时器
	bool bLoop_; //定时器是否有效
	std::atomic<int> uuid_;
	std::mutex id_mutex_;
};

std::unordered_set<int> mytimer::timerSet_;
std::unordered_map<int, std::shared_ptr<mytimer>> mytimer::mapIdToTimer_;

//取消特定id的定时器
void mytimer::cancelById(int id) {
	if (mapIdToTimer_.find(id) != mapIdToTimer_.end()) {
		mapIdToTimer_[id]->cancel();
	}
}

//namespace mytimer {
//
//	////定时调用回调函数
//	//static void timerCallBack(int id, int millisecond, std::function<void()> func) {
//	//	const nanosecond_type interval(millisecond * 1000000LL);
//	//	if (interval <= nanosecond_type(0) || timerSet_.find(id) != timerSet_.end())
//	//		return;
//
//	//	timerSet_.emplace(id);
//
//	//	mapIdToThread.emplace(id, std::shared_ptr<std::thread>(new std::thread([id, interval, func]() {
//	//		cpu_timer timer; //创建定时器
//	//		nanosecond_type last(0);
//	//		while (timerSet_.find(id) != timerSet_.end()) {
//	//			cpu_times elapsed_timers(timer.elapsed());
//	//			nanosecond_type elapsed(elapsed_timers.wall);
//	//			auto t = elapsed - last;
//	//			if (t >= interval) {
//	//				func();
//	//				last = elapsed;
//	//			}
//	//		}
//	//	})));
//	//}
//
//	////销毁定时器
//	//static void timerDestroy(int id) {
//	//	if (timerSet_.find(id) == timerSet_.end())
//	//		return;
//
//	//	timerSet_.erase(id);
//	//	mapIdToThread[id]->join();
//	//}
//}

#endif // !MYTIMER_H