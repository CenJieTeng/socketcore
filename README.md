# socketcore
lua socket library

# modules
1)socket\
2)timer\
3)database

# Build
```
git clone https://github.com/CenJieTeng/socketcore.git
cd socketcore
make
```

# API
### timer
`int timer(int msTime,std::function<void()> callbackFunc, bool bLoop)`: create timer\
`void timerCancel(int timerId)`: cancel timer by id
  
### database
`void db_connect(host, user, password, table, port)`: connect to database\
`void db_query(const char *que)`: sql query\
`table db_fetch_row(const char* que)`: fetch one row from `res_`
