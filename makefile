#dir
LUA_DIR = /usr/local/include/lua-5.3.5/
MYSQL_DIR = /usr/include/mysql/
THIRD_DIR = ./third/
SRC_DIR = ./libsocket/

#var
STD = std=c++17
XX = g++
SOURCES = $(filter-out  libsocket/dllmain.cpp, $(wildcard libsocket/*.cpp))
OBJS = $(SOURCES:.cpp=.o)
#OBJS = $(patsubst %.o, %.cpp, $(SOURCES))

%.o: %.cpp
	$(XX) -c -$(STD) -I$(LUA_DIR) -I$(MYSQL_DIR) -I$(THIRD_DIR) $< -fPIC -o $@

socketcore.so: $(OBJS)
	$(XX) -g -$(STD) -L=/usr/local/lib64 -L=usr/lib64/mysql $(OBJS) \
	/usr/local/lib64/liblua53.a /usr/local/lib/libboost_system.a  -lmysqlclient -shared -o socketcore.so

clean:
	rm -rf $(SRC_DIR)/*.o socketcore.so