# socketcore
lua socket library

## modules
1)socket\
2)timer\
3)database

## Build
```
git clone https://github.com/CenJieTeng/socketcore.git
cd socketcore
make
```

## API
### socket
```c++
void run(): io_context->run()
void listen(const std::string &host, uint16_t port) : listen special port
void accept(): accept new connection
void connect(const std::string &host, uint16_t port): connect to special host and port
void setCallBack(const std::string &name, std::function<void(session_ptr)> cb): set accept,connect callbackFunc
string getReadmsg(session_ptr sp): get recv message
doWrite(session_ptr sp, const std::string &msg, const MessageType mt, const ProtoMessageType pmt = ProtoMessageType::DEFAULT_MSG) send message to `session` 
```

### timer
```
int timer(int msTime,std::function<void()> callbackFunc, bool bLoop): create timer
void timerCancel(int timerId): cancel timer by id
```
  
### database
```
void db_connect(host, user, password, table, port): connect to database
void db_query(const char *que): sql query
table db_fetch_row(const char* que): fetch one row from `res_`
```
